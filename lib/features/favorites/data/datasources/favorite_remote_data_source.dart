import 'package:cloud_firestore/cloud_firestore.dart';

typedef RawFavorite = ({String id, Map<String, dynamic> data});

/// The only favorites class that talks to Firestore.
///
/// The document id is deterministic: `{userId}_{propertyId}`. This makes
/// "add twice" impossible (no duplicates), makes `exists` / `remove` a direct
/// document access (no query) and lets the security rules check ownership.
///
/// No `orderBy` on purpose: `where(userId) + orderBy(createdAt)` would need a
/// composite index. The repository sorts the (small) list in memory instead.
class FavoriteRemoteDataSource {
  FavoriteRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Firestore write futures only complete once the SERVER acknowledged. When the
  /// phone is offline they stay pending (the write itself is queued and applied
  /// later), so we stop waiting after this delay instead of freezing the heart.
  static const _writeTimeout = Duration(seconds: 6);

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('favorites');

  static String docId({required String userId, required String propertyId}) => '${userId}_$propertyId';

  Future<void> add({required String userId, required String propertyId}) {
    final write = _col.doc(docId(userId: userId, propertyId: propertyId)).set({
      'userId': userId,
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return write.timeout(_writeTimeout, onTimeout: () {});
  }

  Future<void> remove({required String userId, required String propertyId}) {
    final write = _col.doc(docId(userId: userId, propertyId: propertyId)).delete();
    return write.timeout(_writeTimeout, onTimeout: () {});
  }

  Future<bool> exists({required String userId, required String propertyId}) async {
    final snap = await _col.doc(docId(userId: userId, propertyId: propertyId)).get();
    return snap.exists;
  }

  Future<List<RawFavorite>> getForUser(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return [for (final d in snap.docs) (id: d.id, data: d.data())];
  }

  Stream<List<RawFavorite>> watchForUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => [for (final d in s.docs) (id: d.id, data: d.data())]);
}