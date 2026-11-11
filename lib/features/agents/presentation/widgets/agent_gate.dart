import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/agent_failure.dart';
import '../../domain/entities/agent_profile.dart';
import '../providers/agent_providers.dart';
import 'agent_states.dart';

/// Wraps every professional page: while loading -> spinner, on error -> retry,
/// without a professional profile -> the "Create your professional profile"
/// empty state, otherwise [builder]. This is a UX guard only: Firestore Rules
/// still decide what the caller may read or write.
class AgentGate extends ConsumerWidget {
  const AgentGate({super.key, required this.title, required this.builder, this.actions});

  final String title;
  final Widget Function(BuildContext context, WidgetRef ref, AgentProfile profile) builder;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(agentProfileStreamProvider);
    return profile.when(
      loading: () => Scaffold(appBar: AppBar(title: Text(title)), body: const AgentLoading()),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AgentErrorView(
          message: e is AgentFailure ? e.message : const AgentFailure(AgentFailureType.unknown).message,
          onRetry: () => ref.invalidate(agentProfileStreamProvider),
        ),
      ),
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: AgentEmptyView(
              icon: Icons.badge_outlined,
              message:
                  'Create your professional profile to present your services and manage your real-estate listings.',
              actionLabel: 'Create professional profile',
              onAction: () => context.push(Routes.agentSetup),
            ),
          );
        }
        return builder(context, ref, p);
      },
    );
  }
}
