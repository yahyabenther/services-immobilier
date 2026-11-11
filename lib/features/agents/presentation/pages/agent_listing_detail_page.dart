import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/agent_providers.dart';
import '../widgets/agent_gate.dart';
import '../widgets/agent_listing_card.dart';
import '../widgets/agent_stat_card.dart';
import '../widgets/agent_states.dart';
import '../widgets/inquiry_tile.dart';
import '../widgets/listing_actions.dart';

/// `/agent/listings/:propertyId`: manage ONE listing of the signed-in agent.
/// A listing that is not in the agent's own list (another agent's, or withdrawn)
/// is simply "not found": the query is scoped by Firestore Rules, not just here.
class AgentListingDetailPage extends StatelessWidget {
  const AgentListingDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) => AgentGate(
        title: 'Listing',
        builder: (context, ref, profile) {
          final listings = ref.watch(agentListingsProvider);
          final me = ref.watch(currentUserProvider)?.id ?? '';

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Manage listing')),
            body: listings.when(
              loading: () => const AgentLoading(),
              error: (_, _) => AgentErrorView(
                message: 'We could not load your listings. Please try again.',
                onRetry: () => ref.invalidate(agentListingsProvider),
              ),
              data: (all) {
                Property? p;
                for (final x in all) {
                  if (x.id == propertyId) p = x;
                }
                if (p == null) {
                  return AgentEmptyView(
                    icon: Icons.search_off_rounded,
                    message: 'This listing could not be found among your listings.',
                    actionLabel: 'Back to my listings',
                    onAction: () => context.go(Routes.agentListings),
                  );
                }
                final stats = ref.watch(agentListingStatsProvider).value?[p.id];
                final inquiries = (ref.watch(agentInquiriesProvider).value ?? const [])
                    .where((c) => c.propertyId == p!.id)
                    .toList();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        ListingActions.card(context, ref, p, stats: stats, detail: true),
                        const SectionTitle('Performance'),
                        AgentStatGrid(cards: [
                          AgentStatCard(icon: Icons.visibility_outlined, label: 'Views', value: stats?.views ?? p.views),
                          AgentStatCard(icon: Icons.favorite_border, label: 'Favorites', value: stats?.favorites ?? p.favoritesCount),
                          AgentStatCard(icon: Icons.chat_bubble_outline_rounded, label: 'Inquiries', value: stats?.contacts ?? 0),
                        ]),
                        const SectionTitle('Inquiries about this listing'),
                        if (inquiries.isEmpty)
                          const Text('No inquiries about this listing yet.', style: TextStyle(color: AppColors.muted))
                        else
                          for (final c in inquiries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InquiryTile(conversation: c, me: me, onTap: () => context.push(Routes.chat(c.id))),
                            ),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Status: ', style: TextStyle(color: AppColors.muted)),
                          ListingStatusChip(status: p.status),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}
