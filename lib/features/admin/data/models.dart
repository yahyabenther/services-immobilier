// Modèles du module Admin (spec ImmoFind §9, §12, §17, §20, §30).

enum UserRole { buyer, owner, agent }
enum UserStatus { active, suspended, banned, pendingVerification, deleted }
enum VerificationStatus { notSubmitted, pending, approved, rejected, expired }
enum PropertyStatus { draft, pendingReview, published, rejected, suspended, removed, expired }
enum ReportStatus { open, investigating, resolved, rejected }
enum Priority { low, medium, high, critical }
enum TargetType { property, user, agent, message }
enum VerificationKind { owner, agent, property }

extension UserRoleX on UserRole {
  String get label => const {
        UserRole.buyer: 'Acheteur / Locataire',
        UserRole.owner: 'Propriétaire',
        UserRole.agent: 'Agent',
      }[this]!;
}

extension UserStatusX on UserStatus {
  String get label => const {
        UserStatus.active: 'Actif',
        UserStatus.suspended: 'Suspendu',
        UserStatus.banned: 'Banni',
        UserStatus.pendingVerification: 'En vérification',
        UserStatus.deleted: 'Supprimé',
      }[this]!;
}

extension VerificationStatusX on VerificationStatus {
  String get label => const {
        VerificationStatus.notSubmitted: 'Non soumis',
        VerificationStatus.pending: 'En attente',
        VerificationStatus.approved: 'Approuvé',
        VerificationStatus.rejected: 'Rejeté',
        VerificationStatus.expired: 'Expiré',
      }[this]!;
}

extension PropertyStatusX on PropertyStatus {
  String get label => const {
        PropertyStatus.draft: 'Brouillon',
        PropertyStatus.pendingReview: 'En attente',
        PropertyStatus.published: 'Publié',
        PropertyStatus.rejected: 'Rejeté',
        PropertyStatus.suspended: 'Suspendu',
        PropertyStatus.removed: 'Retiré',
        PropertyStatus.expired: 'Expiré',
      }[this]!;
}

extension ReportStatusX on ReportStatus {
  String get label => const {
        ReportStatus.open: 'Ouvert',
        ReportStatus.investigating: 'En cours',
        ReportStatus.resolved: 'Résolu',
        ReportStatus.rejected: 'Rejeté',
      }[this]!;
}

extension PriorityX on Priority {
  String get label => const {
        Priority.low: 'Faible',
        Priority.medium: 'Moyenne',
        Priority.high: 'Haute',
        Priority.critical: 'Critique',
      }[this]!;
}

extension TargetTypeX on TargetType {
  String get label => const {
        TargetType.property: 'Annonce',
        TargetType.user: 'Utilisateur',
        TargetType.agent: 'Agent',
        TargetType.message: 'Message',
      }[this]!;
}

extension VerificationKindX on VerificationKind {
  String get label => const {
        VerificationKind.owner: 'Propriétaire',
        VerificationKind.agent: 'Agent',
        VerificationKind.property: 'Annonce',
      }[this]!;
}

/// Compte admin connecté. Les permissions viennent des custom claims
/// (spec §32-33) — jamais d'un champ lisible/modifiable côté client.
class AdminAccount {
  final String id;
  final String name;
  final String email;
  final String role; // super_admin | admin | moderator | ...
  final Set<String> permissions;
  const AdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });
}

class AppUser {
  final String id;
  String name;
  String email;
  String phone;
  UserRole role;
  UserStatus status;
  VerificationStatus verification;
  final DateTime createdAt;
  DateTime? lastLogin;
  DateTime? suspendedUntil; // null + status suspended = permanent
  String? statusReason;
  DateTime? deletedAt;
  String? deletedBy;
  int listings;
  int reportsAgainst;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.status = UserStatus.active,
    this.verification = VerificationStatus.notSubmitted,
    required this.createdAt,
    this.lastLogin,
    this.suspendedUntil,
    this.statusReason,
    this.deletedAt,
    this.deletedBy,
    this.listings = 0,
    this.reportsAgainst = 0,
  });
}

class DocumentRef {
  final String name;
  final bool provided;
  const DocumentRef(this.name, this.provided);
}

class AdminProperty {
  final String id;
  final String ownerId;
  final String ownerName;
  String title;
  String description;
  double price;
  String city;
  String area;
  String type;
  int surface;
  int bedrooms;
  int bathrooms;
  int photos;
  PropertyStatus status;
  bool verified;
  String? statusReason;
  final DateTime createdAt;
  final List<DocumentRef> documents;
  int reportCount;
  int riskScore; // 0-100, spec §23

  AdminProperty({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.price,
    required this.city,
    required this.area,
    required this.type,
    required this.surface,
    required this.bedrooms,
    required this.bathrooms,
    required this.photos,
    this.status = PropertyStatus.pendingReview,
    this.verified = false,
    this.statusReason,
    required this.createdAt,
    this.documents = const [],
    this.reportCount = 0,
    this.riskScore = 10,
  });
}

class Report {
  final String id;
  final String reporterName;
  final TargetType targetType;
  final String targetId;
  final String targetLabel;
  final String reason;
  final String description;
  ReportStatus status;
  Priority priority;
  String? assignedTo;
  String? resolution;
  final DateTime createdAt;
  DateTime? resolvedAt;

  Report({
    required this.id,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.reason,
    required this.description,
    this.status = ReportStatus.open,
    this.priority = Priority.medium,
    this.assignedTo,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });
}

class VerificationRequest {
  final String id;
  final VerificationKind kind;
  final String subjectId; // userId ou propertyId
  final String subjectName;
  final List<DocumentRef> documents;
  VerificationStatus status;
  String? reviewedBy;
  String? reason;
  final DateTime createdAt;

  VerificationRequest({
    required this.id,
    required this.kind,
    required this.subjectId,
    required this.subjectName,
    required this.documents,
    this.status = VerificationStatus.pending,
    this.reviewedBy,
    this.reason,
    required this.createdAt,
  });
}

class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String target;
  final String type;
  final DateTime? scheduledAt;
  final String createdBy;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.type,
    this.scheduledAt,
    required this.createdBy,
    required this.createdAt,
  });
}

class AuditLog {
  final String id;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String? previousValue;
  final String? newValue;
  final String? reason;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.previousValue,
    this.newValue,
    this.reason,
    required this.timestamp,
  });
}
