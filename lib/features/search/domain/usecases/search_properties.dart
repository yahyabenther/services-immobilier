import '../entities/filter_validation.dart' show FilterErrors, FilterValidator;
import '../entities/property_search_filter.dart';
import '../entities/search_result_page.dart';
import '../repositories/search_repository.dart';

class InvalidSearchFilter implements Exception {
  const InvalidSearchFilter(this.errors);
  final FilterErrors errors;
}

class SearchProperties {
  const SearchProperties(this._repo);
  final SearchRepository _repo;

  Future<SearchResultPage> call(PropertySearchFilter filter, {Object? cursor, int pageSize = 20}) {
    final errors = FilterValidator.validate(filter);
    if (errors.hasErrors) throw InvalidSearchFilter(errors);
    return _repo.search(filter, cursor: cursor, pageSize: pageSize);
  }
}
