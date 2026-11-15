import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../providers/property_discovery_providers.dart';
import 'discovery_states.dart';
import 'location_selector.dart';
import 'properties_section.dart';

class NearbyPropertiesSection extends ConsumerWidget {
  const NearbyPropertiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);

    // No location chosen: never pretend, ask for one (manual choice always works).
    if (location == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Près de vous'),
          const SizedBox(height: 8),
          DiscoveryEmptyState(
            icon: Icons.location_searching_rounded,
            title: 'Choisissez votre zone',
            message: 'Sélectionnez un gouvernorat ou utilisez votre position pour voir les biens proches.',
            actionLabel: 'Choisir la zone',
            onAction: () => showLocationPicker(context),
          ),
        ],
      );
    }

    final byDevice = location.hasCoordinates;
    return PropertiesSection(
      title: byDevice ? 'Près de vous' : 'Biens à ${location.label}',
      layout: PropertiesLayout.list,
      seeAllLabel: 'Voir tout',
      data: ref.watch(nearbyPropertiesProvider),
      onRetry: () => ref.invalidate(nearbyPropertiesProvider),
      onSeeAll: () => context.go(Routes.searchWith(section: 'nearby', location: location)),
      empty: DiscoveryEmptyState(
        icon: Icons.location_off_outlined,
        title: byDevice ? 'Rien dans un rayon de 10 km' : 'Aucun bien à ${location.label}',
        message: 'Essayez une autre zone pour découvrir plus de biens.',
        actionLabel: 'Changer de zone',
        onAction: () => showLocationPicker(context),
      ),
    );
  }
}
