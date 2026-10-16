sealed class DeviceLocationResult {
  const DeviceLocationResult();
}

class DeviceLocationGranted extends DeviceLocationResult {
  const DeviceLocationGranted(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// User said no this time; asking again later is allowed.
class DeviceLocationDenied extends DeviceLocationResult {
  const DeviceLocationDenied();
}

/// Permission permanently denied: only the system settings can change it.
class DeviceLocationDeniedForever extends DeviceLocationResult {
  const DeviceLocationDeniedForever();
}

class DeviceLocationServiceDisabled extends DeviceLocationResult {
  const DeviceLocationServiceDisabled();
}

class DeviceLocationError extends DeviceLocationResult {
  const DeviceLocationError();
}

abstract interface class LocationService {
  Future<DeviceLocationResult> getCurrentPosition();
  Future<void> openSettings();
}
