import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/listing_draft.dart';
import '../domain/photo_rules.dart';
import '../domain/publishing_config.dart';

class PickedPhotos {
  const PickedPhotos({this.photos = const [], this.problems = const []});

  /// Files that passed every check, ready to be added to the draft.
  final List<ListingPhoto> photos;

  /// One user-facing sentence per rejected file.
  final List<String> problems;
}

abstract interface class PhotoPicker {
  Future<PickedPhotos> pick({required int remainingSlots});
}

/// Gallery picker with validation (spec §8: formats, size, max count) and
/// resize/re-encode through image_picker's own options.
class ImagePickerPhotoPicker implements PhotoPicker {
  final ImagePicker _picker = ImagePicker();
  var _counter = 0;

  @override
  Future<PickedPhotos> pick({required int remainingSlots}) async {
    if (remainingSlots <= 0) {
      return PickedPhotos(problems: ['You can add up to ${PublishingConfig.maxPhotos} photos.']);
    }
    final List<XFile> files;
    try {
      files = await _picker.pickMultiImage(
        maxWidth: PublishingConfig.pickMaxDimension,
        maxHeight: PublishingConfig.pickMaxDimension,
        imageQuality: PublishingConfig.pickQuality,
      );
    } catch (e) {
      debugPrint('Photo picker failed: $e');
      return const PickedPhotos(problems: ['Could not open your photo library.']);
    }

    final photos = <ListingPhoto>[];
    final problems = <String>[];
    for (final f in files) {
      if (photos.length >= remainingSlots) {
        problems.add('Only ${PublishingConfig.maxPhotos} photos are allowed: extra photos were ignored.');
        break;
      }
      try {
        final length = await f.length();
        final problem = PhotoRules.check(name: f.name, mimeType: f.mimeType, length: length);
        if (problem != null) {
          problems.add(problem);
          continue;
        }
        photos.add(ListingPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}_${_counter++}',
          name: f.name,
          bytes: await f.readAsBytes(),
        ));
      } catch (_) {
        problems.add('"${f.name}" could not be read.');
      }
    }
    return PickedPhotos(photos: photos, problems: problems);
  }
}
