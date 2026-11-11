import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../providers/favorite_providers.dart';

/// Toggles a favorite and tells the user what happened (SnackBar). Shared by every
/// heart button so the behaviour is identical on Home, Search and Favorites.
Future<void> toggleFavoriteWithFeedback(BuildContext context, WidgetRef ref, String propertyId) async {
  // Everything that needs `context` / `ref` is captured BEFORE the await: after
  // removing a card from the Favorites list its widget is gone, but the SnackBar
  // "Undo" must still work.
  final toggle = ref.read(favoriteToggleProvider);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  void show(String message, {String? actionLabel, VoidCallback? onAction}) {
    messenger
      ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        persist: false,
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ));
  }

  final result = await toggle(propertyId: propertyId);

  switch (result) {
    case FavoriteToggleResult.added:
      show('Saved to favorites', actionLabel: 'View', onAction: () => router.go(Routes.favorites));
    case FavoriteToggleResult.removed:
      show(
        'Removed from favorites',
        actionLabel: 'Undo',
        onAction: () => unawaited(toggle(propertyId: propertyId)),
      );
    case FavoriteToggleResult.signInRequired:
      show('Sign in to save favorites.');
    case FavoriteToggleResult.failed:
      show("Couldn't update your favorites. Please try again.");
    case FavoriteToggleResult.busy:
      break;
  }
}