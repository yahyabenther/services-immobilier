/// Trusted aggregate counters of one listing: `property_stats/{propertyId}`.
/// Only backend code writes them (spec §6.7, FR-06).
class PropertyStats {
  const PropertyStats({
    required this.propertyId,
    this.views = 0,
    this.favorites = 0,
    this.contacts = 0,
    this.shares = 0,
  });

  final String propertyId;
  final int views;
  final int favorites;
  final int contacts;
  final int shares;
}

/// Dashboard numbers. Always computed from real data (never hard-coded, spec §14.3).
class AgentDashboardStats {
  const AgentDashboardStats({
    this.totalListings = 0,
    this.published = 0,
    this.pending = 0,
    this.rejected = 0,
    this.drafts = 0,
    this.suspended = 0,
    this.expired = 0,
    this.views = 0,
    this.favorites = 0,
    this.contacts = 0,
    this.shares = 0,
  });

  /// Every listing except withdrawn (`removed`) ones.
  final int totalListings;
  final int published;
  final int pending;
  final int rejected;
  final int drafts;
  final int suspended;
  final int expired;
  final int views;
  final int favorites;
  final int contacts;
  final int shares;

  bool get hasListings => totalListings > 0;

  /// False while nothing has been recorded yet -> the "No statistics" empty state.
  bool get hasActivity => views + favorites + contacts + shares > 0;

  static const empty = AgentDashboardStats();
}
