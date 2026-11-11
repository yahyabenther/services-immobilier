import 'package:cloud_firestore/cloud_firestore.dart';

class ListingRemoteDataSource {
  ListingRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('properties');

  String newId() => _col.doc().id;

  /// `set` with a pre-generated id (not `add`): the same call can be repeated safely.
  Future<void> create(String id, Map<String, dynamic> data) => _col.doc(id).set(data);

  /// True when the document already exists and belongs to [ownerId]. Used after a
  /// failed/timed-out `create`: the first attempt may actually have reached the server.
  Future<bool> existsOwnedBy(String id, String ownerId) async {
    final snap = await _col.doc(id).get();
    return snap.exists && snap.data()?['ownerId'] == ownerId;
  }
}
