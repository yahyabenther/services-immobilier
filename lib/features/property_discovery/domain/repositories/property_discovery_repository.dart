import '../../../properties/domain/entities/property.dart';
import '../entities/discovery_location.dart';

/// Throws [DiscoveryFailure] only.
abstract interface class PropertyDiscoveryRepository {
  Future<List<Property>> getRecommendedProperties({int limit = 10});

  Future<List<Property>> getNearbyProperties({
    required DiscoveryLocation location,
    int limit = 10,
  });
}
