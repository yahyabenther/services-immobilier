import 'package:cloud_firestore/cloud_firestore.dart';

/// DEVELOPMENT ONLY. Writes clearly-marked sample listings (`isSample: true`) so Home and
/// Search have data while Module 08 (publishing + Cloudinary upload) does not exist.
/// Needs an admin account (the Firestore rules only let admins write).
/// Reachable only from the debug buttons on the admin placeholder (kDebugMode).
/// Delete this file (and the two buttons) before release.
///
/// Images are Cloudinary's public demo-cloud samples, only to exercise the image
/// pipeline. Real listings will store the `secure_url`s of YOUR Cloudinary uploads.
class PropertySeeder {
  PropertySeeder(this._db);
  final FirebaseFirestore _db;

  static const _owner = 'sample-owner';
  static const _demo = 'https://res.cloudinary.com/demo/image/upload';
  static const _photos = [
    '$_demo/sample.jpg',
    '$_demo/cld-sample.jpg',
    '$_demo/cld-sample-2.jpg',
    '$_demo/cld-sample-3.jpg',
    '$_demo/cld-sample-4.jpg',
    '$_demo/cld-sample-5.jpg',
  ];

  Future<int> seed() async {
    final now = DateTime.now();
    Timestamp ago(int days) => Timestamp.fromDate(now.subtract(Duration(days: days)));
    var photoIndex = 0;

    Map<String, dynamic> doc({
      required String title,
      required String tx,
      required String type,
      required num price,
      required String governorate,
      required String city,
      String? area,
      required double lat,
      required double lng,
      num? surface,
      int? beds,
      int? baths,
      bool studio = false,
      bool newBuild = false,
      String status = 'published',
      String verification = 'approved',
      int days = 1,
      int views = 0,
      int favs = 0,
      List<String> amenities = const [],
      bool photos = true,
    }) {
      final imgs = photos
          ? [_photos[photoIndex % _photos.length], _photos[(photoIndex + 1) % _photos.length]]
          : <String>[];
      photoIndex++;
      return {
        'ownerId': _owner,
        'title': title,
        'description': 'Sample listing for development.',
        'transactionType': tx,
        'propertyType': type,
        'price': price,
        'currency': 'TND',
        'surface': ?surface,
        'bedrooms': ?beds,
        'bathrooms': ?baths,
        'isStudio': studio,
        'isNewBuild': newBuild,
        'governorate': governorate,
        'city': city,
        'area': ?area,
        'latitude': lat,
        'longitude': lng,
        'images': imgs,
        'amenities': amenities,
        'status': status,
        'verificationStatus': verification,
        'views': views,
        'favoritesCount': favs,
        'createdAt': ago(days),
        'updatedAt': ago(days),
        'publishedAt': ago(days),
        'isSample': true,
      };
    }

    final docs = <Map<String, dynamic>>[
      doc(title: 'Modern Villa with Pool', tx: 'buy', type: 'villa', price: 850000, governorate: 'Tunis', city: 'La Marsa', area: 'Gammarth', lat: 36.9167, lng: 10.2833, surface: 350, beds: 4, baths: 3, days: 2, views: 320, favs: 24, amenities: ['pool', 'garden', 'parking', 'security']),
      doc(title: 'Apartment with Sea View', tx: 'buy', type: 'apartment', price: 620000, governorate: 'Tunis', city: 'La Marsa', area: 'Sidi Bou Said', lat: 36.8700, lng: 10.3416, surface: 180, beds: 3, baths: 2, days: 5, views: 210, favs: 15, amenities: ['seaView', 'elevator', 'balcony']),
      doc(title: 'Modern Apartment', tx: 'rent', type: 'apartment', price: 2800, governorate: 'Tunis', city: 'Tunis', area: 'Les Berges du Lac', lat: 36.8330, lng: 10.2290, surface: 160, beds: 3, baths: 2, days: 1, views: 90, favs: 6, amenities: ['elevator', 'airConditioning', 'parking']),
      doc(title: 'Cozy Studio', tx: 'rent', type: 'apartment', price: 900, governorate: 'Tunis', city: 'Tunis', area: 'El Menzah', lat: 36.8420, lng: 10.1820, surface: 38, studio: true, baths: 1, days: 9, views: 40, favs: 2, verification: 'not_submitted', amenities: ['airConditioning']),
      doc(title: 'Villa with Garden', tx: 'buy', type: 'villa', price: 1200000, governorate: 'Tunis', city: 'Carthage', lat: 36.8528, lng: 10.3233, surface: 450, beds: 5, baths: 4, days: 12, views: 500, favs: 40, amenities: ['garden', 'parking', 'terrace', 'centralHeating']),
      doc(title: 'Traditional House', tx: 'buy', type: 'house', price: 480000, governorate: 'Sousse', city: 'Sousse', area: 'Sahloul', lat: 35.8256, lng: 10.6084, surface: 200, beds: 4, baths: 2, days: 20, views: 120, favs: 8, verification: 'pending', amenities: ['terrace']),
      doc(title: 'Beachfront Apartment', tx: 'rent', type: 'apartment', price: 1800, governorate: 'Nabeul', city: 'Hammamet', lat: 36.4000, lng: 10.6167, surface: 110, beds: 2, baths: 1, days: 3, views: 75, favs: 5, amenities: ['seaView', 'balcony', 'airConditioning']),
      doc(title: 'Building Land near the Coast', tx: 'buy', type: 'land', price: 300000, governorate: 'Sfax', city: 'Sfax', area: 'Route de Gabès', lat: 34.7406, lng: 10.7603, surface: 800, days: 7, views: 30, favs: 1, verification: 'not_submitted'),
      doc(title: 'New Duplex, Ready to Move In', tx: 'buy', type: 'duplex', price: 540000, governorate: 'Ariana', city: 'Ariana', area: 'Ennasr', lat: 36.8625, lng: 10.1956, surface: 210, beds: 4, baths: 3, newBuild: true, days: 4, views: 140, favs: 11, amenities: ['parking', 'elevator', 'terrace']),
      doc(title: 'New Residence Apartment S+2', tx: 'buy', type: 'apartment', price: 330000, governorate: 'Ben Arous', city: 'Mourouj', lat: 36.7300, lng: 10.2100, surface: 105, beds: 2, baths: 1, newBuild: true, days: 6, views: 85, favs: 7, amenities: ['elevator', 'parking']),
      doc(title: 'Office Space, Business District', tx: 'rent', type: 'office', price: 3500, governorate: 'Tunis', city: 'Tunis', area: 'Lac 2', lat: 36.8480, lng: 10.2730, surface: 140, baths: 2, days: 8, views: 60, favs: 3, amenities: ['parking', 'elevator', 'airConditioning']),
      doc(title: 'Shop on Main Avenue', tx: 'rent', type: 'commercial', price: 2200, governorate: 'Sousse', city: 'Sousse', area: 'Centre Ville', lat: 35.8288, lng: 10.6405, surface: 60, days: 15, views: 25, favs: 0, verification: 'not_submitted'),
      doc(title: 'Family House in Nabeul', tx: 'buy', type: 'house', price: 690000, governorate: 'Nabeul', city: 'Nabeul', lat: 36.4513, lng: 10.7357, surface: 320, beds: 5, baths: 3, days: 30, views: 190, favs: 12, amenities: ['garden', 'pool', 'parking'], photos: false),
      doc(title: 'Studio near the University', tx: 'rent', type: 'apartment', price: 650, governorate: 'Monastir', city: 'Monastir', lat: 35.7643, lng: 10.8113, surface: 30, studio: true, baths: 1, days: 2, views: 55, favs: 4, amenities: ['airConditioning']),
      // Must NEVER appear anywhere (proves lifecycle filtering):
      doc(title: 'HIDDEN pending review', tx: 'buy', type: 'house', price: 100000, governorate: 'Tunis', city: 'Ariana', lat: 36.86, lng: 10.19, status: 'pending_review', verification: 'pending'),
      doc(title: 'HIDDEN expired', tx: 'rent', type: 'apartment', price: 700, governorate: 'Tunis', city: 'Bardo', lat: 36.81, lng: 10.14, status: 'expired', days: 90),
    ];

    final batch = _db.batch();
    for (final d in docs) {
      batch.set(_db.collection('properties').doc(), d);
    }
    await batch.commit();
    return docs.length;
  }

  Future<int> clear() async {
    final snap = await _db.collection('properties').where('isSample', isEqualTo: true).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    return snap.docs.length;
  }
}
