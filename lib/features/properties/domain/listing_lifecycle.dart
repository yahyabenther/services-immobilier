import 'entities/property.dart';

/// What the owner/agent of a listing may do, by current status.
/// MUST mirror `lifecycleMove()` in firestore.rules: change them together.
const Map<PropertyStatus, Set<PropertyStatus>> ownerLifecycle = {
  PropertyStatus.draft: {PropertyStatus.pendingReview, PropertyStatus.removed},
  PropertyStatus.pendingReview: {PropertyStatus.removed},
  PropertyStatus.published: {PropertyStatus.removed},
  PropertyStatus.rejected: {
    PropertyStatus.draft,
    PropertyStatus.pendingReview,
    PropertyStatus.removed,
  },
  PropertyStatus.removed: {PropertyStatus.draft},
  PropertyStatus.expired: {PropertyStatus.removed},
  // suspended: moderation hold, no owner action.
};

bool canMove(PropertyStatus from, PropertyStatus to) =>
    ownerLifecycle[from]?.contains(to) ?? false;