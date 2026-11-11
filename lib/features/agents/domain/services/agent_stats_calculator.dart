import '../../../properties/domain/entities/property.dart';
import '../entities/agent_dashboard_stats.dart';

/// Pure dashboard computation (unit-tested).
///
/// Definitions (spec §14.2):
///  * a withdrawn listing (`removed`) is not counted anywhere;
///  * performance metrics are summed over the agent's listings only;
///  * views / favorites come from the trusted `property_stats` document, falling
///    back to the counters already on the property when that document is missing.
class AgentStatsCalculator {
  AgentStatsCalculator._();

  static AgentDashboardStats compute(
    List<Property> listings,
    Map<String, PropertyStats> stats,
  ) {
    var total = 0, published = 0, pending = 0, rejected = 0, drafts = 0, suspended = 0, expired = 0;
    var views = 0, favorites = 0, contacts = 0, shares = 0;

    for (final p in listings) {
      if (p.status == PropertyStatus.removed) continue;
      total++;
      switch (p.status) {
        case PropertyStatus.published:
          published++;
        case PropertyStatus.pendingReview:
          pending++;
        case PropertyStatus.rejected:
          rejected++;
        case PropertyStatus.draft:
          drafts++;
        case PropertyStatus.suspended:
          suspended++;
        case PropertyStatus.expired:
          expired++;
        case PropertyStatus.removed:
          break;
      }
      final s = stats[p.id];
      views += s?.views ?? p.views;
      favorites += s?.favorites ?? p.favoritesCount;
      contacts += s?.contacts ?? 0;
      shares += s?.shares ?? 0;
    }

    return AgentDashboardStats(
      totalListings: total,
      published: published,
      pending: pending,
      rejected: rejected,
      drafts: drafts,
      suspended: suspended,
      expired: expired,
      views: views,
      favorites: favorites,
      contacts: contacts,
      shares: shares,
    );
  }
}
