import '../../../auth/domain/entities/auth_user.dart';
import '../../../property_discovery/domain/publish_permission.dart';
import '../entities/listing_draft.dart';
import '../publishing_failure.dart';
import '../repositories/listing_repository.dart';
import '../services/listing_validator.dart';

/// `submitListing()` from the spec (§11.1):
/// user -> validation -> upload photos -> URLs -> create document (pending_review).
///
/// Failure-safe by construction:
/// * nothing is written to Firestore unless EVERY photo uploaded;
/// * [uploaded] (photoId -> url) is owned by the caller and survives a failed
///   attempt, so a retry only re-uploads the photos that failed;
/// * the document id is fixed by the caller, so a retry can never create a duplicate.
class SubmitListing {
  SubmitListing(this._repo, {this.uploadConcurrency = 3});

  final ListingRepository _repo;
  final int uploadConcurrency;

  Future<void> call({
    required String listingId,
    required AuthUser? user,
    required ListingDraft draft,
    required Map<String, String> uploaded,
    void Function(int done, int total)? onProgress,
  }) async {
    if (user == null) throw const PublishingFailure(PublishingFailureType.notAuthenticated);
    if (!canPublishProperty(user)) throw const PublishingFailure(PublishingFailureType.notAllowed);

    final errors = ListingValidator.validate(draft);
    if (errors.isNotEmpty) {
      throw PublishingFailure(PublishingFailureType.invalidData, fieldErrors: errors);
    }

    final total = draft.photos.length;
    final pending = [for (final p in draft.photos) if (!uploaded.containsKey(p.id)) p];
    var done = total - pending.length;
    onProgress?.call(done, total);

    final failed = <String>{};
    for (var i = 0; i < pending.length; i += uploadConcurrency) {
      final chunk = pending.skip(i).take(uploadConcurrency);
      await Future.wait([
        for (final photo in chunk)
          () async {
            try {
              uploaded[photo.id] = await _repo.uploadPhoto(listingId: listingId, photo: photo);
              done++;
              onProgress?.call(done, total);
            } catch (_) {
              // Any failure of one photo only marks THAT photo as failed.
              failed.add(photo.id);
            }
          }(),
      ]);
    }
    if (failed.isNotEmpty) {
      throw PublishingFailure(PublishingFailureType.uploadFailed, failedPhotoIds: failed);
    }

    final urls = [for (final p in draft.photos) uploaded[p.id]!];
    onProgress?.call(total, total);
    await _repo.createListing(listingId: listingId, draft: draft, user: user, imageUrls: urls);
  }
}
