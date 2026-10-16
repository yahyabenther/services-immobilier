import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../domain/publish_permission.dart';
import '../providers/property_discovery_providers.dart';
import '../widgets/discovery_search_entry.dart';
import '../widgets/home_header.dart';
import '../widgets/location_selector.dart';
import '../widgets/map_preview_card.dart';
import '../widgets/nearby_properties_section.dart';
import '../widgets/publish_property_cta.dart';
import '../widgets/recommended_properties_section.dart';
import '../widgets/transaction_shortcuts.dart';

/// Header and controls render immediately; every property section loads, fails
/// and retries on its own, so one failing query never blanks the screen.
class HomeDiscoveryScreen extends ConsumerWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPublish = canPublishProperty(ref.watch(currentUserProvider));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshDiscovery(ref),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720), // tablets
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 18),
                  const LocationSelector(),
                  const SizedBox(height: 12),
                  const DiscoverySearchEntry(),
                  const SizedBox(height: 16),
                  const TransactionShortcuts(),
                  const SizedBox(height: 24),
                  const RecommendedPropertiesSection(),
                  const SizedBox(height: 24),
                  const NearbyPropertiesSection(),
                  const SizedBox(height: 24),
                  const MapPreviewCard(),
                  if (canPublish) ...[
                    const SizedBox(height: 16),
                    const PublishPropertyCta(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
