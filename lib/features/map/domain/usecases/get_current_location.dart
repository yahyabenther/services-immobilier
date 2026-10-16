import '../../../property_discovery/domain/repositories/location_service.dart';

enum LocateOutcome { located, denied, deniedForever, serviceDisabled, error }

/// Device position for the map camera only. It is never written anywhere.
class LocateResult {
  const LocateResult.located(double this.latitude, double this.longitude) : outcome = LocateOutcome.located;
  const LocateResult.failed(this.outcome)
      : latitude = null,
        longitude = null;

  final LocateOutcome outcome;
  final double? latitude;
  final double? longitude;

  bool get isLocated => outcome == LocateOutcome.located;
}

/// Wraps the shared [LocationService] (permission is requested here, i.e. only when
/// the user taps "My location").
class GetCurrentLocation {
  const GetCurrentLocation(this._service);
  final LocationService _service;

  Future<LocateResult> call() async {
    final r = await _service.getCurrentPosition();
    return switch (r) {
      DeviceLocationGranted(:final latitude, :final longitude) => _valid(latitude, longitude)
          ? LocateResult.located(latitude, longitude)
          : const LocateResult.failed(LocateOutcome.error),
      DeviceLocationDenied() => const LocateResult.failed(LocateOutcome.denied),
      DeviceLocationDeniedForever() => const LocateResult.failed(LocateOutcome.deniedForever),
      DeviceLocationServiceDisabled() => const LocateResult.failed(LocateOutcome.serviceDisabled),
      DeviceLocationError() => const LocateResult.failed(LocateOutcome.error),
    };
  }

  static bool _valid(double lat, double lng) =>
      lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180;
}
