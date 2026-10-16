import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../properties/data/property_remote_data_source.dart' show RawPropertyDoc;
import '../../../properties/domain/entities/property.dart';
import '../../domain/services/search_query_plan.dart';

/// One scanned batch, in server order.
class RawSearchBatch {
  const RawSearchBatch({required this.docs, required this.lastCursor, required this.exhausted});

  final List<RawPropertyDoc> docs;

  /// Opaque cursor pointing after the last document of this batch.
  final Object? lastCursor;

  /// True when the backend has nothing after this batch.
  final bool exhausted;
}

/// Contract used by the repository (lets tests run without Firestore).
abstract interface class SearchDataSource {
  Future<RawSearchBatch> fetchBatch(SearchQueryPlan plan, {Object? cursor, required int batchSize});
}

class FirestoreSearchDatasource implements SearchDataSource {
  FirestoreSearchDatasource(this._db);
  final FirebaseFirestore _db;

  @override
  Future<RawSearchBatch> fetchBatch(SearchQueryPlan plan, {Object? cursor, required int batchSize}) async {
    Query<Map<String, dynamic>> q = _db
        .collection('properties')
        .where('status', isEqualTo: PropertyStatus.published.wire);

    if (plan.transactionType != null) {
      q = q.where('transactionType', isEqualTo: plan.transactionType!.name);
    }
    if (plan.governorate != null) {
      q = q.where('governorate', isEqualTo: plan.governorate);
    }
    if (plan.minPrice != null) q = q.where('price', isGreaterThanOrEqualTo: plan.minPrice);
    if (plan.maxPrice != null) q = q.where('price', isLessThanOrEqualTo: plan.maxPrice);
    if (plan.minSurface != null) q = q.where('surface', isGreaterThanOrEqualTo: plan.minSurface);
    if (plan.maxSurface != null) q = q.where('surface', isLessThanOrEqualTo: plan.maxSurface);

    q = q.orderBy(plan.orderField, descending: plan.descending);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) q = q.startAfterDocument(cursor);

    final snap = await q.limit(batchSize).get();
    return RawSearchBatch(
      docs: [for (final d in snap.docs) (id: d.id, data: d.data())],
      lastCursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      exhausted: snap.docs.length < batchSize,
    );
  }
}
