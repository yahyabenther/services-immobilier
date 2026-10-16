import '../../core/config/env.dart';

/// Map provider configuration (Module 06). Tile URL and user agent come from `.env`.
///
/// Default: OpenStreetMap raster tiles through `flutter_map` — no API key, works on
/// Android / iOS / web. The public OSM tile server is meant for light use (dev, demos,
/// small apps). Before a large launch, switch [mapTileUrlTemplate] to a commercial tile
/// provider (MapTiler, Mapbox, Stadia, ...) — nothing else in the module changes.
String get mapTileUrlTemplate => Env.mapTileUrl; // MAP_TILE_URL in .env

/// Sent as User-Agent so the tile server can identify the app (OSM policy).
String get mapUserAgentPackageName => Env.mapUserAgentPackage; // MAP_USER_AGENT_PACKAGE in .env

const mapAttribution = '© OpenStreetMap contributors';

/// Max listings drawn for one viewport (spec §8.6: never load the whole collection).
const mapPropertyLimit = 150;

const mapMinZoom = 5.0;
const mapMaxZoom = 19.0;
