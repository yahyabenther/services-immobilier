import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/presentation/widgets/property_card.dart';

import 'support_properties.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('shows price, title, location and facts; placeholder when no image', (tester) async {
    await tester.pumpWidget(host(PropertyCard(property: makeProperty(), onTap: () {})));
    expect(find.text('850,000 TND'), findsOneWidget);
    expect(find.text('Modern Villa'), findsOneWidget);
    expect(find.text('La Marsa, Tunis'), findsOneWidget);
    expect(find.text('350 m²'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.byIcon(Icons.home_work_outlined), findsOneWidget); // placeholder
  });

  testWidgets('missing facts are omitted, never shown as 0', (tester) async {
    final p = makeProperty(bedrooms: null, bathrooms: null, surface: null, verification: VerificationStatus.notSubmitted);
    await tester.pumpWidget(host(PropertyCard(property: p, onTap: () {})));
    expect(find.byIcon(Icons.bed_outlined), findsNothing);
    expect(find.byIcon(Icons.square_foot_rounded), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('Verified'), findsNothing); // badge only when verified by data
  });

  testWidgets('rent shows per-month price; tap fires callback', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(host(PropertyCard(
      property: makeProperty(tx: TransactionType.rent, price: 1200),
      onTap: () => tapped++,
    )));
    expect(find.text('1,200 TND / month'), findsOneWidget);
    expect(find.text('For rent'), findsOneWidget);
    await tester.tap(find.byType(InkWell).first);
    expect(tapped, 1);
  });

  testWidgets('favorite control has a semantic label', (tester) async {
    await tester.pumpWidget(host(PropertyCard(property: makeProperty(), onTap: () {}, onFavoriteTap: () {})));
    expect(find.bySemanticsLabel('Add to favorites'), findsOneWidget);
  });
}
