import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../data/conversation_repository.dart';
import '../../domain/conversation.dart';

/// Override in tests with a fake.
final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider)),
);

final conversationProvider = StreamProvider.autoDispose.family<Conversation?, String>(
  (ref, id) => ref.watch(conversationRepositoryProvider).watchConversation(id),
);

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, id) => ref.watch(conversationRepositoryProvider).watchMessages(id),
);

/// Inquiries received by the signed-in professional. Resets with the user.
final receivedConversationsProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return const Stream.empty();
  return ref.watch(conversationRepositoryProvider).watchReceived(uid);
});
