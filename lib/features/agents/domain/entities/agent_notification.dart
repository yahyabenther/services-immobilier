/// In-app notification (`notifications/{id}`, written by Cloud Functions only).
enum AgentNotificationType {
  verificationSubmitted,
  verificationApproved,
  verificationRejected,
  listingSubmitted,
  listingApproved,
  listingRejected,
  listingSuspended,
  listingRestored,
  newInquiry,
  newMessage,
  accountWarning,
  other;

  static AgentNotificationType parse(String? v) =>
      AgentNotificationType.values.firstWhere((t) => t.name == v, orElse: () => AgentNotificationType.other);
}

class AgentNotification {
  const AgentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.propertyId,
    this.conversationId,
    this.createdAt,
  });

  final String id;
  final AgentNotificationType type;
  final String title;
  final String body;
  final bool read;
  final String? propertyId;
  final String? conversationId;
  final DateTime? createdAt;
}
