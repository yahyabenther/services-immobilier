import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/repositories/location_service.dart';

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<DeviceLocationResult> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const DeviceLocationServiceDisabled();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return const DeviceLocationDeniedForever();
      if (permission == LocationPermission.denied) return const DeviceLocationDenied();

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return DeviceLocationGranted(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Location error: $e');
      return const DeviceLocationError();
    }
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
