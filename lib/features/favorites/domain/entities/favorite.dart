/// One saved property of one user. Firestore: `favorites/{userId}_{propertyId}`
/// with the fields `userId`, `propertyId`, `createdAt` (study §23).
class Favorite {
  const Favorite({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String propertyId;

  /// Null only while the server timestamp of a just-written favorite is pending.
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is Favorite &&
      other.id == id &&
      other.userId == userId &&
      other.propertyId == propertyId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, userId, propertyId, createdAt);
}