import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/agent_providers.dart';
import '../widgets/agent_gate.dart';
import '../widgets/agent_states.dart';
import '../widgets/inquiry_tile.dart';

/// `/agent/inquiries`: conversations received about the agent's listings.
/// Reuses the SHARED Conversation model (no second messaging database).
class AgentInquiriesPage extends StatelessWidget {
  const AgentInquiriesPage({super.key});

  @override
  Widget build(BuildContext context) => AgentGate(
        title: 'Inquiries',
        builder: (context, ref, profile) {
          final inquiries = ref.watch(agentInquiriesProvider);
          final me = ref.watch(currentUserProvider)?.id ?? '';
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Inquiries')),
            body: inquiries.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(20),
                children: const [SkeletonBox(height: 84), SizedBox(height: 10), SkeletonBox(height: 84), SizedBox(height: 10), SkeletonBox(height: 84)],
              ),
              error: (_, _) => AgentErrorView(
                message: 'We could not load your inquiries. Please try again.',
                onRetry: () => ref.invalidate(agentInquiriesProvider),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(agentInquiriesProvider),
                child: items.isEmpty
                    ? ListView(children: const [
                        SizedBox(
                          height: 380,
                          child: AgentEmptyView(
                            icon: Icons.chat_bubble_outline_rounded,
                            message: 'You do not have any inquiries yet. New messages about your properties will appear here.',
                          ),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => InquiryTile(
                          conversation: items[i],
                          me: me,
                          onTap: () => context.push(Routes.chat(items[i].id)),
                        ),
                      ),
              ),
            ),
          );
        },
      );
}
