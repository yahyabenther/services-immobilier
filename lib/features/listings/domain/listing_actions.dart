import '../../properties/domain/entities/property.dart';
import '../../properties/domain/listing_lifecycle.dart';

/// Status changes an OWNER may make (spec §20). Approve / reject / suspend
/// belong to the admin. Backed by [ownerLifecycle], which mirrors the Firestore
/// rule `lifecycleMove()`.
Set<PropertyStatus> ownerTransitions(PropertyStatus s) => ownerLifecycle[s] ?? const {};

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
  PropertyStatus.removed,
  PropertyStatus.expired,
];