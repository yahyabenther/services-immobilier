import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../search/domain/entities/property_summary.dart';
import '../data/datasources/firestore_property_datasource.dart';
import '../data/repositories/property_repository_impl.dart';
import '../domain/entities/property.dart';
import '../domain/repositories/property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepositoryImpl(
    FirestorePropertyDatasource(FirebaseFirestore.instance),
  );
});

/// Un bien par id (null = introuvable).
final propertyDetailsProvider =
    FutureProvider.autoDispose.family<Property?, String>((ref, id) {
  return ref.watch(propertyRepositoryProvider).getById(id);
});

/// Biens similaires, clé = id du bien affiché.
final similarPropertiesProvider = FutureProvider.autoDispose
    .family<List<PropertySummary>, String>((ref, id) async {
  final property = await ref.watch(propertyDetailsProvider(id).future);
  if (property == null) return const [];
  return ref.watch(propertyRepositoryProvider).getSimilar(property);
});