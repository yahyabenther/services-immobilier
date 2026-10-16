import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/domain/services/recommendation_ranker.dart';

import 'support_properties.dart';

void main() {
  final now = DateTime(2026, 10, 10);

  test('empty input -> empty output', () {
    expect(RecommendationRanker.rank(const [], now: now, limit: 5), isEmpty);
  });

  test('verified beats unverified when everything else is equal', () {
    final a = makeProperty(id: 'a', verification: VerificationStatus.notSubmitted, publishedAt: now);
    final b = makeProperty(id: 'b', verification: VerificationStatus.approved, publishedAt: now);
    final r = RecommendationRanker.rank([a, b], now: now, limit: 2);
    expect(r.first.id, 'b');
  });

  test('newer beats older when everything else is equal', () {
    final old = makeProperty(id: 'old', publishedAt: now.subtract(const Duration(days: 40)));
    final fresh = makeProperty(id: 'fresh', publishedAt: now.subtract(const Duration(days: 1)));
    expect(RecommendationRanker.rank([old, fresh], now: now, limit: 2).first.id, 'fresh');
  });

  test('more popular beats less popular when everything else is equal', () {
    final quiet = makeProperty(id: 'quiet', publishedAt: now, views: 1);
    final hot = makeProperty(id: 'hot', publishedAt: now, views: 500, favorites: 30);
    expect(RecommendationRanker.rank([quiet, hot], now: now, limit: 2).first.id, 'hot');
  });

  test('respects the limit and is deterministic', () {
    final list = [for (var i = 0; i < 8; i++) makeProperty(id: 'p$i', publishedAt: now)];
    final r1 = RecommendationRanker.rank(list, now: now, limit: 3);
    final r2 = RecommendationRanker.rank(list.reversed.toList(), now: now, limit: 3);
    expect(r1.length, 3);
    expect(r1.map((p) => p.id), r2.map((p) => p.id));
  });
}
