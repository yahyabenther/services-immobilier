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
      title: 'Biens en vedette',
      layout: PropertiesLayout.featured,
      seeAllLabel: 'Explorer',
      data: ref.watch(recommendedPropertiesProvider),
      onRetry: () => ref.invalidate(recommendedPropertiesProvider),
      onSeeAll: () => context.go(Routes.searchWith(section: 'recommended')),
      empty: DiscoveryEmptyState(
        icon: Icons.home_work_outlined,
        title: 'Aucune annonce pour le moment',
        message: 'Les nouveaux biens apparaîtront ici. En attendant, lancez une recherche.',
        actionLabel: 'Rechercher',
        onAction: () => context.go(Routes.search),
      ),
    );
  }
}
