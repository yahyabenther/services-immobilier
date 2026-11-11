import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/publishing_config.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'publish_widgets.dart';

/// Step 8: gallery of chosen photos. Pick (validated) -> reorder / remove. The
/// upload itself happens on submit, so nothing is stored for an abandoned form.
class PropertyPhotosPicker extends ConsumerStatefulWidget {
  const PropertyPhotosPicker({super.key});

  @override
  ConsumerState<PropertyPhotosPicker> createState() => _PropertyPhotosPickerState();
}

class _PropertyPhotosPickerState extends ConsumerState<PropertyPhotosPicker> {
  var _picking = false;

  Future<void> _add() async {
    if (_picking) return;
    final c = ref.read(publishingControllerProvider.notifier);
    final remaining = PublishingConfig.maxPhotos - ref.read(publishingControllerProvider).draft.photos.length;
    setState(() => _picking = true);
    try {
      c.addPhotos(await ref.read(photoPickerProvider).pick(remainingSlots: remaining));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    final photos = s.draft.photos;
    final canAdd = photos.length < PublishingConfig.maxPhotos;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StepHeader(
        title: 'Add photos',
        subtitle:
            'Up to ${PublishingConfig.maxPhotos} photos (JPG, PNG or WebP, max ${PublishingConfig.maxPhotoBytes ~/ (1024 * 1024)} MB each). The first photo is the cover.',
      ),
      if (s.message != null) MessageBanner(s.message!),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < photos.length; i++)
            _Thumb(
              bytes: photos[i].bytes,
              name: photos[i].name,
              isCover: i == 0,
              failed: s.failedPhotoIds.contains(photos[i].id),
              onRemove: () => c.removePhoto(photos[i].id),
              onMakeCover: i == 0 ? null : () => c.makeCover(photos[i].id),
            ),
          if (canAdd)
            InkWell(
              onTap: _picking ? null : _add,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Center(
                  child: _picking
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                          SizedBox(height: 4),
                          Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ]),
                ),
              ),
            ),
        ],
      ),
      FieldError(s.errors[ListingField.photos]),
      const SizedBox(height: 8),
      Text('${photos.length} / ${PublishingConfig.maxPhotos} photos', style: const TextStyle(color: AppColors.muted)),
    ]);
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.bytes,
    required this.name,
    required this.isCover,
    required this.failed,
    required this.onRemove,
    required this.onMakeCover,
  });

  final Uint8List bytes;
  final String name;
  final bool isCover;
  final bool failed;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 360, gaplessPlayback: true, semanticLabel: name),
          if (failed) Container(color: AppColors.error.withValues(alpha: 0.35), child: const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 30))),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
                child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(backgroundColor: Colors.black54, minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
          if (onMakeCover != null)
            Positioned(
              left: 2,
              bottom: 2,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                onPressed: onMakeCover,
                child: const Text('Make cover'),
              ),
            ),
        ]),
      );
}
