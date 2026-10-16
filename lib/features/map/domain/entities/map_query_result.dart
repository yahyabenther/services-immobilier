import '../../../properties/domain/entities/property.dart';

class MapQueryResult {
  const MapQueryResult({required this.items, this.truncated = false});

  /// Public listings with valid coordinates inside the requested viewport.
  final List<Property> items;

  /// True when more listings exist than were returned (limit or scan cap reached):
  /// the UI tells the user to zoom in.
  final bool truncated;
}
