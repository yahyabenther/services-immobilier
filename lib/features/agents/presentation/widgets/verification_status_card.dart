import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/verification_request.dart';
import 'agent_formatters.dart';
import 'agent_states.dart';

/// Verification status with the next action (spec §11.3). Icon + text, never
/// colour alone.
class VerificationStatusCard extends StatelessWidget {
  const VerificationStatusCard({super.key, required this.status, this.request, this.onTap, this.compact = false});

  final VerificationStatus status;
  final VerificationRequest? request;
  final VoidCallback? onTap;
  final bool compact;

  ({IconData icon, Color color, String title, String body}) get _info => switch (status) {
        VerificationStatus.notSubmitted => (
            icon: Icons.shield_outlined,
            color: AppColors.muted,
            title: 'Not verified',
            body: 'Submit your documents to earn the verified badge.',
          ),
        VerificationStatus.pending => (
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFB7791F),
            title: 'Verification pending',
            body: request?.submittedAt == null
                ? 'Your request is being reviewed.'
                : 'Submitted on ${formatShortDate(request!.submittedAt!)}. We are reviewing it.',
          ),
        VerificationStatus.approved => (
            icon: Icons.verified_rounded,
            color: AppColors.success,
            title: 'Verified professional',
            body: 'Your profile shows the verified badge.',
          ),
        VerificationStatus.rejected => (
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
            title: 'Verification rejected',
            body: (request?.rejectionReason ?? '').isEmpty
                ? 'Please correct your documents and resubmit.'
                : request!.rejectionReason!,
          ),
        VerificationStatus.expired => (
            icon: Icons.history_toggle_off_rounded,
            color: AppColors.error,
            title: 'Verification expired',
            body: 'Submit updated documents to restore your badge.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Semantics(
      label: '${i.title}. ${i.body}',
      child: AgentCard(
        onTap: onTap,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i.icon, color: i.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(i.title, style: TextStyle(fontWeight: FontWeight.w800, color: i.color)),
              if (!compact) ...[
                const SizedBox(height: 3),
                Text(i.body, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.35)),
              ],
            ]),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}
