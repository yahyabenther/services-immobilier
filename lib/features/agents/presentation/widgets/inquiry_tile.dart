import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../messaging/domain/conversation.dart';
import 'agent_formatters.dart';
import 'agent_header.dart';
import 'agent_states.dart';

/// One received inquiry (spec §5.6): user, related property, last message, date,
/// read / unread state. Built on the SHARED conversation model.
class InquiryTile extends StatelessWidget {
  const InquiryTile({super.key, required this.conversation, required this.me, required this.onTap});

  final Conversation conversation;
  final String me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.isUnreadFor(me);
    final who = c.userName ?? 'Interested user';
    return Semantics(
      label: '${unread ? 'Unread. ' : ''}$who about ${c.propertyTitle ?? 'a property'}',
      button: true,
      child: AgentCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AgentAvatar(name: who, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, color: AppColors.text)),
                ),
                if (c.lastMessageAt != null)
                  Text(formatRelative(c.lastMessageAt!), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
              if (c.propertyTitle != null)
                Text(c.propertyTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(c.lastMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: unread ? AppColors.text : AppColors.muted)),
            ]),
          ),
          if (unread)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Icon(Icons.circle, size: 10, color: AppColors.primary),
            ),
        ]),
      ),
    );
  }
}
