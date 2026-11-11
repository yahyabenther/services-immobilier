import '../../../messaging/data/conversation_repository.dart';
import '../../../messaging/domain/conversation.dart';
import '../../../properties/domain/entities/property.dart';

/// "Contact agent" (spec §4.3). Orchestrates the SHARED messaging repository:
/// the conversation is tied to the property, so the professional knows which
/// listing the user asks about. Opening the same listing twice reuses the thread.
class OpenAgentConversation {
  const OpenAgentConversation(this._conversations);
  final ConversationRepository _conversations;

  Future<Conversation> call(Property property, {String? userName}) =>
      _conversations.openOrCreate(property, userName: userName);
}
