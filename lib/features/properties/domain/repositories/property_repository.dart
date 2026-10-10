import '../../../search/domain/entities/property_summary.dart';
import '../entities/property.dart';

abstract class PropertyRepository {
  Future<Property?> getById(String id);

  /// Biens du même type et de la même ville (sans le bien lui-même).
  Future<List<PropertySummary>> getSimilar(Property property, {int limit = 6});
}