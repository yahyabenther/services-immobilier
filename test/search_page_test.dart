import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/core/errors/discovery_failure.dart';
import 'package:team_app/core/theme/app_theme.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/presentation/providers/property_discovery_providers.dart';
import 'package:team_app/features/property_discovery/presentation/widgets/property_card.dart';
import 'package:team_app/features/search/domain/entities/property_search_filter.dart';
import 'package:team_app/features/search/domain/entities/search_enums.dart';
import 'package:team_app/features/search/presentation/pages/search_page.dart';
import 'package:team_app/features/search/providers/search_providers.dart';

import 'fake_search_repository.dart';
import 'support_properties.dart';

Future<ProviderContainer> pumpSearch(WidgetTester tester, FakeSearchRepository repo) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    searchRepositoryProvider.overrideWithValue(repo),
    locationServiceProvider.overrideWithValue(FakeLocationService()),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light, home: const SearchPage()),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows the default feed with a count', (tester) async {
    final repo = FakeSearchRepository((_, _) async => pageOf([
          makeProperty(id: 'a', title: 'Villa A'),
          makeProperty(id: 'b', title: 'Flat B'),
        ]));
    await pumpSearch(tester, repo);

    expect(find.text('Villa A'), findsOneWidget);
    expect(find.text('Flat B'), findsOneWidget);
    expect(find.byType(PropertyCard), findsNWidgets(2));
    expect(find.text('2 properties'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget); // current sort label
  });

  testWidgets('tabs filter for real; empty state offers Clear filters', (tester) async {
    final repo = FakeSearchRepository((f, _) async {
      if (f.transactionType == TransactionType.rent) return pageOf(const []);
      return pageOf([makeProperty(id: 'a', title: 'Villa A')]);
    });
    await pumpSearch(tester, repo);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Rent'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.filter.transactionType, TransactionType.rent);
    expect(find.text('No properties match your search'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Villa A'), findsOneWidget);
    expect(repo.calls.last.filter.transactionType, isNull);
  });

  testWidgets('error state keeps the filters and Retry recovers', (tester) async {
    var fail = true;
    final repo = FakeSearchRepository((_, _) async {
      if (fail) throw const DiscoveryFailure(DiscoveryFailureType.network);
      return pageOf([makeProperty(title: 'Back again')]);
    });
    final c = await pumpSearch(tester, repo);

    expect(find.text("The search couldn't be loaded"), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Back again'), findsOneWidget);
    expect(c.read(searchResultsProvider).status.name, 'success');
  });

  testWidgets('filter sheet validates min/max price and blocks Apply', (tester) async {
    final repo = FakeSearchRepository((_, _) async => pageOf([makeProperty()]));
    await pumpSearch(tester, repo);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Apply filters'), findsOneWidget);

    final minField = find.widgetWithText(TextField, 'Min').first;
    final maxField = find.widgetWithText(TextField, 'Max').first;
    await tester.enterText(minField, '500000');
    await tester.enterText(maxField, '100000');
    await tester.pump();

    expect(find.text('Minimum price must not exceed maximum'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply filters')).onPressed, isNull);

    await tester.enterText(maxField, '900000');
    await tester.pump();
    expect(find.text('Minimum price must not exceed maximum'), findsNothing);

    final before = repo.calls.length;
    await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
    await tester.pumpAndSettle();
    expect(repo.calls.length, before + 1);
    expect(repo.calls.last.filter.minPrice, 500000);
    expect(repo.calls.last.filter.maxPrice, 900000);
    expect(find.text('500 000 – 900 000 TND'), findsOneWidget); // active chip
  });

  testWidgets('filters can be deselected and removed from the chips', (tester) async {
    final repo = FakeSearchRepository((_, _) async => pageOf([makeProperty()]));
    final c = await pumpSearch(tester, repo);

    await c.read(searchResultsProvider.notifier).applyFilter(
          const PropertySearchFilter().copyWith(propertyType: PropertyType.villa),
        );
    await tester.pumpAndSettle();
    expect(find.text('Villa'), findsOneWidget); // chip label

    await tester.tap(find.byTooltip('Remove filter'));
    await tester.pumpAndSettle();
    expect(c.read(searchResultsProvider).filter.propertyType, isNull);
    expect(find.byTooltip('Remove filter'), findsNothing);
  });

  testWidgets('sort sheet changes the sort', (tester) async {
    final repo = FakeSearchRepository((_, _) async => pageOf([makeProperty()]));
    await pumpSearch(tester, repo);

    await tester.tap(find.text('Recommended'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lowest price'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.filter.sort, SortOption.lowestPrice);
  });

  testWidgets('map toggle shows the map placeholder and goes back to the same list', (tester) async {
    final repo = FakeSearchRepository((_, _) async => pageOf([makeProperty(title: 'Villa A')]));
    await pumpSearch(tester, repo);
    final callsBefore = repo.calls.length;

    await tester.tap(find.byTooltip('Map'));
    await tester.pumpAndSettle();
    expect(find.text('The map view is coming soon'), findsOneWidget);

    await tester.tap(find.text('Back to list'));
    await tester.pumpAndSettle();
    expect(find.text('Villa A'), findsOneWidget);
    expect(repo.calls.length, callsBefore); // switching views never re-queries
  });
}
