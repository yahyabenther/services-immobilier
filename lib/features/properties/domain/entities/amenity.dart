/// Canonical amenity identifiers. The enum NAME is what is stored in Firestore
/// (`amenities: ["pool", "seaView"]`) and what search filters on, so publishing
/// (Module 08), search (Module 04) and details (Module 05) all agree.
enum Amenity {
  parking('Parking'),
  pool('Pool'),
  elevator('Elevator'),
  garden('Garden'),
  seaView('Sea view'),
  centralHeating('Central heating'),
  airConditioning('Air conditioning'),
  security('Security'),
  terrace('Terrace'),
  balcony('Balcony');

  const Amenity(this.label);

  final String label;

  /// Value stored in Firestore.
  String get id => name;

  static Amenity? tryParse(String? v) {
    for (final a in Amenity.values) {
      if (a.name == v) return a;
    }
    return null;
  }
}
