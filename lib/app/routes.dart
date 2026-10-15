import '../features/properties/domain/entities/property.dart';
import '../features/property_discovery/domain/entities/discovery_location.dart';

class Routes {
  Routes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
  static const accountStatus = '/account-status';

  // Bottom-navigation tabs
  static const home = '/home';
  static const search = '/search'; // Module 04
  static const map = '/map'; // Module 06
  static const favorites = '/favorites'; // Module 07
  static const profile = '/profile'; // Module 02

  static const publish = '/publish'; // Module 08
  static const adminDashboard = '/admin/dashboard';

  /// go_router pattern for Module 05. Build real links with [propertyDetails].
  static const propertyDetailsPattern = '/property/:id';

  /// Reachable while signed out.
  static const publicRoutes = {welcome, login, register, forgotPassword};

  /// Module 05 — stable id in the route, never the whole object.
  static String propertyDetails(String id) => '/property/${Uri.encodeComponent(id)}';

  /// Module 04 entry. Buy/Rent pass `transactionType` so the filter model (not
  /// just a visual tab) starts with the right value.
  static String searchWith({TransactionType? transactionType, String? section, DiscoveryLocation? location}) =>
      _build(search, {
        if (transactionType != null) 'transactionType': transactionType.name,
        if (section != null) 'section': section,
        ..._locationParams(location),
      });

  /// Module 06 entry with usable location context when we have it.
  static String mapWith({DiscoveryLocation? location}) => _build(map, _locationParams(location));

  static Map<String, String> _locationParams(DiscoveryLocation? l) => {
        if (l?.governorate != null) 'governorate': l!.governorate!,
        if (l != null && l.hasCoordinates) ...{'lat': '${l.latitude}', 'lng': '${l.longitude}'},
      };

  static String _build(String path, Map<String, String> q) =>
      Uri(path: path, queryParameters: q.isEmpty ? null : q).toString();
}
