import '../entities/property.dart';

/// Shared read access to single properties. Used by Module 05 (details) and by
/// anything that opens `/property/:id`. Throws [PropertyFailure] only.
abstract interface class PropertyRepository {
  /// Loads a PUBLISHED property by id. Missing, unpublished, malformed or
  /// inaccessible documents all become `notFound` / `unavailable`.
  Future<Property> getPropertyById(String id);

  /// Other published listings similar to [property] (never includes it).
  Future<List<Property>> getSimilarProperties(Property property, {int limit = 6});
}
