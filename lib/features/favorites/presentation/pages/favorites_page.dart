import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/property_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/providers/property_providers.dart';
import '../../../property_discovery/presentation/widgets/discovery_states.dart';
import '../../../property_discovery/presentation/widgets/property_card_skeleton.dart';
import '../../domain/entities/favorite.dart';
import '../../providers/favorite_providers.dart';
import '../favorite_feedback.dart';
import '../widgets/favorite_property_card.dart';

/// Module 07 screen (`/favorites` tab): the user's saved properties, newest first.
///
/// The list of favorites is live (Firestore snapshots). Each row loads its property
/// by id through the shared `propertyDetailsProvider`, so a listing that was removed
/// or unpublished shows as "no longer available" and can be removed from the list.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        loading: () => const _LoadingList(),
        error: (_, __) => _LoadFailed(onRetry: () => ref.invalidate(favoritesProvider)),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: DiscoveryEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'No favorites yet',
                    message: 'Tap the heart on a property to save it here.',
                    actionLabel: 'Browse properties',
                    onAction: () => context.go(Routes.search),
                  ),
                ),
              )
            : _FavoritesList(items: items),
      ),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList({required this.items});

  final List<Favorite> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        for (final f in items) {
          ref.invalidate(propertyDetailsProvider(f.propertyId));
        }
        ref.invalidate(favoritesProvider);
        try {
          await ref.read(favoritesProvider.future);
        } catch (_) {
          // The error state of the page already explains it.
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720), // tablets
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    items.length == 1 ? '1 saved property' : '${items.length} saved properties',
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                );
              }
              final favorite = items[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FavoriteTile(key: ValueKey(favorite.propertyId), favorite: favorite),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({super.key, required this.favorite});

  final Favorite favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = favorite.propertyId;
    final load = ref.watch(propertyDetailsProvider(id));

    return load.when(
      loading: () => const PropertyCardSkeleton(width: double.infinity),
      error: (_, __) => _UnavailableTile(
        message: 'Something went wrong while loading this property.',
        onRetry: () => ref.invalidate(propertyDetailsProvider(id)),
        onRemove: () => toggleFavoriteWithFeedback(context, ref, id),
      ),
      data: (result) {
        final property = result.property;
        if (property != null) {
          return FavoritePropertyCard(property: property, width: double.infinity);
        }
        final failure = result.failure;
        final retryable =
            failure != null && (failure.type == PropertyFailureType.network || failure.type == PropertyFailureType.unknown);
        return _UnavailableTile(
          message: failure?.message ?? 'This property is no longer available.',
          onRetry: retryable ? () => ref.invalidate(propertyDetailsProvider(id)) : null,
          onRemove: () => toggleFavoriteWithFeedback(context, ref, id),
        );
      },
    );
  }
}

class _UnavailableTile extends StatelessWidget {
  const _UnavailableTile({required this.message, required this.onRemove, this.onRetry});

  final String message;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_work_outlined, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(message, style: const TextStyle(color: AppColors.text)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton(onPressed: onRemove, child: const Text('Remove from favorites')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, __) => const PropertyCardSkeleton(width: double.infinity),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: 14),
            const Text("Couldn't load your favorites.", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}