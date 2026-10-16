import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../property_discovery/presentation/widgets/property_card.dart';
import '../../providers/property_providers.dart';

/// Optional section: while loading, on error and when empty it renders nothing,
/// so the main property stays readable whatever happens here.
class SimilarProperties extends ConsumerWidget {
  const SimilarProperties({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(similarPropertiesProvider(propertyId)).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.4);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      const AppSectionHeader(title: 'Similar properties'),
      const SizedBox(height: 10),
      SizedBox(
        height: 282 * scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = items[i];
            return PropertyCard(
              key: ValueKey(p.id),
              property: p,
              width: 240,
              onTap: () => context.push(Routes.propertyDetails(p.id)),
              // No favorite control until the Favorites module exists.
            );
          },
        ),
      ),
    ]);
  }
}
