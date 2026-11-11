import '../../properties/domain/entities/property.dart';

/// Status changes an OWNER may make (spec §20). Approve / reject / suspend
/// belong to the admin. Firestore rules enforce the same list.
Set<PropertyStatus> ownerTransitions(PropertyStatus s) => switch (s) {
      PropertyStatus.draft => {PropertyStatus.pendingReview}, // Submit
      PropertyStatus.published => {PropertyStatus.removed}, // Withdraw
      PropertyStatus.rejected || PropertyStatus.removed => {PropertyStatus.draft}, // Back to draft
      _ => const {},
    };

/// A listing can be deleted only when it is not live or under review.
bool ownerCanDelete(PropertyStatus s) =>
    s == PropertyStatus.draft || s == PropertyStatus.rejected || s == PropertyStatus.removed;

/// Tabs of the My Listings page, in display order.
const myListingsTabs = [
  PropertyStatus.draft,
  PropertyStatus.pendingReview,
  PropertyStatus.published,
  PropertyStatus.rejected,
  PropertyStatus.suspended,
  PropertyStatus.expired,
];