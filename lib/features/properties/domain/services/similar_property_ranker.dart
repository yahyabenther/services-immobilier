import '../entities/property.dart';

/// Picks "similar properties" for the details page (Module 05).
///
/// Candidates must be published, NOT the current property, and have the same
/// transaction type (a rental is not similar to a sale). They are ranked by:
///   +3 same property type, +2 price within ±30 %, +1 same city, then newest first.
class SimilarPropertyRanker {
  const SimilarPropertyRanker._();

  static List<Property> rank(Property current, List<Property> candidates, {int limit = 6}) {
    int score(Property p) {
      var s = 0;
      if (p.propertyType == current.propertyType) s += 3;
      if (current.price > 0 && (p.price - current.price).abs() <= current.price * 0.3) s += 2;
      final c = current.city?.toLowerCase();
      if (c != null && p.city?.toLowerCase() == c) s += 1;
      return s;
    }

    final eligible = candidates
        .where((p) => p.id != current.id && p.isPublic && p.transactionType == current.transactionType)
        .toList();
    eligible.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      final da = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byDate = db.compareTo(da);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return eligible.take(limit).toList();
  }
}
