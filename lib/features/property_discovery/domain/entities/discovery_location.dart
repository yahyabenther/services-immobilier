/// Where the user wants to look: a manually chosen governorate, or the device position.
class DiscoveryLocation {
  const DiscoveryLocation._({required this.label, this.governorate, this.latitude, this.longitude});

  /// Manual selection. Matched against `properties.governorate`.
  const DiscoveryLocation.governorate(String governorate) : this._(label: governorate, governorate: governorate);

  /// Device position. Properties are matched by distance.
  const DiscoveryLocation.device({required double latitude, required double longitude})
      : this._(label: 'Near you', latitude: latitude, longitude: longitude);

  final String label;
  final String? governorate;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  bool operator ==(Object other) =>
      other is DiscoveryLocation &&
      other.governorate == governorate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(governorate, latitude, longitude);
}
