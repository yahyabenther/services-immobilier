import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/features/agents/domain/entities/agent_dashboard_stats.dart';
import 'package:team_app/features/agents/domain/entities/agent_profile.dart';
import 'package:team_app/features/agents/domain/entities/verification_request.dart';
import 'package:team_app/features/agents/domain/services/agent_profile_validator.dart';
import 'package:team_app/features/agents/domain/services/agent_stats_calculator.dart';
import 'package:team_app/features/agents/domain/services/listing_policy.dart';
import 'package:team_app/features/agents/domain/services/profile_completion.dart';
import 'package:team_app/features/messaging/domain/conversation.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';

// NOTE: replace `team_app` with the package name in your pubspec.yaml.

Property prop(String id, PropertyStatus s, {int views = 0, int fav = 0, num price = 100, num? surface = 50, List<String> images = const ['a']}) =>
    Property(
      id: id, ownerId: 'o', agentId: 'a', title: 'T', description: 'D',
      transactionType: TransactionType.buy, propertyType: PropertyType.apartment,
      price: price, currency: 'TND', governorate: 'Tunis', status: s,
      verificationStatus: VerificationStatus.notSubmitted, views: views, favoritesCount: fav,
      surface: surface, images: images,
    );

AgentProfile profile({String name = 'Ali Ben', String desc = 'Real estate services in Tunis area.', String phone = '+21620123456', String email = 'a@b.tn', String city = 'Tunis', AgentProfileKind kind = AgentProfileKind.agent, String? agency, String? website}) =>
    AgentProfile(userId: 'u', professionalName: name, description: desc, phone: phone, publicEmail: email, city: city, kind: kind, agencyName: agency, website: website);

void main() {
  group('AgentProfileValidator', () {
    test('valid profile has no errors', () => expect(AgentProfileValidator.validate(profile()), isEmpty));
    test('rejects bad phone, email, city, short description', () {
      final e = AgentProfileValidator.validate(profile(phone: '123', email: 'x', city: 'Paris', desc: 'short'));
      expect(e.keys, containsAll(['phone', 'publicEmail', 'city', 'description']));
    });
    test('agency name required only for agencies', () {
      expect(AgentProfileValidator.validate(profile(kind: AgentProfileKind.agency)).containsKey('agencyName'), isTrue);
      expect(AgentProfileValidator.validate(profile(kind: AgentProfileKind.agency, agency: 'Immo')).isEmpty, isTrue);
    });
    test('website must be http(s)', () {
      expect(AgentProfileValidator.website('javascript:alert(1)'), isNotNull);
      expect(AgentProfileValidator.website('https://immo.tn'), isNull);
      expect(AgentProfileValidator.website(''), isNull);
    });
    test('image rules', () {
      expect(AgentProfileValidator.image(fileName: 'a.gif', bytes: 10), isNotNull);
      expect(AgentProfileValidator.image(fileName: 'a.jpg', bytes: 3 * 1024 * 1024), isNotNull);
      expect(AgentProfileValidator.image(fileName: 'a.JPG', bytes: 1000), isNull);
    });
  });

  group('AgentStatsCalculator', () {
    test('counts by status, ignores removed, prefers trusted stats', () {
      final s = AgentStatsCalculator.compute([
        prop('1', PropertyStatus.published, views: 5, fav: 1),
        prop('2', PropertyStatus.pendingReview),
        prop('3', PropertyStatus.rejected),
        prop('4', PropertyStatus.removed, views: 99),
      ], {'1': const PropertyStats(propertyId: '1', views: 40, favorites: 3, contacts: 2)});
      expect(s.totalListings, 3);
      expect(s.published, 1);
      expect(s.pending, 1);
      expect(s.rejected, 1);
      expect(s.views, 40);
      expect(s.favorites, 3);
      expect(s.contacts, 2);
      expect(s.hasActivity, isTrue);
    });
    test('empty -> no listings, no activity', () {
      final s = AgentStatsCalculator.compute([], {});
      expect(s.hasListings, isFalse);
      expect(s.hasActivity, isFalse);
    });
  });

  group('ListingPolicy', () {
    test('rejected can be edited and resubmitted, not viewed publicly', () {
      expect(ListingPolicy.canEdit(PropertyStatus.rejected), isTrue);
      expect(ListingPolicy.canSubmit(PropertyStatus.rejected), isTrue);
      expect(ListingPolicy.canViewPublic(PropertyStatus.rejected), isFalse);
    });
    test('suspended cannot be changed by the agent', () {
      expect(ListingPolicy.canEdit(PropertyStatus.suspended), isFalse);
      expect(ListingPolicy.canSubmit(PropertyStatus.suspended), isFalse);
      expect(ListingPolicy.canWithdraw(PropertyStatus.suspended), isFalse);
    });
    test('published can be withdrawn but not resubmitted', () {
      expect(ListingPolicy.canWithdraw(PropertyStatus.published), isTrue);
      expect(ListingPolicy.canSubmit(PropertyStatus.published), isFalse);
    });
    test('submission check mirrors Module 08 validation', () {
      expect(ListingSubmissionCheck.problems(prop('1', PropertyStatus.draft)), isEmpty);
      expect(ListingSubmissionCheck.problems(prop('1', PropertyStatus.draft, price: 0, surface: 0, images: const [])).length, 3);
    });
  });

  group('Verification state machine', () {
    test('submit allowed only from not_submitted / rejected / expired', () {
      expect(canSubmitVerification(VerificationStatus.notSubmitted), isTrue);
      expect(canSubmitVerification(VerificationStatus.rejected), isTrue);
      expect(canSubmitVerification(VerificationStatus.expired), isTrue);
      expect(canSubmitVerification(VerificationStatus.pending), isFalse);
      expect(canSubmitVerification(VerificationStatus.approved), isFalse);
    });
    test('pending request wins over stale profile mirror', () {
      const r = VerificationRequest(id: 'v', targetId: 'u', status: VerificationStatus.pending);
      expect(effectiveVerificationStatus(VerificationStatus.notSubmitted, r), VerificationStatus.pending);
    });
    test('agency requires the extra category', () {
      expect(AgentVerificationPolicy.requiredFor(isAgency: true), contains(VerificationCategory.agency));
      expect(AgentVerificationPolicy.requiredFor(isAgency: false), isNot(contains(VerificationCategory.agency)));
    });
  });

  group('ProfileCompletion', () {
    test('required-only profile is incomplete, full profile is 100%', () {
      expect(ProfileCompletion.of(profile()).percent, 60);
      final full = profile().copyWith(profileImageUrl: 'x', address: 'y', website: 'https://a.tn', yearsOfExperience: 3, languages: ['French'], serviceAreas: ['Tunis']);
      expect(ProfileCompletion.of(full).percent, 100);
    });
  });

  group('Conversation unread', () {
    final t = DateTime(2026, 11, 9, 12);
    Conversation c({String? sender, DateTime? read}) => Conversation(
          id: 'p_u', participants: const ['u', 'a'], userId: 'u', recipientId: 'a', propertyId: 'p',
          lastMessage: 'hi', lastMessageAt: t, lastSenderId: sender, lastReadAt: read == null ? const {} : {'a': read});
    test('unread for recipient until read', () {
      expect(c(sender: 'u').isUnreadFor('a'), isTrue);
      expect(c(sender: 'u', read: t.add(const Duration(minutes: 1))).isUnreadFor('a'), isFalse);
    });
    test('own message is never unread', () => expect(c(sender: 'a').isUnreadFor('a'), isFalse));
  });
}
