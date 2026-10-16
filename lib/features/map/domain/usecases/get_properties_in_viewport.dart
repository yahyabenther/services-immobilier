import '../../../search/domain/entities/property_search_filter.dart';
import '../entities/map_query_result.dart';
import '../entities/map_viewport.dart';
import '../repositories/map_repository.dart';

class GetPropertiesInViewport {
  const GetPropertiesInViewport(this._repository);
  final MapRepository _repository;

  Future<MapQueryResult> call({
    required MapViewport viewport,
    PropertySearchFilter? filter,
    int limit = 150,
  }) =>
      _repository.getPropertiesInViewport(viewport: viewport, filter: filter, limit: limit);
}
