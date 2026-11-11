import '../../../properties/domain/entities/property.dart';

/// Document categories of the agent verification (spec §11.1).
enum VerificationCategory {
  identity,
  professional,
  agency;

  String get label => switch (this) {
        VerificationCategory.identity => 'Identity document',
        VerificationCategory.professional => 'Professional document',
        VerificationCategory.agency => 'Agency information',
      };
}

/// The platform's document policy. Spec §11.1: "do not invent a mandatory
/// document list without confirming the policy" -> this is the ONE place to
/// change once business / legal confirm it.
class AgentVerificationPolicy {
  const AgentVerificationPolicy._();

  /// TODO(business): confirm the final list with the product owner / legal.
  static const required = {VerificationCategory.identity, VerificationCategory.professional};

  /// Extra category required only for agency profiles.
  static const requiredForAgency = {VerificationCategory.agency};

  static Set<VerificationCategory> requiredFor({required bool isAgency}) =>
      {...required, if (isAgency) ...requiredForAgency};

  static const maxFilesPerCategory = 3;
}

/// What the agent is allowed to see of a `verifications/{id}` record.
/// Document references are private and never exposed here, only their count.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.targetId,
    required this.status,
    this.documentCount = 0,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.expiresAt,
  });

  final String id;
  final String targetId;
  final VerificationStatus status;
  final int documentCount;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  /// The PUBLIC reason an administrator chose to share. Internal notes live
  /// in an admin-only sub-collection and never reach this model.
  final String? rejectionReason;
  final DateTime? expiresAt;
}

/// Whether a (re)submission is allowed from [status] (spec §11.2 state machine).
bool canSubmitVerification(VerificationStatus status) =>
    status == VerificationStatus.notSubmitted ||
    status == VerificationStatus.rejected ||
    status == VerificationStatus.expired;

/// Status to display: a still-pending request wins over a profile mirror
/// that the backend has not updated yet.
VerificationStatus effectiveVerificationStatus(VerificationStatus profile, VerificationRequest? latest) =>
    latest?.status == VerificationStatus.pending ? VerificationStatus.pending : profile;
