import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/cloudinary_url.dart';

enum PropertyImageSize { thumb, card, gallery }

/// Network image for listings: Cloudinary-optimised, disk-cached, with loading and
/// failure placeholders. Never throws on a missing or invalid URL.
class PropertyImage extends StatelessWidget {
  const PropertyImage({super.key, required this.url, this.size = PropertyImageSize.card, this.fit = BoxFit.cover});

  final String? url;
  final PropertyImageSize size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty || !(raw.startsWith('http://') || raw.startsWith('https://'))) {
      return const _Placeholder();
    }
    final resolved = switch (size) {
      PropertyImageSize.thumb => CloudinaryUrl.thumb(raw),
      PropertyImageSize.card => CloudinaryUrl.card(raw),
      PropertyImageSize.gallery => CloudinaryUrl.gallery(raw),
    };
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const _Placeholder(loading: true),
      errorWidget: (_, _, _) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.loading = false});
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE8F0FE),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.home_work_outlined, size: 40, color: AppColors.primary),
      );
}
