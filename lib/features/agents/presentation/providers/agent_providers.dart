import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/agent_failure.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../../properties/domain/entities/property.dart';
import '../../data/agent_media_service.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../../domain/entities/agent_dashboard_stats.dart';
import '../../domain/entities/agent_notification.dart';
import '../../domain/entities/agent_profile.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/entities/verification_upload.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../domain/services/agent_stats_calculator.dart';
import '../../domain/usecases/create_agent_profile.dart';
import '../../domain/usecases/get_agent_profile.dart';
import '../../domain/usecases/manage_agent_listing.dart';
import '../../domain/usecases/open_agent_conversation.dart';
import '../../domain/usecases/submit_agent_verification.dart';
import '../../domain/usecases/update_agent_profile.dart';
import '../../domain/usecases/watch_agent_listings.dart';
import '../../domain/usecases/watch_agent_profile.dart';

// ---- infrastructure (override in tests) -----------------------------------
final cloudinaryServiceProvider = Provider<CloudinaryService>((_) => CloudinaryService());

final agentRepositoryProvider = Provider<AgentRepository>(
  (ref) => AgentRepositoryImpl(
    AgentRemoteDataSource(ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider)),
    ref.watch(cloudinaryServiceProvider),
  ),
);

final agentMediaServiceProvider =
    Provider<AgentMediaService>((ref) => AgentMediaService(cloudinary: ref.watch(cloudinaryServiceProvider)));

// ---- use cases --------------------------------------------------------------
final createAgentProfileProvider = Provider((ref) => CreateAgentProfile(ref.watch(agentRepositoryProvider)));
final getAgentProfileProvider = Provider((ref) => GetAgentProfile(ref.watch(agentRepositoryProvider)));
final updateAgentProfileProvider = Provider((ref) => UpdateAgentProfile(ref.watch(agentRepositoryProvider)));
final watchAgentProfileProvider = Provider((ref) => WatchAgentProfile(ref.watch(agentRepositoryProvider)));
final watchAgentListingsProvider = Provider((ref) => WatchAgentListings(ref.watch(agentRepositoryProvider)));
final submitAgentVerificationProvider =
    Provider((ref) => SubmitAgentVerification(ref.watch(agentRepositoryProvider)));
final submitAgentListingProvider = Provider((ref) => SubmitAgentListing(ref.watch(agentRepositoryProvider)));
final withdrawAgentListingProvider = Provider((ref) => WithdrawAgentListing(ref.watch(agentRepositoryProvider)));
final openAgentConversationProvider =
    Provider((ref) => OpenAgentConversation(ref.watch(conversationRepositoryProvider)));

// ---- data (every provider is scoped to the signed-in user and resets with it)
String? _uid(Ref ref) => ref.watch(currentUserProvider)?.id;

/// Own profile; `null` data means "no professional profile yet".
final agentProfileStreamProvider = StreamProvider.autoDispose<AgentProfile?>((ref) {
  final uid = _uid(ref);
  if (uid == null) return const Stream.empty();
  return ref.watch(watchAgentProfileProvider)(uid);
});

/// One-shot variant of the own profile.
final agentProfileProvider = FutureProvider.autoDispose<AgentProfile?>((ref) {
  final uid = _uid(ref);
  if (uid == null) return null;
  return ref.watch(getAgentProfileProvider)(uid);
});

/// Public profile by id. The document holds only public fields.
final publicAgentProfileProvider = StreamProvider.autoDispose.family<AgentProfile?, String>(
  (ref, agentId) => ref.watch(watchAgentProfileProvider)(agentId),
);

final agentPublishedListingsProvider = FutureProvider.autoDispose.family<List<Property>, String>(
  (ref, agentId) => ref.watch(agentRepositoryProvider).getPublishedListings(agentId),
);

/// The caller's own listings (all statuses except withdrawn).
final agentListingsProvider = StreamProvider.autoDispose<List<Property>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return const Stream.empty();
  return ref.watch(watchAgentListingsProvider)(uid);
});

final agentListingStatsProvider = StreamProvider.autoDispose<Map<String, PropertyStats>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchListingStats(uid);
});

/// Dashboard numbers: listings + trusted counters. If the stats collection is
/// unreachable the dashboard still renders from the counters on the listings.
final agentDashboardStatsProvider = Provider.autoDispose<AsyncValue<AgentDashboardStats>>((ref) {
  final listings = ref.watch(agentListingsProvider);
  final stats = ref.watch(agentListingStatsProvider);
  if (listings.hasError) return AsyncValue.error(listings.error!, listings.stackTrace ?? StackTrace.current);
  final data = listings.value;
  if (data == null) return const AsyncValue.loading();
  return AsyncValue.data(AgentStatsCalculator.compute(data, stats.value ?? const {}));
});

final agentVerificationProvider = StreamProvider.autoDispose<VerificationRequest?>((ref) {
  final uid = _uid(ref);
  if (uid == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchLatestVerification(uid);
});

final agentNotificationsProvider = StreamProvider.autoDispose<List<AgentNotification>>((ref) {
  final uid = _uid(ref);
  if (uid == null) return const Stream.empty();
  return ref.watch(agentRepositoryProvider).watchNotifications(uid);
});

/// Inquiries reuse the SHARED conversations (spec §5.6, §9).
final agentInquiriesProvider = receivedConversationsProvider;

// ---- profile form (saving / uploading states, spec §9) ---------------------
enum AgentSavePhase { idle, uploading, saving, saved, failed }

class AgentFormState {
  const AgentFormState({this.phase = AgentSavePhase.idle, this.failure});

  final AgentSavePhase phase;
  final AgentFailure? failure;

  bool get isBusy => phase == AgentSavePhase.uploading || phase == AgentSavePhase.saving;
}

final agentProfileFormProvider =
    NotifierProvider<AgentProfileFormController, AgentFormState>(AgentProfileFormController.new);

class AgentProfileFormController extends Notifier<AgentFormState> {
  @override
  AgentFormState build() => const AgentFormState();

  void reset() => state = const AgentFormState();

  /// Uploads the new image first; if that fails NOTHING is saved (spec §10.3).
  /// Returns true on success.
  Future<bool> save({
    required AgentProfile draft,
    required bool isCreate,
    PickedAgentImage? newImage,
  }) async {
    if (state.isBusy) return false; // duplicate taps are ignored
    try {
      var profile = draft;
      if (newImage != null) {
        state = const AgentFormState(phase: AgentSavePhase.uploading);
        final url = await ref.read(agentMediaServiceProvider).uploadProfileImage(newImage, uid: draft.userId);
        profile = profile.copyWith(profileImageUrl: url);
      }
      state = const AgentFormState(phase: AgentSavePhase.saving);
      if (isCreate) {
        await ref.read(createAgentProfileProvider)(profile);
      } else {
        await ref.read(updateAgentProfileProvider)(profile);
      }
      state = const AgentFormState(phase: AgentSavePhase.saved);
      return true;
    } on AgentFailure catch (e) {
      state = AgentFormState(phase: AgentSavePhase.failed, failure: e);
      return false;
    } catch (_) {
      state = const AgentFormState(phase: AgentSavePhase.failed, failure: AgentFailure(AgentFailureType.unknown));
      return false;
    }
  }

  /// Verification submit shares the same busy / failure channel.
  Future<bool> submitVerification({
    required AgentProfile profile,
    required List<VerificationUpload> documents,
  }) async {
    if (state.isBusy) return false;
    state = const AgentFormState(phase: AgentSavePhase.uploading);
    try {
      await ref.read(submitAgentVerificationProvider)(profile: profile, documents: documents);
      state = const AgentFormState(phase: AgentSavePhase.saved);
      return true;
    } on AgentFailure catch (e) {
      state = AgentFormState(phase: AgentSavePhase.failed, failure: e);
      return false;
    } catch (_) {
      state = const AgentFormState(
          phase: AgentSavePhase.failed, failure: AgentFailure(AgentFailureType.verificationUploadFailed));
      return false;
    }
  }
}
