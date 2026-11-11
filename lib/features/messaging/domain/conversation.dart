/// SHARED conversation model (`conversations/{id}`, spec §6.6). The Agent module
/// reads it; it never keeps a second messaging database for agents.
///
/// Conversation id is deterministic: `{propertyId}_{userId}` -> one thread per
/// user per listing, and "open or create" needs no query.
class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    required this.userId,
    required this.recipientId,
    required this.propertyId,
    this.userName,
    this.propertyTitle,
    this.propertyImage,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.lastReadAt = const {},
    this.createdAt,
  });

  final String id;

  /// Exactly `[userId, recipientId]`; drives every access rule.
  final List<String> participants;

  /// The user who initiated the contact.
  final String userId;

  /// The professional (property.agentId) or the owner (property.ownerId).
  final String recipientId;
  final String propertyId;

  /// Public display snapshots, so lists need no extra reads.
  final String? userName;
  final String? propertyTitle;
  final String? propertyImage;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, DateTime> lastReadAt;
  final DateTime? createdAt;

  /// A conversation opened but never written to is not an inquiry yet.
  bool get hasMessages => (lastMessage ?? '').isNotEmpty;

  String otherParticipant(String me) => me == userId ? recipientId : userId;

  /// Unread for [me] when the last message is from the other side and newer
  /// than my last read time.
  bool isUnreadFor(String me) {
    if (!hasMessages || lastSenderId == null || lastSenderId == me) return false;
    final read = lastReadAt[me];
    final last = lastMessageAt;
    if (last == null) return true;
    return read == null || last.isAfter(read);
  }
}

class ChatMessage {
  const ChatMessage({required this.id, required this.senderId, required this.text, this.createdAt});

  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;
}
