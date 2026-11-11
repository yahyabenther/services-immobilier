import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/agent_failure.dart';
import '../../../properties/domain/entities/property.dart';

typedef RawDoc = ({String id, Map<String, dynamic> data});

List<RawDoc> _raw(QuerySnapshot<Map<String, dynamic>> s) => [for (final d in s.docs) (id: d.id, data: d.data())];

/// Firestore access of the Agent module. It owns no business rule.
///
/// The current user id ALWAYS comes from Firebase Authentication ([uid]), never
/// from a parameter the UI could forge (spec §12 requirement 2).
class AgentRemoteDataSource {
  AgentRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get uid {
    final id = _auth.currentUser?.uid;
    if (id == null) throw const AgentFailure(AgentFailureType.notSignedIn);
    return id;
  }

  CollectionReference<Map<String, dynamic>> get _profiles => _db.collection('agent_profiles');
  CollectionReference<Map<String, dynamic>> get _properties => _db.collection('properties');

  // ---- profile ----------------------------------------------------------
  Future<RawDoc?> getProfile(String userId) async {
    final snap = await _profiles.doc(userId).get();
    final data = snap.data();
    return (!snap.exists || data == null) ? null : (id: snap.id, data: data);
  }

  Stream<RawDoc?> watchProfile(String userId) => _profiles.doc(userId).snapshots().map((snap) {
        final data = snap.data();
        return (!snap.exists || data == null) ? null : (id: snap.id, data: data);
      });

  /// Rules allow a create only when the document id is the caller's uid.
  Future<void> createProfile(Map<String, dynamic> data) => _profiles.doc(uid).set(data);

  Future<void> updateProfile(Map<String, dynamic> data) => _profiles.doc(uid).update(data);

  // ---- listings ---------------------------------------------------------
  /// Index: agentId ASC, updatedAt DESC (see backend/firestore.indexes.json).
  Stream<List<RawDoc>> watchAgentListings(String agentId, {required int limit}) => _properties
      .where('agentId', isEqualTo: agentId)
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_raw);

  Future<List<RawDoc>> fetchAgentListings(String agentId, {required int limit}) async => _raw(await _properties
      .where('agentId', isEqualTo: agentId)
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .get());

  /// Index: agentId ASC, status ASC, publishedAt DESC.
  Future<List<RawDoc>> fetchPublishedListings(String agentId, {required int limit}) async =>
      _raw(await _properties
          .where('agentId', isEqualTo: agentId)
          .where('status', isEqualTo: PropertyStatus.published.wire)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get());

  /// Stats documents carry an `agentId` copy (written by the backend) so this
  /// query is provable by Firestore Rules.
  Stream<List<RawDoc>> watchStats(String agentId) =>
      _db.collection('property_stats').where('agentId', isEqualTo: agentId).snapshots().map(_raw);

  Future<List<RawDoc>> fetchStats(String agentId) async =>
      _raw(await _db.collection('property_stats').where('agentId', isEqualTo: agentId).get());

  /// Status transitions only (draft/rejected -> pending_review, -> removed).
  /// Rules reject every other field and every moderation status.
  Future<void> updateListingStatus(String propertyId, String wireStatus) => _properties.doc(propertyId).update({
        'status': wireStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ---- verification -----------------------------------------------------
  Future<void> createVerification(Map<String, dynamic> data) => _db.collection('verifications').add(data);

  /// Index: targetId ASC, targetType ASC, submittedAt DESC.
  Stream<RawDoc?> watchLatestVerification(String agentId) => _db
      .collection('verifications')
      .where('targetId', isEqualTo: agentId)
      .where('targetType', isEqualTo: 'agent')
      .orderBy('submittedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : (id: s.docs.first.id, data: s.docs.first.data()));

  // ---- notifications ----------------------------------------------------
  /// Index: userId ASC, createdAt DESC.
  Stream<List<RawDoc>> watchNotifications(String userId, {required int limit}) => _db
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_raw);

  /// Rules allow changing ONLY `read` on your own notification.
  Future<void> markNotificationRead(String id) => _db.collection('notifications').doc(id).update({'read': true});
}
