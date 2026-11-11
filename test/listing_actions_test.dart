import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/listings/domain/listing_actions.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';

void main() {
  group('ownerTransitions (Module 09)', () {
    test('a draft can only be submitted for review', () {
      expect(ownerTransitions(PropertyStatus.draft), {PropertyStatus.pendingReview});
    });

    test('a published listing can only be withdrawn', () {
      expect(ownerTransitions(PropertyStatus.published), {PropertyStatus.removed});
    });

    test('rejected and withdrawn listings go back to draft', () {
      expect(ownerTransitions(PropertyStatus.rejected), {PropertyStatus.draft});
      expect(ownerTransitions(PropertyStatus.removed), {PropertyStatus.draft});
    });

    test('pending, suspended and expired listings are locked for the owner', () {
      for (final s in [PropertyStatus.pendingReview, PropertyStatus.suspended, PropertyStatus.expired]) {
        expect(ownerTransitions(s), isEmpty, reason: s.name);
      }
    });

    test('an owner can never publish directly', () {
      for (final s in PropertyStatus.values) {
        expect(ownerTransitions(s), isNot(contains(PropertyStatus.published)), reason: s.name);
      }
    });
  });

  group('ownerCanDelete', () {
    test('only drafts, rejected and withdrawn listings can be deleted', () {
      expect(ownerCanDelete(PropertyStatus.draft), isTrue);
      expect(ownerCanDelete(PropertyStatus.rejected), isTrue);
      expect(ownerCanDelete(PropertyStatus.removed), isTrue);
      expect(ownerCanDelete(PropertyStatus.published), isFalse);
      expect(ownerCanDelete(PropertyStatus.pendingReview), isFalse);
      expect(ownerCanDelete(PropertyStatus.suspended), isFalse);
      expect(ownerCanDelete(PropertyStatus.expired), isFalse);
    });
  });

  test('every status has a tab in My Listings', () {
    expect(myListingsTabs.toSet(), PropertyStatus.values.toSet());
  });
}