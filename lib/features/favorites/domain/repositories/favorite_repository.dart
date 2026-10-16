import '../entities/favorite.dart';

/// Throws `FavoriteFailure` only.
abstract interface class FavoriteRepository {
  /// Live list of the user's favorites, newest first. Emits again after every
  /// add / remove (also from the local cache, so the heart reacts instantly).
  Stream<List<Favorite>> watchFavorites(String userId);

  /// One-shot version of [watchFavorites].
  Future<List<Favorite>> getFavorites(String userId);

  Future<bool> isFavorite({required String userId, required String propertyId});

  /// Idempotent: adding an existing favorite is a success.
  Future<void> addFavorite({required String userId, required String propertyId});

  /// Idempotent: removing a missing favorite is a success.
  Future<void> removeFavorite({required String userId, required String propertyId});
}