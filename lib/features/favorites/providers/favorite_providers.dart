import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/datasources/favorite_remote_data_source.dart';
import '../data/repositories/favorite_repository_impl.dart';
import '../domain/entities/favorite.dart';
import '../domain/repositories/favorite_repository.dart';

/// Override in tests with a fake.
final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => FavoriteRepositoryImpl(FavoriteRemoteDataSource(ref.watch(firestoreProvider))),
);

/// The signed-in user's favorites, live, newest first. ONE Firestore listener
/// shared by every heart in the app. It follows the user: after logout / login
/// with another account it re-subscribes by itself (nothing to invalidate).
final favoritesProvider = StreamProvider<List<Favorite>>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u?.id));
  if (userId == null) return Stream.value(const <Favorite>[]);
  return ref.watch(favoriteRepositoryProvider).watchFavorites(userId);
});

/// Number of saved properties (0 while loading / on error / signed out).
final favoritesCountProvider = Provider<int>(
  (ref) => ref.watch(favoritesProvider).maybeWhen(data: (list) => list.length, orElse: () => 0),
);

/// Is this property a favorite? Same shape as before (`.value ?? false` works), but it
/// reads the shared live list instead of doing one Firestore read per card.
/// It never holds an error (an error counts as "not a favorite"), so reading
/// `.value` is always safe.
final favoriteStatusProvider = Provider.family<AsyncValue<bool>, String>((ref, propertyId) {
  return ref.watch(favoritesProvider).maybeWhen(
        data: (list) => AsyncValue<bool>.data(list.any((f) => f.propertyId == propertyId)),
        loading: () => const AsyncValue<bool>.loading(),
        orElse: () => const AsyncValue<bool>.data(false),
      );
});

/// Plain `bool` version for widgets: `ref.watch(isFavoriteProvider(id))`.
final isFavoriteProvider = Provider.family<bool, String>(
  (ref, propertyId) => ref.watch(favoriteStatusProvider(propertyId)).maybeWhen(data: (v) => v, orElse: () => false),
);

enum FavoriteToggleResult {
  added,
  removed,

  /// No signed-in user.
  signInRequired,

  /// The same property is already being toggled (double tap): ignored.
  busy,
  failed,
}

typedef FavoriteToggle = Future<FavoriteToggleResult> Function({required String propertyId});

/// `await ref.read(favoriteToggleProvider)(propertyId: id)` adds or removes the favorite
/// and says what happened. It never throws.
final favoriteToggleProvider = Provider<FavoriteToggle>((ref) {
  final inFlight = <String>{};

  return ({required String propertyId}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return FavoriteToggleResult.signInRequired;
    if (propertyId.trim().isEmpty) return FavoriteToggleResult.failed;
    if (!inFlight.add(propertyId)) return FavoriteToggleResult.busy;

    try {
      final repo = ref.read(favoriteRepositoryProvider);
      // The live list knows the answer; ask the repository only while it is still loading.
      final known = ref.read(favoriteStatusProvider(propertyId)).value;
      final isFavorite = known ?? await repo.isFavorite(userId: user.id, propertyId: propertyId);

      if (isFavorite) {
        await repo.removeFavorite(userId: user.id, propertyId: propertyId);
        return FavoriteToggleResult.removed;
      }
      await repo.addFavorite(userId: user.id, propertyId: propertyId);
      return FavoriteToggleResult.added;
    } catch (_) {
      return FavoriteToggleResult.failed;
    } finally {
      inFlight.remove(propertyId);
    }
  };
});