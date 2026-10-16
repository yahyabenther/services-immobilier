import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/property_discovery_providers.dart';

/// Map preview entry. Until the map SDK exists (Module 06) this is a fallback
/// card — never a broken map. Swap the body for a real static map later.
class MapPreviewCard extends ConsumerWidget {
  const MapPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Explore properties on the map',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(Routes.mapWith(location: ref.read(selectedLocationProvider))),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFE3EEFF), Color(0xFFCFE1FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            const Icon(Icons.map_rounded, size: 52, color: AppColors.primary),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Explore on the map',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
                SizedBox(height: 4),
                Text('See listings around you at a glance.', style: TextStyle(color: AppColors.muted)),
              ]),
            ),
            FilledButton(
              onPressed: () => context.go(Routes.mapWith(location: ref.read(selectedLocationProvider))),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
              child: const Text('Explore'),
            ),
          ]),
        ),
      ),
    );
  }
}
