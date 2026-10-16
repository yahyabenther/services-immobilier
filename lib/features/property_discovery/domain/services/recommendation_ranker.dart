import 'dart:math' as math;

import '../../../properties/domain/entities/property.dart';

/// "Recent + verified + popular" ranking (implementation decision, spec §4.6).
///
///   score = 0.40 * recency + 0.30 * verified + 0.30 * popularity
///
/// - recency    : 0.5 ^ (ageDays / 14)   (halves every two weeks; 0.5 if undated)
/// - verified   : 1 if verificationStatus == verified, else 0
/// - popularity : log(1 + views + 5*favorites) normalised by the best value in the set
///
/// This is NOT personalisation: every user sees the same ranking.
class RecommendationRanker {
  const RecommendationRanker._();

  static const recencyWeight = 0.40;
  static const verifiedWeight = 0.30;
  static const popularityWeight = 0.30;
  static const recencyHalfLifeDays = 14.0;

  static double _rawPopularity(Property p) => math.log(1 + p.views + 5 * p.favoritesCount);

  static List<Property> rank(List<Property> candidates, {required DateTime now, required int limit}) {
    if (candidates.isEmpty) return const [];
    final maxPop = candidates.map(_rawPopularity).reduce(math.max);

    double score(Property p) {
      final published = p.publishedAt ?? p.createdAt;
      final recency = published == null
          ? 0.5
          : math.pow(0.5, math.max(0, now.difference(published).inHours) / 24 / recencyHalfLifeDays).toDouble();
      final popularity = maxPop == 0 ? 0.0 : _rawPopularity(p) / maxPop;
      return recencyWeight * recency +
          verifiedWeight * (p.isVerified ? 1 : 0) +
          popularityWeight * popularity;
    }

    final scored = [for (final p in candidates) (p: p, s: score(p))]
      ..sort((a, b) {
        final c = b.s.compareTo(a.s);
        if (c != 0) return c;
        // Stable tie-break: newest first, then id.
        final da = a.p.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.p.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final d = db.compareTo(da);
        return d != 0 ? d : a.p.id.compareTo(b.p.id);
      });
    return [for (final e in scored.take(limit)) e.p];
  }
}
