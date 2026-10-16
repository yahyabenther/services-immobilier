import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/discovery_failure.dart';
import 'package:team_app/core/theme/app_theme.dart';
import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/auth/providers/auth_provider.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/domain/entities/discovery_location.dart';
import 'package:team_app/features/property_discovery/domain/repositories/property_discovery_repository.dart';
import 'package:team_app/features/property_discovery/presentation/providers/property_discovery_providers.dart';
import 'package:team_app/features/property_discovery/presentation/screens/home_discovery_screen.dart';
import 'package:team_app/features/property_discovery/presentation/widgets/property_card.dart';

import 'support_properties.dart';

class FakeDiscoveryRepository implements PropertyDiscoveryRepository {
  Future<List<Property>> Function() recommended = () async => [];
  Future<List<Property>> Function() nearby = () async => [];

  @override
  Future<List<Property>> getRecommendedProperties({int limit = 10}) => recommended();

  @override
  Future<List<Property>> getNearbyProperties({required DiscoveryLocation location, int limit = 10}) => nearby();
}

Future<void> pumpHome(
  WidgetTester tester,
  FakeDiscoveryRepository repo, {
  AuthUser? user,
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(repo),
      currentUserProvider.overrideWithValue(user),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const HomeDiscoveryScreen()),
  ));
  await tester.pump(); // first frame (loading)
  await tester.pump(); // futures resolved
}

void main() {
  testWidgets('shows recommended cards; header works without a profile', (tester) async {
    final repo = FakeDiscoveryRepository()
      ..recommended = () async => [makeProperty(id: 'a', title: 'Villa A'), makeProperty(id: 'b', title: 'Flat B')];
    await pumpHome(tester, repo);

    expect(find.text('Hello 👋'), findsOneWidget); // generic greeting, no hardcoded name
    expect(find.text('Villa A'), findsOneWidget);
    expect(find.text('Flat B'), findsOneWidget);
    expect(find.byType(PropertyCard), findsNWidgets(2));
    // Nearby has no location -> asks for one instead of faking results.
    expect(find.text('Choose your area'), findsOneWidget);
  });

  testWidgets('greets by first name when the profile has one', (tester) async {
    await pumpHome(tester, FakeDiscoveryRepository(),
        user: const AuthUser(id: '1', email: 'y@x.co', name: 'Yahya Ben', emailVerified: true));
    expect(find.text('Hello, Yahya 👋'), findsOneWidget);
  });

  testWidgets('empty recommended state', (tester) async {
    await pumpHome(tester, FakeDiscoveryRepository());
    expect(find.text('No listings yet'), findsOneWidget);
    expect(find.byType(PropertyCard), findsNothing);
  });

  testWidgets('a failing section shows Retry and does not break the screen', (tester) async {
    var fail = true;
    final repo = FakeDiscoveryRepository()
      ..recommended = () async {
        if (fail) throw const DiscoveryFailure(DiscoveryFailureType.network);
        return [makeProperty(title: 'Recovered')];
      };
    await pumpHome(tester, repo);

    expect(find.text("Couldn't load this section"), findsOneWidget);
    expect(find.text('Explore on the map'), findsOneWidget); // rest of Home still there
    expect(find.text('Choose your area'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text("Couldn't load this section"), findsNothing);
  });

  testWidgets('Publish CTA follows UI permission state', (tester) async {
    await pumpHome(tester, FakeDiscoveryRepository(),
        user: const AuthUser(id: '1', email: 'a@b.co', role: UserRole.owner, emailVerified: true));
    expect(find.text('Have a property to sell or rent?'), findsOneWidget);
  });

  testWidgets('Publish CTA hidden for a plain user', (tester) async {
    await pumpHome(tester, FakeDiscoveryRepository(),
        user: const AuthUser(id: '1', email: 'a@b.co', emailVerified: true));
    expect(find.text('Have a property to sell or rent?'), findsNothing);
  });
}
