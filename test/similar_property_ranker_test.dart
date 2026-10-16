import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/properties/domain/services/similar_property_ranker.dart';

// NOTE: replace `immofind` with the `name:` in your pubspec.yaml.
Property p(
  String id, {
  TransactionType tx = TransactionType.buy,
  PropertyType type = PropertyType.apartment,
  PropertyStatus status = PropertyStatus.published,
  num price = 100000,
  VerificationStatus verification = VerificationStatus.notSubmitted,
}) =>
    Property(
      id: id,
      ownerId: 'o',
      title: id,
      transactionType: tx,
      propertyType: type,
      price: price,
      currency: 'TND',
      governorate: 'Tunis',
      status: status,
      verificationStatus: verification,
    );

void main() {
  test('excludes the current property, other transaction types and unpublished listings', () {
    final current = p('a');
    final result = SimilarPropertyRanker.rank(current, [
      p('a'),
      p('rent', tx: TransactionType.rent),
      p('draft', status: PropertyStatus.draft),
      p('ok'),
    ]);
    expect(result.map((e) => e.id), ['ok']);
  });

  test('same type and similar price rank first', () {
    final current = p('a');
    final result = SimilarPropertyRanker.rank(current, [
      p('far', type: PropertyType.villa, price: 900000),
      p('near'),
    ]);
    expect(result.first.id, 'near');
  });

  test('only an approved verification counts as verified', () {
    expect(p('x', verification: VerificationStatus.approved).isVerified, isTrue);
    expect(p('x', verification: VerificationStatus.pending).isVerified, isFalse);
    expect(p('x', verification: VerificationStatus.rejected).isVerified, isFalse);
  });
}
