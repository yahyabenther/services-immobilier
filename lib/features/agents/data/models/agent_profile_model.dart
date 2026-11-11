import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/agent_profile.dart';

/// Firestore <-> [AgentProfile] (spec §6.1). Timestamps are Firestore
/// timestamps (never client formatted strings).
class AgentProfileModel {
  AgentProfileModel._();

  /// Null when the document is too malformed to show (missing name / owner).
  static AgentProfile? tryFromMap(String id, Map<String, dynamic> d) {
    final name = _string(d['professionalName']);
    if (name == null) return null;
    return AgentProfile(
      userId: _string(d['userId']) ?? id,
      professionalName: name,
      description: _string(d['description']) ?? '',
      phone: _string(d['phone']) ?? '',
      publicEmail: _string(d['publicEmail']) ?? '',
      city: _string(d['city']) ?? '',
      kind: AgentProfileKind.parse(_string(d['profileType'])),
      agencyName: _string(d['agencyName']),
      agencyId: _string(d['agencyId']),
      profileImageUrl: _string(d['profileImageUrl']),
      address: _string(d['address']),
      website: _string(d['website']),
      yearsOfExperience: d['yearsOfExperience'] is num ? (d['yearsOfExperience'] as num).toInt() : null,
      languages: _stringList(d['languages']),
      serviceAreas: _stringList(d['serviceAreas']),
      verificationStatus: VerificationStatus.parse(_string(d['verificationStatus'])),
      showPhone: d['showPhone'] != false,
      showEmail: d['showEmail'] != false,
      isPublic: d['isPublic'] != false,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  /// First write. `verificationStatus` is ALWAYS `not_submitted`: it is never
  /// taken from the entity, so a client cannot create an already-verified profile.
  static Map<String, dynamic> toCreateMap(AgentProfile p, {required String uid}) => {
        'userId': uid,
        ..._editable(p),
        'agencyId': null,
        'verificationStatus': 'not_submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Only the fields an agent may change. Never `userId`, `agencyId`,
  /// `verificationStatus` or `createdAt` (Firestore Rules reject them too).
  static Map<String, dynamic> toUpdateMap(AgentProfile p) => {
        ..._editable(p),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static Map<String, dynamic> _editable(AgentProfile p) => {
        'professionalName': p.professionalName.trim(),
        'description': p.description.trim(),
        'phone': p.phone.trim(),
        'publicEmail': p.publicEmail.trim(),
        'city': p.city.trim(),
        'profileType': p.kind.wire,
        'agencyName': p.isAgency ? _clean(p.agencyName) : null,
        'profileImageUrl': _clean(p.profileImageUrl),
        'address': _clean(p.address),
        'website': _clean(p.website),
        'yearsOfExperience': p.yearsOfExperience,
        'languages': p.languages,
        'serviceAreas': p.serviceAreas,
        'showPhone': p.showPhone,
        'showEmail': p.showEmail,
        'isPublic': p.isPublic,
      };

  static String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String? _string(Object? v) => v is String ? _clean(v) : null;

  static List<String> _stringList(Object? v) =>
      v is List ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList() : const [];

  static DateTime? _date(Object? v) => switch (v) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        _ => null,
      };
}
