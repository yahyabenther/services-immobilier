import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/agent_failure.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../properties/data/property_mapper.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/agent_dashboard_stats.dart';
import '../../domain/entities/agent_notification.dart';
import '../../domain/entities/agent_profile.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/entities/verification_upload.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../domain/services/agent_profile_validator.dart';
import '../../domain/services/agent_stats_calculator.dart';
import '../../domain/services/listing_policy.dart';
import '../datasources/agent_remote_data_source.dart';
import '../models/agent_misc_models.dart';
import '../models/agent_profile_model.dart';

class AgentRepositoryImpl implements AgentRepository {
  AgentRepositoryImpl(this._ds, this._cloudinary);
  final AgentRemoteDataSource _ds;
  final CloudinaryService _cloudinary;

  // ---- error mapping ----------------------------------------------------
  static AgentFailure toFailure(Object e, AgentFailureType fallback) {
    if (e is AgentFailure) return e;
    if (e is FirebaseException) {
      debugPrint('Agent module Firebase error [${e.code}]: ${e.message}');
      return AgentFailure(switch (e.code) {
        'permission-denied' || 'unauthenticated' => AgentFailureType.permissionDenied,
        'unavailable' || 'deadline-exceeded' || 'network-request-failed' => AgentFailureType.network,
        _ => fallback,
      });
    }
    debugPrint('Agent module unexpected error: $e');
    return AgentFailure(fallback);
  }

  Future<T> _guard<T>(AgentFailureType fallback, Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw toFailure(e, fallback);
    }
  }

  Stream<T> _guardStream<T>(AgentFailureType fallback, Stream<T> source) => source.transform(
        StreamTransformer<T, T>.fromHandlers(
          handleError: (e, st, sink) => sink.addError(toFailure(e, fallback), st),
        ),
      );

  // ---- profile ----------------------------------------------------------
  @override
  Future<AgentProfile?> getProfile(String userId) => _guard(AgentFailureType.unknown, () async {
        final raw = await _ds.getProfile(userId);
        return raw == null ? null : AgentProfileModel.tryFromMap(raw.id, raw.data);
      });

  @override
  Stream<AgentProfile?> watchProfile(String userId) => _guardStream(
        AgentFailureType.unknown,
        _ds.watchProfile(userId).map((raw) => raw == null ? null : AgentProfileModel.tryFromMap(raw.id, raw.data)),
      );

  AgentProfile _prepared(AgentProfile p) {
    final errors = AgentProfileValidator.validate(p);
    if (errors.isNotEmpty) throw AgentFailure(AgentFailureType.validation, fieldErrors: errors);
    return p.copyWith(phone: Validators.normalizePhone(p.phone));
  }

  @override
  Future<void> createProfile(AgentProfile profile) => _guard(AgentFailureType.saveFailed, () async {
        final uid = _ds.uid;
        if (profile.userId != uid) throw const AgentFailure(AgentFailureType.permissionDenied);
        final p = _prepared(profile);
        if (await _ds.getProfile(uid) != null) {
          throw const AgentFailure(AgentFailureType.profileAlreadyExists);
        }
        await _ds.createProfile(AgentProfileModel.toCreateMap(p, uid: uid));
      });

  @override
  Future<void> updateProfile(AgentProfile profile) => _guard(AgentFailureType.saveFailed, () async {
        if (profile.userId != _ds.uid) throw const AgentFailure(AgentFailureType.permissionDenied);
        final p = _prepared(profile);
        await _ds.updateProfile(AgentProfileModel.toUpdateMap(p));
      });

  // ---- listings ---------------------------------------------------------
  List<Property> _listings(List<RawDoc> docs) => [
        for (final d in docs) ?PropertyMapper.tryFromMap(d.id, d.data),
      ].where((p) => p.status != PropertyStatus.removed).toList();

  Map<String, PropertyStats> _statsMap(List<RawDoc> docs) =>
      {for (final d in docs) d.id: PropertyStatsModel.fromMap(d.id, d.data)};

  @override
  Stream<List<Property>> watchAgentListings(String agentId, {int limit = 100}) => _guardStream(
        AgentFailureType.listingsFailed,
        _ds.watchAgentListings(agentId, limit: limit).map(_listings),
      );

  @override
  Future<List<Property>> getPublishedListings(String agentId, {int limit = 20}) =>
      _guard(AgentFailureType.listingsFailed, () async {
        final raw = await _ds.fetchPublishedListings(agentId, limit: limit);
        return [for (final d in raw) ?PropertyMapper.tryFromMap(d.id, d.data)];
      });

  @override
  Stream<Map<String, PropertyStats>> watchListingStats(String agentId) =>
      _guardStream(AgentFailureType.unknown, _ds.watchStats(agentId).map(_statsMap));

  @override
  Future<AgentDashboardStats> getDashboardStats(String agentId) => _guard(AgentFailureType.listingsFailed, () async {
        final listings = _listings(await _ds.fetchAgentListings(agentId, limit: 200));
        final stats = _statsMap(await _ds.fetchStats(agentId));
        return AgentStatsCalculator.compute(listings, stats);
      });

  void _requireOwnListing(Property l) {
    if (l.agentId != _ds.uid) {
      throw const AgentFailure(AgentFailureType.permissionDenied);
    }
  }

  @override
  Future<void> submitListing(Property listing) => _guard(AgentFailureType.saveFailed, () async {
        _requireOwnListing(listing);
        if (!ListingPolicy.canSubmit(listing.status)) {
          throw const AgentFailure(AgentFailureType.listingNotAllowed,
              detail: 'Only drafts and rejected listings can be submitted.');
        }
        final problems = ListingSubmissionCheck.problems(listing);
        if (problems.isNotEmpty) {
          throw AgentFailure(AgentFailureType.listingNotAllowed, detail: problems.first);
        }
        await _ds.updateListingStatus(listing.id, PropertyStatus.pendingReview.wire);
      });

  @override
  Future<void> withdrawListing(Property listing) => _guard(AgentFailureType.saveFailed, () async {
        _requireOwnListing(listing);
        if (!ListingPolicy.canWithdraw(listing.status)) {
          throw const AgentFailure(AgentFailureType.listingNotAllowed,
              detail: 'This listing cannot be withdrawn in its current status.');
        }
        await _ds.updateListingStatus(listing.id, PropertyStatus.removed.wire);
      });

  // ---- verification -----------------------------------------------------
  @override
  Stream<VerificationRequest?> watchLatestVerification(String agentId) => _guardStream(
        AgentFailureType.unknown,
        _ds.watchLatestVerification(agentId).map((raw) => raw == null ? null : VerificationModel.tryFromMap(raw.id, raw.data)),
      );

  @override
  Future<void> submitVerification({
    required AgentProfile profile,
    required List<VerificationUpload> documents,
  }) async {
    final uploaded = <String>[];
    try {
      final uid = _ds.uid;
      if (profile.userId != uid) throw const AgentFailure(AgentFailureType.permissionDenied);
      if (!canSubmitVerification(profile.verificationStatus)) {
        throw const AgentFailure(AgentFailureType.verificationNotAllowed,
            detail: 'A verification request is already pending or approved.');
      }
      final provided = documents.map((d) => d.category).toSet();
      final missing = AgentVerificationPolicy.requiredFor(isAgency: profile.isAgency).difference(provided);
      if (missing.isNotEmpty) {
        throw AgentFailure(AgentFailureType.verificationNotAllowed,
            detail: 'Add: ${missing.map((c) => c.label.toLowerCase()).join(', ')}.');
      }
      for (var i = 0; i < documents.length; i++) {
        final d = documents[i];
        // Private (`authenticated`) Cloudinary file; we keep only its public_id.
        uploaded.add(await _cloudinary.uploadPrivateDocument(
          d.bytes,
          filename: d.fileName,
          folder: 'verification/$uid/${d.category.name}',
        ));
      }
      await _ds.createVerification(VerificationModel.toCreateMap(uid: uid, storagePaths: uploaded));
    } catch (e) {
      // No request is created, so a half-sent upload is unreferenced. The app holds
      // no Cloudinary secret and cannot delete: purge `verification/` orphans with a
      // scheduled job if needed.
      if (e is CloudinaryUploadException) {
        throw const AgentFailure(AgentFailureType.verificationUploadFailed);
      }
      throw toFailure(e, AgentFailureType.verificationUploadFailed);
    }
  }

  // ---- notifications ----------------------------------------------------
  @override
  Stream<List<AgentNotification>> watchNotifications(String userId, {int limit = 10}) => _guardStream(
        AgentFailureType.unknown,
        _ds.watchNotifications(userId, limit: limit).map((docs) => [
              for (final d in docs) ?NotificationModel.tryFromMap(d.id, d.data),
            ]),
      );

  @override
  Future<void> markNotificationRead(String notificationId) =>
      _guard(AgentFailureType.unknown, () => _ds.markNotificationRead(notificationId));
}
