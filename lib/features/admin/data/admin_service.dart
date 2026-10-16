import 'package:flutter/foundation.dart';
import 'models.dart';

class AdminAuthException implements Exception {
  final String message;
  AdminAuthException(this.message);
  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  final String permission;
  PermissionDeniedException(this.permission);
  @override
  String toString() => 'Permission refusée : $permission';
}

const kAllAdminPermissions = <String>{
  'users.read', 'users.update', 'users.suspend', 'users.delete',
  'properties.read', 'properties.approve', 'properties.reject',
  'properties.remove', 'properties.restore',
  'verification.read', 'verification.approve', 'verification.reject',
  'reports.read', 'reports.resolve',
  'notifications.create', 'notifications.send',
  'analytics.read', 'settings.read', 'settings.update', 'audit.read',
};

/// Service admin en mémoire (données de démonstration).
///
/// TODO(firebase): remplacer par Firebase Auth + custom claims et des
/// Cloud Functions qui appliquent les permissions CÔTÉ SERVEUR et écrivent
/// les audit_logs. Les vérifications ci-dessous ne sont qu'un garde-fou UI.
class AdminService extends ChangeNotifier {
  AdminService._() {
    _seed();
  }
  static final AdminService instance = AdminService._();

  // DEMO UNIQUEMENT — à supprimer avant toute mise en production.
  static const demoEmail = 'admin@immofind.tn';
  static const demoPassword = 'Admin#2026';

  AdminAccount? admin;
  bool get isAuthenticated => admin != null;

  final List<AppUser> users = [];
  final List<AdminProperty> properties = [];
  final List<Report> reports = [];
  final List<VerificationRequest> verifications = [];
  final List<AdminNotification> notifications = [];
  final List<AuditLog> auditLogs = [];

  final List<String> propertyTypes = ['Appartement', 'Villa', 'Maison', 'Duplex', 'Terrain', 'Bureau', 'Commerce'];
  final List<String> amenities = ['Parking', 'Piscine', 'Ascenseur', 'Jardin', 'Vue mer', 'Climatisation', 'Terrasse'];
  final List<String> cities = ['Tunis', 'Ariana', 'Ben Arous', 'Sousse', 'Sfax', 'Nabeul', 'Tozeur'];

  int _seq = 1000;
  String _id(String p) => '$p${_seq++}';

  // ───────── Auth ─────────
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      throw AdminAuthException('Identifiants invalides ou accès refusé.');
    }
    admin = const AdminAccount(
      id: 'adm_1',
      name: 'Administrateur',
      email: demoEmail,
      role: 'admin',
      permissions: kAllAdminPermissions,
    );
    _log('admin.login', 'admin', admin!.id);
    notifyListeners();
  }

  void logout() {
    if (admin != null) _log('admin.logout', 'admin', admin!.id);
    admin = null;
    notifyListeners();
  }

  void _require(String permission) {
    if (admin == null || !admin!.permissions.contains(permission)) {
      throw PermissionDeniedException(permission);
    }
  }

  void _log(String action, String targetType, String targetId,
      {String? prev, String? next, String? reason}) {
    auditLogs.insert(
      0,
      AuditLog(
        id: _id('log_'),
        adminEmail: admin?.email ?? 'system',
        action: action,
        targetType: targetType,
        targetId: targetId,
        previousValue: prev,
        newValue: next,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ───────── Statistiques ─────────
  int get totalUsers => users.where((u) => u.status != UserStatus.deleted).length;
  int get verifiedUsers => users.where((u) => u.verification == VerificationStatus.approved).length;
  int get suspendedUsers => users.where((u) => u.status == UserStatus.suspended || u.status == UserStatus.banned).length;
  int get newUsersToday => users.where((u) => _isToday(u.createdAt)).length;
  int get activeToday => users.where((u) => u.lastLogin != null && _isToday(u.lastLogin!)).length;
  int propertyCount(PropertyStatus s) => properties.where((p) => p.status == s).length;
  int get reportedProperties => properties.where((p) => p.reportCount > 0 && p.status != PropertyStatus.removed).length;
  int reportCount(ReportStatus s) => reports.where((r) => r.status == s).length;
  int get highPriorityReports => reports.where((r) =>
      (r.priority == Priority.high || r.priority == Priority.critical) &&
      (r.status == ReportStatus.open || r.status == ReportStatus.investigating)).length;
  int get pendingVerifications => verifications.where((v) => v.status == VerificationStatus.pending).length;

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Map<String, int> listingsByCity() {
    final m = <String, int>{};
    for (final p in properties) {
      m[p.city] = (m[p.city] ?? 0) + 1;
    }
    return m;
  }

  // ───────── Utilisateurs ─────────
  AppUser? userById(String id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  void suspendUser(String id, String reason, Duration? duration) {
    _require('users.suspend');
    final u = userById(id)!;
    final prev = u.status.name;
    u.status = UserStatus.suspended;
    u.suspendedUntil = duration == null ? null : DateTime.now().add(duration);
    u.statusReason = reason;
    _log('user.suspend', 'user', id, prev: prev, next: 'suspended', reason: reason);
    notifyListeners();
  }

  void restoreUser(String id) {
    _require('users.suspend');
    final u = userById(id)!;
    final prev = u.status.name;
    u.status = UserStatus.active;
    u.suspendedUntil = null;
    u.statusReason = null;
    u.deletedAt = null;
    u.deletedBy = null;
    _log('user.restore', 'user', id, prev: prev, next: 'active');
    notifyListeners();
  }

  void banUser(String id, String reason) {
    _require('users.suspend');
    final u = userById(id)!;
    final prev = u.status.name;
    u.status = UserStatus.banned;
    u.statusReason = reason;
    _log('user.ban', 'user', id, prev: prev, next: 'banned', reason: reason);
    notifyListeners();
  }

  /// Suppression douce (spec §43) : deletedAt / deletedBy / deleteReason.
  void deleteUser(String id, String reason) {
    _require('users.delete');
    final u = userById(id)!;
    final prev = u.status.name;
    u.status = UserStatus.deleted;
    u.deletedAt = DateTime.now();
    u.deletedBy = admin!.id;
    u.statusReason = reason;
    _log('user.delete', 'user', id, prev: prev, next: 'deleted', reason: reason);
    notifyListeners();
  }

  void changeUserRole(String id, UserRole role) {
    _require('users.update');
    final u = userById(id)!;
    final prev = u.role.name;
    u.role = role;
    _log('user.changeRole', 'user', id, prev: prev, next: role.name);
    notifyListeners();
  }

  // ───────── Annonces ─────────
  AdminProperty? propertyById(String id) {
    for (final p in properties) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _setProperty(String id, PropertyStatus next, String action, String perm,
      {String? reason, bool? verified}) {
    _require(perm);
    final p = propertyById(id)!;
    final prev = p.status.name;
    p.status = next;
    p.statusReason = reason;
    if (verified != null) p.verified = verified;
    _log(action, 'property', id, prev: prev, next: next.name, reason: reason);
    notifyListeners();
  }

  void approveProperty(String id, {bool verified = false}) =>
      _setProperty(id, PropertyStatus.published, 'property.approve', 'properties.approve', verified: verified ? true : null);

  void rejectProperty(String id, String reason) =>
      _setProperty(id, PropertyStatus.rejected, 'property.reject', 'properties.reject', reason: reason);

  void suspendProperty(String id, String reason) =>
      _setProperty(id, PropertyStatus.suspended, 'property.suspend', 'properties.remove', reason: reason);

  void removeProperty(String id, String reason) =>
      _setProperty(id, PropertyStatus.removed, 'property.remove', 'properties.remove', reason: reason);

  /// removed -> draft, suspended -> published (spec §12).
  void restoreProperty(String id) {
    final p = propertyById(id)!;
    final next = p.status == PropertyStatus.suspended ? PropertyStatus.published : PropertyStatus.draft;
    _setProperty(id, next, 'property.restore', 'properties.restore');
  }

  void verifyProperty(String id) {
    _require('properties.approve');
    final p = propertyById(id)!;
    p.verified = true;
    _log('property.verify', 'property', id, prev: 'false', next: 'true');
    notifyListeners();
  }

  // ───────── Signalements ─────────
  void startInvestigation(String id) {
    _require('reports.resolve');
    final r = reports.firstWhere((e) => e.id == id);
    final prev = r.status.name;
    r.status = ReportStatus.investigating;
    r.assignedTo = admin!.email;
    _log('report.investigate', 'report', id, prev: prev, next: 'investigating');
    notifyListeners();
  }

  void resolveReport(String id, String resolution) {
    _require('reports.resolve');
    final r = reports.firstWhere((e) => e.id == id);
    final prev = r.status.name;
    r.status = ReportStatus.resolved;
    r.resolution = resolution;
    r.resolvedAt = DateTime.now();
    _log('report.resolve', 'report', id, prev: prev, next: 'resolved', reason: resolution);
    notifyListeners();
  }

  void rejectReport(String id, String reason) {
    _require('reports.resolve');
    final r = reports.firstWhere((e) => e.id == id);
    final prev = r.status.name;
    r.status = ReportStatus.rejected;
    r.resolution = reason;
    r.resolvedAt = DateTime.now();
    _log('report.reject', 'report', id, prev: prev, next: 'rejected', reason: reason);
    notifyListeners();
  }

  // ───────── Vérification ─────────
  void approveVerification(String id) {
    _require('verification.approve');
    final v = verifications.firstWhere((e) => e.id == id);
    v.status = VerificationStatus.approved;
    v.reviewedBy = admin!.email;
    if (v.kind == VerificationKind.property) {
      propertyById(v.subjectId)?.verified = true;
    } else {
      final u = userById(v.subjectId);
      if (u != null) {
        u.verification = VerificationStatus.approved;
        if (u.status == UserStatus.pendingVerification) u.status = UserStatus.active;
      }
    }
    _log('verification.approve', 'verification', id, prev: 'pending', next: 'approved');
    notifyListeners();
  }

  void rejectVerification(String id, String reason) {
    _require('verification.reject');
    final v = verifications.firstWhere((e) => e.id == id);
    v.status = VerificationStatus.rejected;
    v.reviewedBy = admin!.email;
    v.reason = reason;
    if (v.kind != VerificationKind.property) {
      userById(v.subjectId)?.verification = VerificationStatus.rejected;
    }
    _log('verification.reject', 'verification', id, prev: 'pending', next: 'rejected', reason: reason);
    notifyListeners();
  }

  // ───────── Notifications ─────────
  /// TODO(firebase): déclencher FCM depuis le backend.
  void sendNotification({
    required String title,
    required String body,
    required String target,
    required String type,
    DateTime? scheduledAt,
  }) {
    _require('notifications.send');
    final n = AdminNotification(
      id: _id('ntf_'),
      title: title,
      body: body,
      target: target,
      type: type,
      scheduledAt: scheduledAt,
      createdBy: admin!.email,
      createdAt: DateTime.now(),
    );
    notifications.insert(0, n);
    _log('notification.send', 'notification', n.id, next: target, reason: title);
    notifyListeners();
  }

  // ───────── Contenu configurable ─────────
  void addContent(List<String> list, String kind, String value) {
    _require('settings.update');
    final v = value.trim();
    if (v.isEmpty || list.contains(v)) return;
    list.add(v);
    _log('content.add', kind, v, next: v);
    notifyListeners();
  }

  void removeContent(List<String> list, String kind, String value) {
    _require('settings.update');
    list.remove(value);
    _log('content.remove', kind, value, prev: value);
    notifyListeners();
  }

  // ───────── Fil d'activité & alertes ─────────
  List<AuditLog> recentActivity([int n = 8]) => auditLogs.take(n).toList();

  /// Éléments urgents triés par priorité (spec §45).
  List<({Priority priority, String text})> get urgentItems {
    final items = <({Priority priority, String text})>[];
    final crit = reports.where((r) => r.priority == Priority.critical &&
        r.status != ReportStatus.resolved && r.status != ReportStatus.rejected).length;
    if (crit > 0) items.add((priority: Priority.critical, text: '$crit signalement(s) critique(s)'));
    if (highPriorityReports - crit > 0) {
      items.add((priority: Priority.high, text: '${highPriorityReports - crit} signalement(s) prioritaire(s)'));
    }
    final risky = properties.where((p) => p.riskScore >= 70 && p.status == PropertyStatus.pendingReview).length;
    if (risky > 0) items.add((priority: Priority.high, text: '$risky annonce(s) à risque élevé en attente'));
    if (pendingVerifications > 0) items.add((priority: Priority.medium, text: '$pendingVerifications demande(s) de vérification'));
    final pend = propertyCount(PropertyStatus.pendingReview);
    if (pend > 0) items.add((priority: Priority.medium, text: '$pend annonce(s) en attente de validation'));
    return items;
  }

  // ───────── Données de démonstration ─────────
  void _seed() {
    final now = DateTime.now();
    DateTime ago(int d, [int h = 0]) => now.subtract(Duration(days: d, hours: h));

    users.addAll([
      AppUser(id: 'u1', name: 'Ahmed Ali', email: 'ahmed@example.com', phone: '+216 20 111 222', role: UserRole.buyer, verification: VerificationStatus.approved, createdAt: ago(120), lastLogin: ago(0, 2)),
      AppUser(id: 'u2', name: 'Karim Ben Ali', email: 'karim@example.com', phone: '+216 22 333 444', role: UserRole.owner, verification: VerificationStatus.approved, createdAt: ago(90), lastLogin: ago(0, 1), listings: 3),
      AppUser(id: 'u3', name: 'Agence TN Immo', email: 'contact@tnimmo.tn', phone: '+216 71 555 666', role: UserRole.agent, status: UserStatus.pendingVerification, verification: VerificationStatus.pending, createdAt: ago(3), lastLogin: ago(1), listings: 2),
      AppUser(id: 'u4', name: 'Sana Trabelsi', email: 'sana@example.com', phone: '+216 55 777 888', role: UserRole.owner, verification: VerificationStatus.pending, createdAt: ago(5), lastLogin: ago(2), listings: 1),
      AppUser(id: 'u5', name: 'Mehdi Gharbi', email: 'mehdi@example.com', phone: '+216 98 123 456', role: UserRole.owner, createdAt: ago(1), lastLogin: ago(0, 5), listings: 6, reportsAgainst: 4),
      AppUser(id: 'u6', name: 'Leila Mansour', email: 'leila@example.com', phone: '+216 50 987 654', role: UserRole.buyer, createdAt: ago(0, 3), lastLogin: ago(0, 1)),
      AppUser(id: 'u7', name: 'Omar Jlassi', email: 'omar@example.com', phone: '+216 29 456 789', role: UserRole.buyer, status: UserStatus.suspended, statusReason: 'Messages abusifs', suspendedUntil: now.add(const Duration(days: 5)), createdAt: ago(60), lastLogin: ago(9), reportsAgainst: 2),
    ]);

    const okDocs = [DocumentRef("Titre de propriété", true), DocumentRef("Pièce d'identité", true)];
    properties.addAll([
      AdminProperty(id: 'P1024', ownerId: 'u2', ownerName: 'Karim Ben Ali', title: 'Villa contemporaine vue mer', description: 'Villa de 4 chambres avec piscine et vue panoramique sur la mer, quartier calme.', price: 1250000, city: 'Tunis', area: 'La Marsa', type: 'Villa', surface: 320, bedrooms: 4, bathrooms: 3, photos: 12, createdAt: ago(0, 2), documents: okDocs, riskScore: 12),
      AdminProperty(id: 'P1025', ownerId: 'u4', ownerName: 'Sana Trabelsi', title: 'Appartement S+2 Les Berges du Lac', description: 'Appartement lumineux S+2 au 3e étage, proche commerces.', price: 420000, city: 'Tunis', area: 'Les Berges du Lac', type: 'Appartement', surface: 110, bedrooms: 2, bathrooms: 1, photos: 6, createdAt: ago(0, 6), documents: const [DocumentRef("Titre de propriété", false), DocumentRef("Pièce d'identité", true)], riskScore: 38),
      AdminProperty(id: 'P1026', ownerId: 'u5', ownerName: 'Mehdi Gharbi', title: 'Villa de luxe 80 000 TND !!!', description: 'Offre exceptionnelle, contactez-moi vite par WhatsApp.', price: 80000, city: 'Sousse', area: 'Khezama', type: 'Villa', surface: 400, bedrooms: 6, bathrooms: 4, photos: 1, createdAt: ago(0, 1), documents: const [DocumentRef("Titre de propriété", false), DocumentRef("Pièce d'identité", false)], reportCount: 4, riskScore: 87),
      AdminProperty(id: 'P1027', ownerId: 'u3', ownerName: 'Agence TN Immo', title: 'Bureau open space Centre Urbain Nord', description: 'Plateau de bureaux de 150 m², parking inclus.', price: 2800, city: 'Tunis', area: 'Centre Urbain Nord', type: 'Bureau', surface: 150, bedrooms: 0, bathrooms: 2, photos: 8, createdAt: ago(1), documents: okDocs, riskScore: 20),
      AdminProperty(id: 'P1001', ownerId: 'u2', ownerName: 'Karim Ben Ali', title: 'Duplex Ennasr', description: 'Duplex récent, résidence gardée.', price: 560000, city: 'Ariana', area: 'Ennasr', type: 'Duplex', surface: 180, bedrooms: 3, bathrooms: 2, photos: 10, status: PropertyStatus.published, verified: true, createdAt: ago(20), documents: okDocs, riskScore: 5),
      AdminProperty(id: 'P1002', ownerId: 'u2', ownerName: 'Karim Ben Ali', title: 'Appartement S+3 Sousse centre', description: 'Appartement rénové à 5 min de la plage.', price: 310000, city: 'Sousse', area: 'Sousse Ville', type: 'Appartement', surface: 125, bedrooms: 3, bathrooms: 2, photos: 7, status: PropertyStatus.published, createdAt: ago(15), documents: okDocs, reportCount: 1, riskScore: 25),
      AdminProperty(id: 'P1003', ownerId: 'u4', ownerName: 'Sana Trabelsi', title: 'Terrain constructible Nabeul', description: 'Terrain de 600 m², titre bleu.', price: 190000, city: 'Nabeul', area: 'Hammamet', type: 'Terrain', surface: 600, bedrooms: 0, bathrooms: 0, photos: 3, status: PropertyStatus.rejected, statusReason: 'Document de propriété non vérifiable', createdAt: ago(8), riskScore: 45),
    ]);

    reports.addAll([
      Report(id: 'R201', reporterName: 'Ahmed Ali', targetType: TargetType.property, targetId: 'P1026', targetLabel: 'Villa de luxe 80 000 TND !!!', reason: 'Arnaque', description: 'Prix irréaliste et demande de paiement avant visite.', priority: Priority.critical, createdAt: ago(0, 3)),
      Report(id: 'R202', reporterName: 'Leila Mansour', targetType: TargetType.user, targetId: 'u5', targetLabel: 'Mehdi Gharbi', reason: 'Annonces en double', description: 'Mêmes photos utilisées sur plusieurs annonces.', priority: Priority.high, createdAt: ago(1)),
      Report(id: 'R203', reporterName: 'Sana Trabelsi', targetType: TargetType.property, targetId: 'P1002', targetLabel: 'Appartement S+3 Sousse centre', reason: 'Information incorrecte', description: 'La surface annoncée semble erronée.', status: ReportStatus.investigating, assignedTo: demoEmail, createdAt: ago(2)),
      Report(id: 'R204', reporterName: 'Karim Ben Ali', targetType: TargetType.message, targetId: 'm88', targetLabel: 'Message de Omar Jlassi', reason: 'Contenu offensif', description: 'Insultes dans la messagerie.', status: ReportStatus.resolved, resolution: 'Utilisateur suspendu 7 jours.', priority: Priority.medium, createdAt: ago(10), resolvedAt: ago(9)),
    ]);

    verifications.addAll([
      VerificationRequest(id: 'V301', kind: VerificationKind.agent, subjectId: 'u3', subjectName: 'Agence TN Immo', documents: const [DocumentRef("Pièce d'identité", true), DocumentRef('Registre de commerce', true), DocumentRef('Attestation professionnelle', false)], createdAt: ago(3)),
      VerificationRequest(id: 'V302', kind: VerificationKind.owner, subjectId: 'u4', subjectName: 'Sana Trabelsi', documents: const [DocumentRef('Carte d\'identité', true), DocumentRef('Titre de propriété', false)], createdAt: ago(5)),
      VerificationRequest(id: 'V303', kind: VerificationKind.property, subjectId: 'P1024', subjectName: 'Villa contemporaine vue mer', documents: okDocs, createdAt: ago(0, 2)),
    ]);

    notifications.add(AdminNotification(id: 'ntf_1', title: 'Bienvenue sur ImmoFind', body: 'Découvrez les nouvelles fonctionnalités de la plateforme.', target: 'Tous les utilisateurs', type: 'Annonce', createdBy: demoEmail, createdAt: ago(14)));

    // Quelques entrées d'audit initiales pour le fil d'activité.
    auditLogs.addAll([
      AuditLog(id: 'log_a', adminEmail: demoEmail, action: 'property.approve', targetType: 'property', targetId: 'P1001', previousValue: 'pendingReview', newValue: 'published', timestamp: ago(20)),
      AuditLog(id: 'log_b', adminEmail: demoEmail, action: 'user.suspend', targetType: 'user', targetId: 'u7', previousValue: 'active', newValue: 'suspended', reason: 'Messages abusifs', timestamp: ago(4)),
      AuditLog(id: 'log_c', adminEmail: demoEmail, action: 'property.reject', targetType: 'property', targetId: 'P1003', previousValue: 'pendingReview', newValue: 'rejected', reason: 'Document de propriété non vérifiable', timestamp: ago(8)),
    ]);
    auditLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
