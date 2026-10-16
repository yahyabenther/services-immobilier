import '../../../properties/domain/entities/property.dart';
import '../repositories/property_discovery_repository.dart';

class GetRecommendedProperties {
  const GetRecommendedProperties(this._repo);
  final PropertyDiscoveryRepository _repo;

  Future<List<Property>> call({int limit = 10}) => _repo.getRecommendedProperties(limit: limit);
}
