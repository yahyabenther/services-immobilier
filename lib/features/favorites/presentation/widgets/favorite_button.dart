import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorite_providers.dart';
import '../favorite_feedback.dart';

/// Heart toggle for places that are not a property card (e.g. the Details AppBar).
/// Same behaviour as the heart on [FavoritePropertyCard]: shows the real state,
/// toggles it and tells the user what happened (SnackBar).
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(propertyId));
    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () => toggleFavoriteWithFeedback(context, ref, propertyId),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
    );
  }
}
