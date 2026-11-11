import '../../../properties/domain/entities/property.dart';
import '../entities/agent_dashboard_stats.dart';
import '../entities/agent_notification.dart';
import '../entities/agent_profile.dart';
import '../entities/verification_request.dart';
import '../entities/verification_upload.dart';

/// Agent module contract (spec §8.3, extended for verification, listings and
/// notifications). Every write derives the owner from Firebase Auth, never from
/// an id passed by the UI (spec §12 requirement 2).
///
/// Failures are thrown as `AgentFailure`.
abstract class AgentRepository {
  // ---- profile ----------------------------------------------------------
  Future<AgentProfile?> getProfile(String userId);
  Stream<AgentProfile?> watchProfile(String userId);

  /// [profileImageUrl] has already been uploaded by the caller.
  Future<void> createProfile(AgentProfile profile);
  Future<void> updateProfile(AgentProfile profile);

  // ---- listings ---------------------------------------------------------
  /// Every listing of [agentId] the caller may manage (all statuses except
  /// `removed`), newest update first.
  Stream<List<Property>> watchAgentListings(String agentId, {int limit = 100});

  /// Published listings only: the public profile.
  Future<List<Property>> getPublishedListings(String agentId, {int limit = 20});

  Future<AgentDashboardStats> getDashboardStats(String agentId);
  Stream<Map<String, PropertyStats>> watchListingStats(String agentId);

  /// draft | rejected -> pending_review, after `ListingSubmissionCheck`.
  Future<void> submitListing(Property listing);

  /// -> removed (the shared lifecycle's "withdrawn").
  Future<void> withdrawListing(Property listing);

  // ---- verification -----------------------------------------------------
  Stream<VerificationRequest?> watchLatestVerification(String agentId);
  Future<void> submitVerification({
    required AgentProfile profile,
    required List<VerificationUpload> documents,
  });

  // ---- notifications ----------------------------------------------------
  Stream<List<AgentNotification>> watchNotifications(String userId, {int limit = 10});
  Future<void> markNotificationRead(String notificationId);
}
