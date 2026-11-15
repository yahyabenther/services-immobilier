import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../properties/domain/entities/property.dart';
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

/// Compact on purpose: the visitor should see listings without scrolling much.
/// Header and controls render immediately; every property section loads, fails
/// and retries on its own, so one failing query never blanks the screen.
class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  ConsumerState<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends ConsumerState<HomeDiscoveryScreen> {
  TransactionType _type = TransactionType.buy;

  @override
  Widget build(BuildContext context) {
    final canPublish = canPublishProperty(ref.watch(currentUserProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshDiscovery(ref),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720), // tablets
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 12),
                  DiscoverySearchEntry(transactionType: _type),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 48,
                        child: TransactionToggle(value: _type, onChanged: (v) => setState(() => _type = v)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(flex: 6, child: SizedBox(height: 48, child: LocationSelector())),
                  ]),
                  const SizedBox(height: 18),
                  const RecommendedPropertiesSection(),
                  const SizedBox(height: 18),
                  const NearbyPropertiesSection(),
                  const SizedBox(height: 18),
                  const MapPreviewCard(),
                  if (canPublish) ...[
                    const SizedBox(height: 14),
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
