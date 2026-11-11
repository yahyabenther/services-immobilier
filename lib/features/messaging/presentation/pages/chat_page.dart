import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../agents/presentation/widgets/agent_formatters.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/conversation_repository.dart';
import '../../domain/conversation.dart';
import '../providers/messaging_providers.dart';

/// `/chat/:conversationId`: minimal shared conversation screen. Only the two
/// participants can read or write it (Firestore Rules); the thread is tied to
/// ONE property so the professional knows which listing is discussed.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationRepositoryProvider).markRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (_sending || text.trim().isEmpty) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(conversationRepositoryProvider).sendMessage(widget.conversationId, text);
      if (mounted) _controller.clear();
    } on ConversationFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider)?.id ?? '';
    final convo = ref.watch(conversationProvider(widget.conversationId));
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));

    // Mark as read whenever a message from the other side arrives while open.
    ref.listen(chatMessagesProvider(widget.conversationId), (_, next) {
      final latest = next.value?.firstOrNull;
      if (latest != null && latest.senderId != me) {
        ref.read(conversationRepositoryProvider).markRead(widget.conversationId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(convo.value?.userId == me ? 'Advertiser' : (convo.value?.userName ?? 'Conversation'))),
      body: convo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('You are not allowed to open this conversation.')),
        data: (c) {
          if (c == null) return const Center(child: Text('This conversation does not exist.'));
          if (!c.participants.contains(me)) {
            return const Center(child: Text('You are not allowed to open this conversation.'));
          }
          return Column(children: [
            _PropertyHeader(conversation: c),
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('We could not load the messages.')),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('Say hello and ask your question.', style: TextStyle(color: AppColors.muted)))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _Bubble(message: items[i], mine: items[i].senderId == me),
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                color: Colors.white,
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: ConversationRepository.maxMessageLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => context.push(Routes.propertyDetails(conversation.propertyId)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 48, height: 48, child: PropertyImage(url: conversation.propertyImage, size: PropertyImageSize.thumb)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(conversation.propertyTitle ?? 'Property',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ]),
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: mine ? null : Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(message.text, style: TextStyle(color: mine ? Colors.white : AppColors.text, height: 1.35)),
            if (message.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(formatRelative(message.createdAt!),
                    style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : AppColors.muted)),
              ),
          ]),
        ),
      );
}
