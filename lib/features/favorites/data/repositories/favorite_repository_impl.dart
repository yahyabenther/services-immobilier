import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException, Timestamp;
import 'package:flutter/foundation.dart';

import '../../../../core/errors/favorite_failure.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../datasources/favorite_remote_data_source.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._remote);

  final FavoriteRemoteDataSource _remote;

  static void _check(String userId, String propertyId) {
    if (userId.trim().isEmpty || propertyId.trim().isEmpty || propertyId.contains('/')) {
      throw const FavoriteFailure(FavoriteFailureType.invalidInput);
    }
  }

  static FavoriteFailure _map(FirebaseException e) {
    debugPrint('Favorites failed [${e.code}]: ${e.message}');
    return FavoriteFailure(switch (e.code) {
      'permission-denied' || 'unauthenticated' => FavoriteFailureType.permissionDenied,
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' => FavoriteFailureType.network,
      _ => FavoriteFailureType.unknown,
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FavoriteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    } catch (e, st) {
      debugPrint('Unexpected favorites error: $e\n$st');
      throw const FavoriteFailure(FavoriteFailureType.unknown);
    }
  }

  @override
  Future<void> addFavorite({required String userId, required String propertyId}) => _guard(() async {
        _check(userId, propertyId);
        try {
          await _remote.add(userId: userId, propertyId: propertyId);
        } on FirebaseException catch (e) {
          // Writing over an existing favorite is an "update" for the rules, which
          // refuse it. The property is already saved, so that is a success.
          if (e.code == 'permission-denied' && await _remote.exists(userId: userId, propertyId: propertyId)) {
            return;
          }
          rethrow;
        }
      });

  @override
  Future<void> removeFavorite({required String userId, required String propertyId}) => _guard(() async {
        _check(userId, propertyId);
        await _remote.remove(userId: userId, propertyId: propertyId);
      });

  @override
  Future<bool> isFavorite({required String userId, required String propertyId}) => _guard(() async {
        _check(userId, propertyId);
        return _remote.exists(userId: userId, propertyId: propertyId);
      });

  @override
  Future<List<Favorite>> getFavorites(String userId) => _guard(() async {
        _check(userId, 'x');
        return _toFavorites(await _remote.getForUser(userId));
      });

  @override
  Stream<List<Favorite>> watchFavorites(String userId) async* {
    try {
      _check(userId, 'x');
      await for (final raw in _remote.watchForUser(userId)) {
        yield _toFavorites(raw);
      }
    } on FavoriteFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _map(e);
    }
  }

  static List<Favorite> _toFavorites(List<RawFavorite> raw) {
    final list = <Favorite>[
  for (final r in raw) ?_toFavorite(r),
];
    // Newest first. A pending server timestamp (null) means "just added" = newest.
    list.sort((a, b) {
      final x = a.createdAt;
      final y = b.createdAt;
      if (x == null && y == null) return 0;
      if (x == null) return -1;
      if (y == null) return 1;
      return y.compareTo(x);
    });
    return list;
  }

  /// Malformed documents (no propertyId) are skipped so they never break the list.
  static Favorite? _toFavorite(RawFavorite r) {
    final d = r.data;
    final userId = d['userId'];
    final propertyId = d['propertyId'];
    if (userId is! String || propertyId is! String || propertyId.trim().isEmpty) return null;
    return Favorite(
      id: r.id,
      userId: userId,
      propertyId: propertyId,
      createdAt: switch (d['createdAt']) {
        Timestamp t => t.toDate(),
        DateTime t => t,
        _ => null,
      },
    );
  }
}