import '../../domain/usecases/get_current_location.dart';

/// All user-facing map strings in one place (easy to localise to French later).
class MapStrings {
  MapStrings._();

  static const loading = 'Loading properties…';
  static const searchArea = 'Search this area';
  static const emptyTitle = 'No properties found in this area';
  static const emptyMessage = 'Move the map or change your filters.';
  static const errorTitle = "We couldn't load properties for this area";
  static const noCoordsTitle = 'None of these results has a map location';
  static const noCoordsMessage = 'They are still available in the list.';

  static const explainTitle = 'Show listings near you?';
  static const explainBody =
      'ImmoFind uses your location only to center the map around you. It is not saved or shared, '
      'and you can keep exploring the map without it.';

  static String locationNotice(LocateOutcome o) => switch (o) {
        LocateOutcome.denied => 'Location permission was declined. You can still explore the map manually.',
        LocateOutcome.deniedForever =>
          'Location is blocked for ImmoFind. Enable it in system settings, or keep exploring manually.',
        LocateOutcome.serviceDisabled =>
          'Your location is unavailable. Turn on location services, or explore the map manually.',
        LocateOutcome.error => "Couldn't get your location. Try again, or explore the map manually.",
        LocateOutcome.located => '',
      };
}
