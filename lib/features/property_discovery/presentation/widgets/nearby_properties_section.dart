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
          const AppSectionHeader(title: 'Nearby properties'),
          const SizedBox(height: 10),
          DiscoveryEmptyState(
            icon: Icons.location_searching_rounded,
            title: 'Choose your area',
            message: 'Pick a governorate or use your location to see listings close to you.',
            actionLabel: 'Choose location',
            onAction: () => showLocationPicker(context),
          ),
        ],
      );
    }

    final byDevice = location.hasCoordinates;
    return PropertiesSection(
      title: byDevice ? 'Nearby properties' : 'Properties in ${location.label}',
      subtitle: byDevice ? 'Within 10 km of your location' : null,
      data: ref.watch(nearbyPropertiesProvider),
      onRetry: () => ref.invalidate(nearbyPropertiesProvider),
      onSeeAll: () => context.go(Routes.searchWith(section: 'nearby', location: location)),
      empty: DiscoveryEmptyState(
        icon: Icons.location_off_outlined,
        title: byDevice ? 'Nothing within 10 km' : 'No listings in ${location.label}',
        message: 'Try another area to discover more properties.',
        actionLabel: 'Change area',
        onAction: () => showLocationPicker(context),
      ),
    );
  }
}
