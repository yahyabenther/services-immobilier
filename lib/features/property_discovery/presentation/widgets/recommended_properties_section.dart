import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../providers/property_discovery_providers.dart';
import 'discovery_states.dart';
import 'properties_section.dart';

class RecommendedPropertiesSection extends ConsumerWidget {
  const RecommendedPropertiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PropertiesSection(
      title: 'Recommended for you',
      // Honest label: recent + verified + popular, not personalised.
      subtitle: 'Recent, verified and popular listings',
      data: ref.watch(recommendedPropertiesProvider),
      onRetry: () => ref.invalidate(recommendedPropertiesProvider),
      onSeeAll: () => context.go(Routes.searchWith(section: 'recommended')),
      empty: DiscoveryEmptyState(
        icon: Icons.home_work_outlined,
        title: 'No listings yet',
        message: 'New properties will appear here. Try searching in the meantime.',
        actionLabel: 'Search',
        onAction: () => context.go(Routes.search),
      ),
    );
  }
}
