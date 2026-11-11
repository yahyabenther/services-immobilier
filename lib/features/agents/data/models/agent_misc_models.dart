import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/agent_dashboard_stats.dart';
import '../../domain/entities/agent_notification.dart';
import '../../domain/entities/verification_request.dart';

DateTime? _date(Object? v) => switch (v) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => null,
    };

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

int _int(Object? v) => v is num && v >= 0 ? v.toInt() : 0;

class PropertyStatsModel {
  PropertyStatsModel._();

  static PropertyStats fromMap(String id, Map<String, dynamic> d) => PropertyStats(
        propertyId: id,
        views: _int(d['views']),
        favorites: _int(d['favorites']),
        contacts: _int(d['contacts']),
        shares: _int(d['shares']),
      );
}

class VerificationModel {
  VerificationModel._();

  static VerificationRequest? tryFromMap(String id, Map<String, dynamic> d) {
    final target = _str(d['targetId']);
    if (target == null) return null;
    final docs = d['documentUrls'];
    return VerificationRequest(
      id: id,
      targetId: target,
      status: VerificationStatus.parse(_str(d['status'])),
      documentCount: docs is List ? docs.length : 0,
      submittedAt: _date(d['submittedAt']),
      reviewedAt: _date(d['reviewedAt']),
      rejectionReason: _str(d['rejectionReason']),
      expiresAt: _date(d['expiresAt']),
    );
  }

  /// A new request is ALWAYS `pending`, created by the agent. The decision
  /// fields stay null: only an administrator (trusted function) fills them.
  static Map<String, dynamic> toCreateMap({required String uid, required List<String> storagePaths}) => {
        'targetId': uid,
        'targetType': 'agent',
        'status': 'pending',
        'documentUrls': storagePaths, // private storage references, never public URLs
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'rejectionReason': null,
      };
}

class NotificationModel {
  NotificationModel._();

  static AgentNotification? tryFromMap(String id, Map<String, dynamic> d) {
    final title = _str(d['title']);
    if (title == null) return null;
    return AgentNotification(
      id: id,
      type: AgentNotificationType.parse(_str(d['type'])),
      title: title,
      body: _str(d['body']) ?? '',
      read: d['read'] == true,
      propertyId: _str(d['propertyId']),
      conversationId: _str(d['conversationId']),
      createdAt: _date(d['createdAt']),
    );
  }
}
