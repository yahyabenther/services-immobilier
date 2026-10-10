import '../../../search/domain/entities/property_summary.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/firestore_property_datasource.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  PropertyRepositoryImpl(this._datasource);
  final FirestorePropertyDatasource _datasource;

  @override
  Future<Property?> getById(String id) => _datasource.getById(id);

  @override
  Future<List<PropertySummary>> getSimilar(Property property, {int limit = 6}) =>
      _datasource.getSimilar(property, limit: limit);
}