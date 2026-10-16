import 'package:flutter_test/flutter_test.dart';
import 'package:team_app/app/routes.dart';
import 'package:team_app/core/utils/geo.dart';
import 'package:team_app/core/utils/price_formatter.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/property_discovery/domain/entities/discovery_location.dart';

void main() {
  group('geo', () {
    test('haversine: Tunis -> Sousse is about 110-120 km', () {
      final d = distanceKm(36.8065, 10.1815, 35.8256, 10.6084);
      expect(d, inInclusiveRange(110, 120));
    });
    test('same point is 0', () => expect(distanceKm(36, 10, 36, 10), closeTo(0, 1e-9)));
    test('bounding box contains points inside the radius', () {
      final b = boundingBox(36.8, 10.2, 10);
      // ~5 km north / east must be inside
      expect(36.845 >= b.minLat && 36.845 <= b.maxLat, isTrue);
      expect(10.25 >= b.minLng && 10.25 <= b.maxLng, isTrue);
    });
  });

  group('price', () {
    test('sale', () => expect(PriceFormatter.format(850000, 'TND', TransactionType.buy), '850,000 TND'));
    test('rent', () => expect(PriceFormatter.format(1200, 'TND', TransactionType.rent), '1,200 TND / month'));
    test('small', () => expect(PriceFormatter.format(900, 'TND', TransactionType.buy), '900 TND'));
  });

  group('routes', () {
    test('Buy/Rent put the transaction type in the route', () {
      expect(Routes.searchWith(transactionType: TransactionType.buy), '/search?transactionType=buy');
      expect(Routes.searchWith(transactionType: TransactionType.rent), '/search?transactionType=rent');
    });
    test('location context is preserved', () {
      expect(Routes.searchWith(location: const DiscoveryLocation.governorate('Sousse')), '/search?governorate=Sousse');
      final u = Uri.parse(Routes.mapWith(location: const DiscoveryLocation.device(latitude: 36.8, longitude: 10.2)));
      expect(u.path, '/map');
      expect(u.queryParameters['lat'], '36.8');
      expect(u.queryParameters['lng'], '10.2');
    });
    test('See all carries the section', () {
      expect(Routes.searchWith(section: 'recommended'), '/search?section=recommended');
    });
    test('details route uses the property id', () => expect(Routes.propertyDetails('abc123'), '/property/abc123'));
    test('no params -> bare path', () => expect(Routes.searchWith(), '/search'));
  });
}
