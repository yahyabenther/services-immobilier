import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../properties/domain/entities/property.dart';
import '../../data/listing_remote_data_source.dart';
import '../../data/listing_repository_impl.dart';
import '../../data/photo_picker.dart';
import '../../data/photo_uploader.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/entities/property_type_rules.dart';
import '../../domain/publishing_config.dart';
import '../../domain/publishing_failure.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../domain/services/listing_validator.dart';
import '../../domain/usecases/submit_listing.dart';

// ---- infrastructure (override in tests with fakes) -----------------------------
final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepositoryImpl(
    ListingRemoteDataSource(ref.watch(firestoreProvider)),
    CloudinaryPhotoUploader(CloudinaryService()),
  ),
);

final photoPickerProvider = Provider<PhotoPicker>((_) => ImagePickerPhotoPicker());

final submitListingProvider = Provider<SubmitListing>((ref) => SubmitListing(ref.watch(listingRepositoryProvider)));

// ---- state ------------------------------------------------------------------------
enum PublishPhase { editing, uploading, submitting, success }

class PublishingState {
  const PublishingState({
    this.draft = const ListingDraft(),
    this.step = PublishStep.type,
    this.phase = PublishPhase.editing,
    this.errors = const {},
    this.showErrors = false,
    this.message,
    this.failedPhotoIds = const {},
    this.uploadDone = 0,
    this.uploadTotal = 0,
    this.listingId,
    this.returnToPreview = false,
  });

  final ListingDraft draft;
  final PublishStep step;
  final PublishPhase phase;

  /// Field errors of the CURRENT step, only filled once the user tried to continue.
  final Map<ListingField, String> errors;
  final bool showErrors;

  /// Banner text (submission failure, rejected photos...). Always user-friendly.
  final String? message;
  final Set<String> failedPhotoIds;
  final int uploadDone;
  final int uploadTotal;

  /// Fixed on the first submit so every retry targets the same document.
  final String? listingId;

  /// Set when the user jumped back from the preview to fix one thing.
  final bool returnToPreview;

  bool get isBusy => phase == PublishPhase.uploading || phase == PublishPhase.submitting;
  bool get isSuccess => phase == PublishPhase.success;

  PublishingState copyWith({
    ListingDraft? draft,
    PublishStep? step,
    PublishPhase? phase,
    Map<ListingField, String>? errors,
    bool? showErrors,
    String? message,
    bool clearMessage = false,
    Set<String>? failedPhotoIds,
    int? uploadDone,
    int? uploadTotal,
    String? listingId,
    bool? returnToPreview,
  }) =>
      PublishingState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        phase: phase ?? this.phase,
        errors: errors ?? this.errors,
        showErrors: showErrors ?? this.showErrors,
        message: clearMessage ? null : (message ?? this.message),
        failedPhotoIds: failedPhotoIds ?? this.failedPhotoIds,
        uploadDone: uploadDone ?? this.uploadDone,
        uploadTotal: uploadTotal ?? this.uploadTotal,
        listingId: listingId ?? this.listingId,
        returnToPreview: returnToPreview ?? this.returnToPreview,
      );
}

/// Not autoDispose: leaving the page by accident must not lose the form. It resets
/// itself when the signed-in user changes (same convention as the other modules).
final publishingControllerProvider =
    NotifierProvider<PublishingController, PublishingState>(PublishingController.new);

class PublishingController extends Notifier<PublishingState> {
  /// photoId -> uploaded URL. Survives failed attempts so a retry only re-uploads
  /// the photos that failed.
  final Map<String, String> _uploaded = {};

  @override
  PublishingState build() {
    ref.watch(currentUserProvider.select((u) => u?.id));
    _uploaded.clear();
    return const PublishingState();
  }

  // ---- editing -----------------------------------------------------------------
  void _edit(ListingDraft Function(ListingDraft d) change) {
    if (state.isBusy) return;
    final draft = change(state.draft);
    state = state.copyWith(
      draft: draft,
      errors: state.showErrors ? ListingValidator.validateStep(state.step, draft) : state.errors,
      clearMessage: true,
    );
  }

  void setPropertyType(PropertyType t) => _edit((d) => d.copyWith(
        propertyType: t,
        // Switching to a type without studios / rooms must not keep stale values.
        isStudio: t.allowsStudio ? d.isStudio : false,
        bedrooms: t.usesBedrooms ? d.bedrooms : 0,
        bathrooms: t.usesBathrooms ? d.bathrooms : 0,
      ));
  void setTransactionType(TransactionType t) => _edit((d) => d.copyWith(transactionType: t));
  void setGovernorate(String g) => _edit((d) => d.copyWith(governorate: g));
  void setCity(String v) => _edit((d) => d.copyWith(city: v));
  void setArea(String v) => _edit((d) => d.copyWith(area: v));
  void setCoordinates(ListingCoordinates? c) =>
      _edit((d) => c == null ? d.copyWith(clearCoordinates: true) : d.copyWith(coordinates: c));
  void setPriceText(String v) => _edit((d) => d.copyWith(priceText: v));
  void setSurfaceText(String v) => _edit((d) => d.copyWith(surfaceText: v));
  void setBedrooms(int v) => _edit((d) => d.copyWith(bedrooms: v.clamp(0, 99)));
  void setBathrooms(int v) => _edit((d) => d.copyWith(bathrooms: v.clamp(0, 99)));
  void setStudio(bool v) => _edit((d) => d.copyWith(isStudio: v, bedrooms: v ? 0 : d.bedrooms));
  void setNewBuild(bool v) => _edit((d) => d.copyWith(isNewBuild: v));
  void setTitle(String v) => _edit((d) => d.copyWith(title: v));
  void setDescription(String v) => _edit((d) => d.copyWith(description: v));

  void toggleAmenity(String id) => _edit((d) {
        final next = {...d.amenities};
        if (!next.remove(id)) next.add(id);
        return d.copyWith(amenities: next);
      });

  // ---- photos --------------------------------------------------------------------
  void addPhotos(PickedPhotos picked) {
    if (state.isBusy) return;
    final room = PublishingConfig.maxPhotos - state.draft.photos.length;
    final accepted = picked.photos.take(room < 0 ? 0 : room).toList();
    final draft = state.draft.copyWith(photos: [...state.draft.photos, ...accepted]);
    state = state.copyWith(
      draft: draft,
      errors: state.showErrors ? ListingValidator.validateStep(state.step, draft) : state.errors,
      message: picked.problems.isEmpty ? null : picked.problems.join('\n'),
      clearMessage: picked.problems.isEmpty,
    );
  }

  void removePhoto(String id) {
    if (state.isBusy) return;
    _uploaded.remove(id);
    _edit((d) => d.copyWith(photos: [for (final p in d.photos) if (p.id != id) p]));
    if (state.failedPhotoIds.contains(id)) {
      state = state.copyWith(failedPhotoIds: {...state.failedPhotoIds}..remove(id));
    }
  }

  /// The first photo is the cover shown on cards.
  void makeCover(String id) => _edit((d) {
        final i = d.photos.indexWhere((p) => p.id == id);
        if (i <= 0) return d;
        final list = [...d.photos];
        list.insert(0, list.removeAt(i));
        return d.copyWith(photos: list);
      });

  // ---- navigation ----------------------------------------------------------------
  void next() {
    if (state.isBusy) return;
    final errors = ListingValidator.validateStep(state.step, state.draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors, showErrors: true);
      return;
    }
    final target = state.returnToPreview ? PublishStep.preview : state.step.next;
    if (target == null) return;
    state = state.copyWith(step: target, errors: {}, showErrors: false, clearMessage: true, returnToPreview: false);
  }

  void back() {
    if (state.isBusy) return;
    final target = state.returnToPreview ? PublishStep.preview : state.step.previous;
    if (target == null) return;
    state = state.copyWith(step: target, errors: {}, showErrors: false, clearMessage: true, returnToPreview: false);
  }

  /// "Edit" buttons of the preview: fix one thing, then come straight back.
  void editFromPreview(PublishStep step) {
    if (state.isBusy) return;
    state = state.copyWith(step: step, errors: {}, showErrors: false, clearMessage: true, returnToPreview: true);
  }

  // ---- submission ------------------------------------------------------------------
  Future<void> submit() async {
    if (state.isBusy || state.isSuccess) return; // no double submit (spec §14)
    final id = state.listingId ?? ref.read(listingRepositoryProvider).newListingId();
    state = state.copyWith(
      listingId: id,
      phase: PublishPhase.uploading,
      clearMessage: true,
      failedPhotoIds: {},
      errors: {},
      showErrors: false,
      uploadDone: _uploaded.keys.where((k) => state.draft.photos.any((p) => p.id == k)).length,
      uploadTotal: state.draft.photos.length,
    );
    try {
      await ref.read(submitListingProvider)(
        listingId: id,
        user: ref.read(currentUserProvider),
        draft: state.draft,
        uploaded: _uploaded,
        onProgress: (done, total) => state = state.copyWith(
          uploadDone: done,
          uploadTotal: total,
          phase: done >= total ? PublishPhase.submitting : PublishPhase.uploading,
        ),
      );
      _uploaded.clear();
      state = state.copyWith(phase: PublishPhase.success, clearMessage: true);
    } on PublishingFailure catch (e) {
      var step = state.step;
      if (e.type == PublishingFailureType.invalidData && e.fieldErrors.isNotEmpty) {
        // Take the user to the first screen that has something to fix.
        step = PublishStep.values.firstWhere(
          (s) => e.fieldErrors.keys.any(s.fields.contains),
          orElse: () => state.step,
        );
      }
      state = state.copyWith(
        phase: PublishPhase.editing,
        step: step,
        message: e.message,
        failedPhotoIds: e.failedPhotoIds,
        errors: e.type == PublishingFailureType.invalidData ? ListingValidator.validateStep(step, state.draft) : {},
        showErrors: e.type == PublishingFailureType.invalidData,
      );
    } catch (_) {
      state = state.copyWith(
        phase: PublishPhase.editing,
        message: const PublishingFailure(PublishingFailureType.unknown).message,
      );
    }
  }

  /// "Publish another" / discard.
  void reset() {
    _uploaded.clear();
    state = const PublishingState();
  }
}
