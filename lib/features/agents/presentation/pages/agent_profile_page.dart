import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/agent_gate.dart';
import '../widgets/agent_profile_view.dart';

/// `/agent/profile`: how the public sees you, plus the Edit action.
class AgentProfilePage extends StatelessWidget {
  const AgentProfilePage({super.key});

  @override
  Widget build(BuildContext context) => AgentGate(
        title: 'My professional profile',
        builder: (context, ref, profile) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My professional profile'),
            actions: [
              IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Routes.agentProfileEdit),
              ),
            ],
          ),
          body: AgentProfileView(profile: profile),
        ),
      );
}
