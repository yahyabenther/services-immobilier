import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../properties/domain/entities/property.dart';
import '../domain/conversation.dart';

enum ConversationFailureType { notSignedIn, ownListing, unavailable, empty, tooLong, permissionDenied, network, unknown }

class ConversationFailure implements Exception {
  const ConversationFailure(this.type);
  final ConversationFailureType type;

  String get message => switch (type) {
        ConversationFailureType.notSignedIn => 'Please sign in to contact the advertiser.',
        ConversationFailureType.ownListing => 'This is your own listing.',
        ConversationFailureType.unavailable => 'This property is no longer available.',
        ConversationFailureType.empty => 'Write a message first.',
        ConversationFailureType.tooLong => 'Your message is too long.',
        ConversationFailureType.permissionDenied => 'You are not allowed to perform this action.',
        ConversationFailureType.network => 'Network problem. Check your connection and try again.',
        ConversationFailureType.unknown => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => 'ConversationFailure($type)';
}

/// Minimal shared messaging base used by "Contact agent" and the agent's
/// Inquiries page. Module 09 builds the full inbox on top of these collections.
class ConversationRepository {
  ConversationRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const maxMessageLength = 2000;

  CollectionReference<Map<String, dynamic>> get _conversations => _db.collection('conversations');

  String get _uid {
    final id = _auth.currentUser?.uid;
    if (id == null) throw const ConversationFailure(ConversationFailureType.notSignedIn);
    return id;
  }

  static String idFor(String propertyId, String userId) => '${propertyId}_$userId';

  /// Who receives the inquiry: the responsible professional, else the owner.
  static String recipientOf(Property p) => (p.agentId != null && p.agentId!.isNotEmpty) ? p.agentId! : p.ownerId;

  ConversationFailure _map(Object e) {
    if (e is ConversationFailure) return e;
    if (e is FirebaseException) {
      debugPrint('Conversation error [${e.code}]: ${e.message}');
      return ConversationFailure(switch (e.code) {
        'permission-denied' => ConversationFailureType.permissionDenied,
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => ConversationFailureType.network,
        _ => ConversationFailureType.unknown,
      });
    }
    debugPrint('Conversation unexpected error: $e');
    return const ConversationFailure(ConversationFailureType.unknown);
  }

  /// Find or create the thread of ([property], current user). Idempotent.
  Future<Conversation> openOrCreate(Property property, {String? userName}) async {
    try {
      final me = _uid;
      final recipient = recipientOf(property);
      if (recipient == me) throw const ConversationFailure(ConversationFailureType.ownListing);
      if (!property.isPublic) throw const ConversationFailure(ConversationFailureType.unavailable);

      final ref = _conversations.doc(idFor(property.id, me));
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) return _fromMap(snap.id, snap.data()!)!;

      await ref.set({
        'participants': [me, recipient],
        'userId': me,
        'recipientId': recipient,
        'propertyId': property.id,
        'userName': (userName?.trim().isEmpty ?? true) ? null : userName!.trim(),
        'propertyTitle': property.title,
        'propertyImage': property.mainImage,
        'lastMessage': null,
        'lastMessageAt': null,
        'lastSenderId': null,
        'lastReadAt': <String, dynamic>{},
        'messageCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return Conversation(
        id: ref.id,
        participants: [me, recipient],
        userId: me,
        recipientId: recipient,
        propertyId: property.id,
        userName: userName,
        propertyTitle: property.title,
        propertyImage: property.mainImage,
      );
    } catch (e) {
      throw _map(e);
    }
  }

  Stream<Conversation?> watchConversation(String id) => _conversations.doc(id).snapshots().map((s) {
        final d = s.data();
        return (!s.exists || d == null) ? null : _fromMap(s.id, d);
      });

  /// Inquiries received by [recipientId] (agent / owner). Index:
  /// recipientId ASC, lastMessageAt DESC. Threads without messages are hidden.
  Stream<List<Conversation>> watchReceived(String recipientId, {int limit = 50}) => _conversations
      .where('recipientId', isEqualTo: recipientId)
      .orderBy('lastMessageAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?_fromMap(d.id, d.data())].where((c) => c.hasMessages).toList());

  /// Newest first, so a reversed ListView shows the latest at the bottom.
  Stream<List<ChatMessage>> watchMessages(String conversationId, {int limit = 100}) => _conversations
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?_message(d.id, d.data())]);

  Future<void> sendMessage(String conversationId, String text) async {
    try {
      final me = _uid;
      final t = text.trim();
      if (t.isEmpty) throw const ConversationFailure(ConversationFailureType.empty);
      if (t.length > maxMessageLength) throw const ConversationFailure(ConversationFailureType.tooLong);

      final convo = _conversations.doc(conversationId);
      final msg = convo.collection('messages').doc();
      final batch = _db.batch()
        ..set(msg, {
          'senderId': me,
          'text': t,
          'attachments': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..update(convo, {
          'lastMessage': t.length > 140 ? '${t.substring(0, 140)}…' : t,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': me,
          'lastReadAt.$me': FieldValue.serverTimestamp(),
        });
      await batch.commit();
    } catch (e) {
      throw _map(e);
    }
  }

  /// Rules allow a participant to change ONLY `lastReadAt.<own uid>`.
  Future<void> markRead(String conversationId) async {
    try {
      await _conversations.doc(conversationId).update({'lastReadAt.$_uid': FieldValue.serverTimestamp()});
    } catch (_) {
      // Read receipts are best effort.
    }
  }

  // ---- mapping ----------------------------------------------------------
  static DateTime? _date(Object? v) => switch (v) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        _ => null,
      };

  static String? _s(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  static Conversation? _fromMap(String id, Map<String, dynamic> d) {
    final user = _s(d['userId']);
    final recipient = _s(d['recipientId']);
    final property = _s(d['propertyId']);
    if (user == null || recipient == null || property == null) return null;
    final read = d['lastReadAt'];
    return Conversation(
      id: id,
      participants: d['participants'] is List ? (d['participants'] as List).whereType<String>().toList() : [user, recipient],
      userId: user,
      recipientId: recipient,
      propertyId: property,
      userName: _s(d['userName']),
      propertyTitle: _s(d['propertyTitle']),
      propertyImage: _s(d['propertyImage']),
      lastMessage: _s(d['lastMessage']),
      lastMessageAt: _date(d['lastMessageAt']),
      lastSenderId: _s(d['lastSenderId']),
      lastReadAt: read is Map
          ? {
              for (final e in read.entries)
                if (e.key is String && _date(e.value) != null) e.key as String: _date(e.value)!,
            }
          : const {},
      createdAt: _date(d['createdAt']),
    );
  }

  static ChatMessage? _message(String id, Map<String, dynamic> d) {
    final sender = _s(d['senderId']);
    final text = _s(d['text']);
    if (sender == null || text == null) return null;
    return ChatMessage(id: id, senderId: sender, text: text, createdAt: _date(d['createdAt']));
  }
}
