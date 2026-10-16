import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/property_discovery_providers.dart';

/// Looks like a search field but only opens Module 04 (no search engine here).
class DiscoverySearchEntry extends ConsumerWidget {
  const DiscoverySearchEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Search properties',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(Routes.searchWith(location: ref.read(selectedLocationProvider))),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(children: [
            Icon(Icons.search, color: AppColors.muted),
            SizedBox(width: 10),
            Expanded(
              child: Text('Search by city, neighborhood, or property...',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted)),
            ),
            Icon(Icons.tune_rounded, color: AppColors.primary),
          ]),
        ),
      ),
    );
  }
}
