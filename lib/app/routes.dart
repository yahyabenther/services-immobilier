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

  // ---- Module 10: Agent / Agency (all require a signed-in user) -------------
  static const agentDashboard = '/agent';
  static const agentSetup = '/agent/setup';
  static const agentProfile = '/agent/profile';
  static const agentProfileEdit = '/agent/profile/edit';
  static const agentListings = '/agent/listings';
  static const agentInquiries = '/agent/inquiries';
  static const agentStatistics = '/agent/statistics';
  static const agentVerification = '/agent/verification';
  static const agentListingPattern = '/agent/listings/:propertyId';

  /// Public professional profile. Exposes public fields only.
  static const agentPublicPattern = '/agents/:agentId';

  /// Shared messaging base (Module 09 extends it).
  static const chatPattern = '/chat/:conversationId';

  /// go_router pattern for Module 05. Build real links with [propertyDetails].
  static const propertyDetailsPattern = '/property/:id';

  /// Reachable while signed out.
  static const publicRoutes = {welcome, login, register, forgotPassword};

  static String agentListing(String propertyId) => '/agent/listings/${Uri.encodeComponent(propertyId)}';
  static String agentPublic(String agentId) => '/agents/${Uri.encodeComponent(agentId)}';
  static String chat(String conversationId) => '/chat/${Uri.encodeComponent(conversationId)}';

  /// Module 08 entry: publish a new property, or edit one (`edit=<propertyId>`).
  static String publishWith({String? editPropertyId}) =>
      _build(publish, {if (editPropertyId != null) 'edit': editPropertyId});

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

  /// Module 04 -> 06: open the full map with the filter currently applied in Search.
  /// `t` makes every call a new location so the map re-reads the Search filter.
  static String mapFromSearch() =>
      _build(map, {'source': 'search', 't': '${DateTime.now().millisecondsSinceEpoch}'});

  static Map<String, String> _locationParams(DiscoveryLocation? l) => {
        if (l?.governorate != null) 'governorate': l!.governorate!,
        if (l != null && l.hasCoordinates) ...{'lat': '${l.latitude}', 'lng': '${l.longitude}'},
      };

  static String _build(String path, Map<String, String> q) =>
      Uri(path: path, queryParameters: q.isEmpty ? null : q).toString();
}
