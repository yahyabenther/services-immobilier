import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../property_discovery/presentation/widgets/property_card_skeleton.dart';
import 'search_labels.dart';

class SearchLoadingList extends StatelessWidget {
  const SearchLoadingList({super.key});

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const PropertyCardSkeleton(width: double.infinity),
      );
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 56, color: color),
                const SizedBox(height: 14),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 18),
                ...actions,
              ]),
            ),
          ),
        ),
      );
}

/// No results. Offers to clear the filters when some are active.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.hasActiveCriteria, required this.onClear});

  final bool hasActiveCriteria;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => _Centered(
        icon: Icons.search_off_rounded,
        color: AppColors.primary,
        title: hasActiveCriteria ? SearchStrings.emptyTitle : SearchStrings.emptyFeedTitle,
        message: hasActiveCriteria ? SearchStrings.emptyMessage : SearchStrings.emptyFeedMessage,
        actions: [
          if (hasActiveCriteria)
            FilledButton(
              onPressed: onClear,
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              child: const Text('Clear filters'),
            ),
        ],
      );
}

/// Failed search. Retry keeps the current filters.
class SearchErrorState extends StatelessWidget {
  const SearchErrorState({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Centered(
        icon: Icons.cloud_off_rounded,
        color: AppColors.error,
        title: SearchStrings.errorTitle,
        message: message ?? SearchStrings.errorFallback,
        actions: [
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
            child: const Text('Retry'),
          ),
        ],
      );
}
