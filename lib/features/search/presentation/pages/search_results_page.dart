import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_theme.dart';
import '../../domain/entities/search_enums.dart';
import '../../providers/search_filter_provider.dart';
import '../../providers/search_results_provider.dart';
import '../widgets/property_result_card.dart';
import '../widgets/search_labels.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    final filter = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
        actions: [
          IconButton(
            tooltip: 'Trier',
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: () => _showSortSheet(context, ref, filter.sort),
          ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          icon: Icons.error_outline,
          title: 'Impossible de charger les biens',
          subtitle: '$e',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(searchResultsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _Message(
              icon: Icons.search_off_rounded,
              title: 'Aucun bien trouvé',
              subtitle: 'Essayez de modifier ou de réinitialiser vos filtres.',
              actionLabel: 'Modifier les filtres',
              onAction: () => Navigator.of(context).pop(),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Text(
                  '${items.length} bien(s) • ${filter.sort.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.muted,
                  ),
                );
              }
              // TODO(module détails): ouvrir la page détails du bien.
              return PropertyResultCard(property: items[i - 1]);
            },
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref, SortOption current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Trier par',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            for (final s in SortOption.values)
              ListTile(
                title: Text(s.label),
                trailing: s == current
                    ? const Icon(Icons.check_rounded, color: C.navy)
                    : null,
                onTap: () {
                  ref.read(searchFilterProvider.notifier).setSort(s);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: C.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: C.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.navy),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}