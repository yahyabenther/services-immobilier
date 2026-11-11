import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/agent_notification.dart';
import 'agent_formatters.dart';

/// Where a notification leads (spec FR-08): profile, listing or conversation.
String? routeForNotification(AgentNotification n) {
  if (n.conversationId != null) return Routes.chat(n.conversationId!);
  return switch (n.type) {
    AgentNotificationType.verificationSubmitted ||
    AgentNotificationType.verificationApproved ||
    AgentNotificationType.verificationRejected =>
      Routes.agentVerification,
    AgentNotificationType.listingSubmitted ||
    AgentNotificationType.listingApproved ||
    AgentNotificationType.listingRejected ||
    AgentNotificationType.listingSuspended ||
    AgentNotificationType.listingRestored =>
      n.propertyId == null ? Routes.agentListings : Routes.agentListing(n.propertyId!),
    _ => null,
  };
}

IconData iconForNotification(AgentNotificationType t) => switch (t) {
      AgentNotificationType.verificationApproved => Icons.verified_rounded,
      AgentNotificationType.verificationRejected || AgentNotificationType.listingRejected => Icons.error_outline_rounded,
      AgentNotificationType.verificationSubmitted || AgentNotificationType.listingSubmitted => Icons.send_outlined,
      AgentNotificationType.listingApproved || AgentNotificationType.listingRestored => Icons.check_circle_outline,
      AgentNotificationType.listingSuspended || AgentNotificationType.accountWarning => Icons.warning_amber_rounded,
      AgentNotificationType.newInquiry || AgentNotificationType.newMessage => Icons.chat_bubble_outline_rounded,
      AgentNotificationType.other => Icons.notifications_none_rounded,
    };

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AgentNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(iconForNotification(n.type), color: n.read ? AppColors.muted : AppColors.primary),
      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w800)),
      subtitle: Text(
        [if (n.body.isNotEmpty) n.body, if (n.createdAt != null) formatRelative(n.createdAt!)].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: n.read ? null : const Icon(Icons.circle, size: 9, color: AppColors.primary),
    );
  }
}
