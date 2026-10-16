import 'package:cloud_firestore/cloud_firestore.dart';

import '../../properties/data/property_remote_data_source.dart' show RawPropertyDoc;
import '../../properties/domain/entities/property.dart';

class RawMapBatch {
  const RawMapBatch({required this.docs, required this.lastCursor, required this.exhausted});

  final List<RawPropertyDoc> docs;

  /// Opaque cursor pointing after the last document of this batch.
  final Object? lastCursor;
  final bool exhausted;
}

/// Contract used by the repository (lets tests run without Firestore).
abstract interface class MapDataSource {
  Future<RawMapBatch> fetchLatitudeBand({
    required double south,
    required double north,
    Object? cursor,
    required int batchSize,
  });
}

/// The only Map class that talks to Firestore. Firestore cannot run a lat/lng
/// bounding-box query, so the server narrows to a LATITUDE BAND and the repository
/// applies longitude + filters. Index: status ASC, latitude ASC (already in
/// firestore.indexes.json). Rules: the query is constrained to `status == published`,
/// which is exactly what the `properties` read rule requires.
class FirestoreMapDataSource implements MapDataSource {
  FirestoreMapDataSource(this._db);
  final FirebaseFirestore _db;

  @override
  Future<RawMapBatch> fetchLatitudeBand({
    required double south,
    required double north,
    Object? cursor,
    required int batchSize,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('properties')
        .where('status', isEqualTo: PropertyStatus.published.wire)
        .where('latitude', isGreaterThanOrEqualTo: south)
        .where('latitude', isLessThanOrEqualTo: north)
        .orderBy('latitude');
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) q = q.startAfterDocument(cursor);

    final snap = await q.limit(batchSize).get();
    return RawMapBatch(
      docs: [for (final d in snap.docs) (id: d.id, data: d.data())],
      lastCursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      exhausted: snap.docs.length < batchSize,
    );
  }
}
