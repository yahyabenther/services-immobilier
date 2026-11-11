import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/listing_lifecycle.dart';

/// What an agent may do with one of THEIR listings, by status (spec §5.5).
/// This only drives the UI and the client guard. The real enforcement is in
/// Firestore Rules (`backend/firestore.rules`): never trust it alone.
///
/// The lifecycle is the SHARED one (Property.status). The agent module never
/// invents another status system and never sets a moderation status
/// (published / rejected / suspended / expired): administrators do.
class ListingPolicy {
  ListingPolicy._();

  static bool canViewPublic(PropertyStatus s) => s == PropertyStatus.published;

  /// Editing happens in the publishing module (Module 08).
  static bool canEdit(PropertyStatus s) => switch (s) {
        PropertyStatus.draft || PropertyStatus.rejected || PropertyStatus.published => true,
        _ => false,
      };

  /// draft | rejected -> pending_review (after the shared validation).
  /// Driven by the shared lifecycle table (mirrors the Firestore rules).
  static bool canSubmit(PropertyStatus s) => canMove(s, PropertyStatus.pendingReview);

  /// -> removed. Allowed from every non-final, non-suspended state.
  static bool canWithdraw(PropertyStatus s) => canMove(s, PropertyStatus.removed);

  static String statusLabel(PropertyStatus s) => switch (s) {
        PropertyStatus.draft => 'Draft',
        PropertyStatus.pendingReview => 'Pending review',
        PropertyStatus.published => 'Published',
        PropertyStatus.rejected => 'Rejected',
        PropertyStatus.suspended => 'Suspended',
        PropertyStatus.removed => 'Withdrawn',
        PropertyStatus.expired => 'Expired',
      };

  /// Short hint shown on the card for states that need the agent's attention.
  static String? statusHint(PropertyStatus s) => switch (s) {
        PropertyStatus.rejected => 'Needs changes before it can be resubmitted.',
        PropertyStatus.suspended => 'Suspended by moderation. Contact support.',
        PropertyStatus.pendingReview => 'Waiting for an administrator.',
        PropertyStatus.expired => 'No longer visible to users.',
        _ => null,
      };
}

/// The shared Property Publishing validation (spec §10.2), re-checked before an
/// agent submits a draft / rejected listing. Never weaker than Module 08.
class ListingSubmissionCheck {
  ListingSubmissionCheck._();

  /// Empty list == the listing may be submitted.
  static List<String> problems(Property p) => [
        if (p.title.trim().isEmpty) 'A title is required.',
        if (p.description.trim().isEmpty) 'A description is required.',
        if (p.price <= 0) 'The price must be greater than zero.',
        if ((p.surface ?? 0) <= 0) 'The surface must be greater than zero.',
        if (p.images.isEmpty) 'Add at least one photo.',
        if (p.governorate.trim().isEmpty) 'A valid location is required.',
      ];
}