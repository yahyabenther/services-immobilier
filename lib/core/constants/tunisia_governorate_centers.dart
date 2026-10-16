/// Approximate centre of each governorate. Used ONLY as a map camera hint
/// (e.g. Home selected "Sfax" -> the map opens around Sfax). Never stored on
/// listings and never used as a property coordinate.
typedef GeoCenter = ({double lat, double lng});

const Map<String, GeoCenter> tunisiaGovernorateCenters = {
  'Tunis': (lat: 36.8065, lng: 10.1815),
  'Ariana': (lat: 36.8625, lng: 10.1956),
  'Ben Arous': (lat: 36.7531, lng: 10.2189),
  'Manouba': (lat: 36.8101, lng: 10.0863),
  'Nabeul': (lat: 36.4561, lng: 10.7376),
  'Zaghouan': (lat: 36.4029, lng: 10.1429),
  'Bizerte': (lat: 37.2744, lng: 9.8739),
  'Béja': (lat: 36.7256, lng: 9.1817),
  'Jendouba': (lat: 36.5011, lng: 8.7802),
  'Le Kef': (lat: 36.1826, lng: 8.7148),
  'Siliana': (lat: 36.0850, lng: 9.3708),
  'Sousse': (lat: 35.8256, lng: 10.6369),
  'Monastir': (lat: 35.7643, lng: 10.8113),
  'Mahdia': (lat: 35.5047, lng: 11.0622),
  'Sfax': (lat: 34.7406, lng: 10.7603),
  'Kairouan': (lat: 35.6781, lng: 10.0963),
  'Kasserine': (lat: 35.1676, lng: 8.8365),
  'Sidi Bouzid': (lat: 35.0382, lng: 9.4849),
  'Gabès': (lat: 33.8815, lng: 10.0982),
  'Médenine': (lat: 33.3549, lng: 10.5055),
  'Tataouine': (lat: 32.9297, lng: 10.4518),
  'Gafsa': (lat: 34.4250, lng: 8.7842),
  'Tozeur': (lat: 33.9197, lng: 8.1335),
  'Kébili': (lat: 33.7048, lng: 8.9690),
};
