import '../../../properties/domain/entities/property.dart';
import '../entities/discovery_location.dart';
import '../repositories/property_discovery_repository.dart';

class GetNearbyProperties {
  const GetNearbyProperties(this._repo);
  final PropertyDiscoveryRepository _repo;

  Future<List<Property>> call({required DiscoveryLocation location, int limit = 10}) =>
      _repo.getNearbyProperties(location: location, limit: limit);
}
