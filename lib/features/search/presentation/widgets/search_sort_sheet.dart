import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_enums.dart';

/// Returns the chosen sort or null if dismissed.
Future<SortOption?> showSearchSortSheet(BuildContext context, SortOption current) {
  return showModalBottomSheet<SortOption>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        for (final s in SortOption.values)
          ListTile(
            title: Text(s.label),
            subtitle: switch (s) {
              SortOption.closest => const Text('Uses your location'),
              SortOption.recommended => const Text('Recent, verified and popular'),
              _ => null,
            },
            trailing: s == current ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => Navigator.of(ctx).pop(s),
          ),
      ]),
    ),
  );
}
