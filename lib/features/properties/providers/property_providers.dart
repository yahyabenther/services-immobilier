import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/property_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/property_remote_data_source.dart';
import '../data/property_repository_impl.dart';
import '../domain/entities/property.dart';
import '../domain/repositories/property_repository.dart';

/// Override in tests with a fake.
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => PropertyRepositoryImpl(PropertyRemoteDataSource(ref.watch(firestoreProvider))),
);

/// Data-or-failure (never thrown), so a missing property is a normal UI state
/// and Riverpod never retries a "not found" in the background.
class PropertyLoadResult {
  const PropertyLoadResult.ok(Property this.property) : failure = null;
  const PropertyLoadResult.failed(PropertyFailure this.failure) : property = null;

  final Property? property;
  final PropertyFailure? failure;

  bool get isOk => property != null;
}

/// Module 05 entry point: `ref.watch(propertyDetailsProvider(id))`.
final propertyDetailsProvider =
    FutureProvider.autoDispose.family<PropertyLoadResult, String>((ref, id) async {
  try {
    return PropertyLoadResult.ok(await ref.read(propertyRepositoryProvider).getPropertyById(id));
  } on PropertyFailure catch (e) {
    return PropertyLoadResult.failed(e);
  } catch (_) {
    return const PropertyLoadResult.failed(PropertyFailure(PropertyFailureType.unknown));
  }
});

/// Similar listings for the property with this id (reuses the cached details load).
/// Failures degrade to an empty list: the details page must never break because of it.
final similarPropertiesProvider =
    FutureProvider.autoDispose.family<List<Property>, String>((ref, id) async {
  try {
    final loaded = await ref.watch(propertyDetailsProvider(id).future);
    final property = loaded.property;
    if (property == null) return const [];
    return await ref.read(propertyRepositoryProvider).getSimilarProperties(property);
  } catch (_) {
    return const [];
  }
});
