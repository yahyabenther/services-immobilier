import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/tunisia_governorates.dart';
import '../../../../core/errors/discovery_failure.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../properties/domain/entities/property.dart';
import '../../data/datasources/property_discovery_remote_data_source.dart';
import '../../data/repositories/property_discovery_repository_impl.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/entities/discovery_location.dart';
import '../../domain/repositories/location_service.dart';
import '../../domain/repositories/property_discovery_repository.dart';
import '../../domain/usecases/get_nearby_properties.dart';
import '../../domain/usecases/get_recommended_properties.dart';

// ---- infrastructure (override in tests) -----------------------------------
final discoveryRepositoryProvider = Provider<PropertyDiscoveryRepository>(
  (ref) => PropertyDiscoveryRepositoryImpl(PropertyDiscoveryRemoteDataSource(ref.watch(firestoreProvider))),
);

final locationServiceProvider = Provider<LocationService>((_) => const GeolocatorLocationService());

final getRecommendedPropertiesProvider =
    Provider((ref) => GetRecommendedProperties(ref.watch(discoveryRepositoryProvider)));
final getNearbyPropertiesProvider =
    Provider((ref) => GetNearbyProperties(ref.watch(discoveryRepositoryProvider)));

// ---- section data ---------------------------------------------------------
/// Result of one Home section. Failures are DATA (not thrown), so a failed
/// section never breaks the others and no automatic provider retry kicks in.
class SectionData {
  const SectionData.ok(this.items) : error = null;
  const SectionData.failed(this.error) : items = const [];

  final List<Property> items;
  final String? error;

  bool get hasError => error != null;
  bool get isEmpty => !hasError && items.isEmpty;
}

Future<SectionData> _load(Future<List<Property>> Function() run) async {
  try {
    return SectionData.ok(await run());
  } on DiscoveryFailure catch (e) {
    return SectionData.failed(e.message);
  } catch (_) {
    return SectionData.failed(const DiscoveryFailure(DiscoveryFailureType.unknown).message);
  }
}

const homeSectionLimit = 10;

final recommendedPropertiesProvider = FutureProvider.autoDispose<SectionData>(
  (ref) => _load(() => ref.read(getRecommendedPropertiesProvider)(limit: homeSectionLimit)),
);

final nearbyPropertiesProvider = FutureProvider.autoDispose<SectionData>((ref) async {
  final location = ref.watch(selectedLocationProvider);
  if (location == null) return const SectionData.ok([]);
  return await _load(() => ref.read(getNearbyPropertiesProvider)(location: location, limit: homeSectionLimit));
});

// ---- location -------------------------------------------------------------
/// Outcome of "use my current location", so the UI can explain what happened.
enum DeviceLocationOutcome { success, denied, deniedForever, serviceDisabled, error }

/// The governorate saved in the user's profile (`preferredCity`), or null.
/// Used only as the STARTING location on Home: it is never treated as GPS, and a
/// profile that cannot be read just means no starting location.
final preferredGovernorateProvider = StreamProvider.autoDispose<String?>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.id));
  if (uid == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) {
    final raw = (s.data()?['preferredCity'] as String?)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    for (final g in tunisiaGovernorates) {
      if (g.toLowerCase() == raw) return g;
    }
    return null; // not a known governorate: never guess
  }).handleError((_) {});
});

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, DiscoveryLocation?>(SelectedLocationNotifier.new);

class SelectedLocationNotifier extends Notifier<DiscoveryLocation?> {
  @override
  DiscoveryLocation? build() {
    // Reset when the signed-in user changes (logout / account switch).
    ref.watch(currentUserProvider.select((u) => u?.id));
    // Start from the profile's preferred governorate when there is one; otherwise
    // nothing is assumed. (Re-runs when the profile value arrives or changes.)
    final preferred = ref.watch(preferredGovernorateProvider).value;
    return preferred == null ? null : DiscoveryLocation.governorate(preferred);
  }

  void selectGovernorate(String governorate) => state = DiscoveryLocation.governorate(governorate);

  void clear() => state = null;

  Future<DeviceLocationOutcome> useDeviceLocation() async {
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    switch (result) {
      case DeviceLocationGranted(:final latitude, :final longitude):
        state = DiscoveryLocation.device(latitude: latitude, longitude: longitude);
        return DeviceLocationOutcome.success;
      case DeviceLocationDenied():
        return DeviceLocationOutcome.denied;
      case DeviceLocationDeniedForever():
        return DeviceLocationOutcome.deniedForever;
      case DeviceLocationServiceDisabled():
        return DeviceLocationOutcome.serviceDisabled;
      case DeviceLocationError():
        return DeviceLocationOutcome.error;
    }
  }

  Future<void> openSettings() => ref.read(locationServiceProvider).openSettings();
}

/// Pull-to-refresh: reload every section, keep what is on screen meanwhile.
Future<void> refreshDiscovery(WidgetRef ref) async {
  ref.invalidate(recommendedPropertiesProvider);
  ref.invalidate(nearbyPropertiesProvider);
  await Future.wait([
    ref.read(recommendedPropertiesProvider.future),
    ref.read(nearbyPropertiesProvider.future),
  ]);
}
