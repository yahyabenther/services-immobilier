import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/property_discovery_providers.dart';

/// "Repères de prestige": entry to the map. Not a real map yet (never a broken one).
class MapPreviewCard extends ConsumerWidget {
  const MapPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    void open() => context.go(Routes.mapWith(location: location));

    return Semantics(
      button: true,
      label: 'Explorer les biens sur la carte',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x140B1F4B), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.explore_outlined, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Repères de prestige',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            Text(location?.label ?? 'Tunisie',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ]),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: open,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 84,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDDE8F8), Color(0xFFC6D9F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Icon(Icons.map_rounded, size: 100, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [
                        CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Explorer sur la carte',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.navy),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
