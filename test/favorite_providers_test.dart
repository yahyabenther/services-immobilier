// Module 07 unit tests: toggle / status / list logic with an in-memory repository
// (no Firebase needed). Run: flutter test test/features/favorites
//
// Package name: team_app (pubspec.yaml).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/core/errors/favorite_failure.dart';
import 'package:team_app/features/auth/domain/entities/auth_user.dart';
import 'package:team_app/features/auth/providers/auth_provider.dart';
import 'package:team_app/features/favorites/domain/entities/favorite.dart';
import 'package:team_app/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:team_app/features/favorites/providers/favorite_providers.dart';

class FakeFavoriteRepository implements FavoriteRepository {
  final List<String> _ids = []; // oldest first
  final _changes = StreamController<void>.broadcast();

  /// Makes every write fail like a network error.
  bool failWrites = false;

  /// While set, writes wait for it (to simulate a slow server).
  Completer<void>? writeGate;

  List<Favorite> _snapshot(String userId) => [
        for (final id in _ids.reversed)
          Favorite(id: '${userId}_$id', userId: userId, propertyId: id, createdAt: null),
      ];

  @override
  Stream<List<Favorite>> watchFavorites(String userId) async* {
    yield _snapshot(userId);
    await for (final _ in _changes.stream) {
      yield _snapshot(userId);
    }
  }

  @override
  Future<List<Favorite>> getFavorites(String userId) async => _snapshot(userId);

  @override
  Future<bool> isFavorite({required String userId, required String propertyId}) async =>
      _ids.contains(propertyId);

  @override
  Future<void> addFavorite({required String userId, required String propertyId}) async {
    await writeGate?.future;
    if (failWrites) throw const FavoriteFailure(FavoriteFailureType.network);
    if (!_ids.contains(propertyId)) _ids.add(propertyId);
    _changes.add(null);
  }

  @override
  Future<void> removeFavorite({required String userId, required String propertyId}) async {
    await writeGate?.future;
    if (failWrites) throw const FavoriteFailure(FavoriteFailureType.network);
    _ids.remove(propertyId);
    _changes.add(null);
  }
}

const _user = AuthUser(id: 'u1', email: 'u1@example.com', emailVerified: true);

ProviderContainer _container(FakeFavoriteRepository repo, {AuthUser? user = _user}) {
  final container = ProviderContainer(overrides: [
    currentUserProvider.overrideWithValue(user),
    favoriteRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(container.dispose);
  // Keep the live list subscribed, like the app does while any heart is on screen.
  container.listen(favoritesProvider, (_, _) {});
  return container;
}

void main() {
  test('toggle adds, then removes, and the status follows', () async {
    final container = _container(FakeFavoriteRepository());
    await pumpEventQueue();
    final toggle = container.read(favoriteToggleProvider);

    expect(container.read(isFavoriteProvider('p1')), isFalse);

    expect(await toggle(propertyId: 'p1'), FavoriteToggleResult.added);
    await pumpEventQueue();
    expect(container.read(isFavoriteProvider('p1')), isTrue);
    expect(container.read(favoritesCountProvider), 1);

    expect(await toggle(propertyId: 'p1'), FavoriteToggleResult.removed);
    await pumpEventQueue();
    expect(container.read(isFavoriteProvider('p1')), isFalse);
    expect(container.read(favoritesCountProvider), 0);
  });

  test('favorites are listed newest first', () async {
    final container = _container(FakeFavoriteRepository());
    await pumpEventQueue();
    final toggle = container.read(favoriteToggleProvider);

    await toggle(propertyId: 'p1');
    await pumpEventQueue();
    await toggle(propertyId: 'p2');
    await pumpEventQueue();

    final ids = container.read(favoritesProvider).value!.map((f) => f.propertyId).toList();
    expect(ids, ['p2', 'p1']);
  });

  test('signed out: sign-in required, nothing is written', () async {
    final repo = FakeFavoriteRepository();
    final container = _container(repo, user: null);
    await pumpEventQueue();

    final result = await container.read(favoriteToggleProvider)(propertyId: 'p1');

    expect(result, FavoriteToggleResult.signInRequired);
    expect(await repo.isFavorite(userId: 'u1', propertyId: 'p1'), isFalse);
    expect(container.read(favoritesCountProvider), 0);
  });

  test('a failing write is reported as failed and changes nothing', () async {
    final repo = FakeFavoriteRepository()..failWrites = true;
    final container = _container(repo);
    await pumpEventQueue();

    final result = await container.read(favoriteToggleProvider)(propertyId: 'p1');

    expect(result, FavoriteToggleResult.failed);
    await pumpEventQueue();
    expect(container.read(isFavoriteProvider('p1')), isFalse);
  });

  test('a second tap on the same property while the first is running is ignored', () async {
    final repo = FakeFavoriteRepository()..writeGate = Completer<void>();
    final container = _container(repo);
    await pumpEventQueue();
    final toggle = container.read(favoriteToggleProvider);

    final first = toggle(propertyId: 'p1');
    final second = await toggle(propertyId: 'p1');
    expect(second, FavoriteToggleResult.busy);

    repo.writeGate!.complete();
    expect(await first, FavoriteToggleResult.added);
  });

  test('an empty property id is refused', () async {
    final container = _container(FakeFavoriteRepository());
    await pumpEventQueue();

    expect(await container.read(favoriteToggleProvider)(propertyId: '  '), FavoriteToggleResult.failed);
  });
}