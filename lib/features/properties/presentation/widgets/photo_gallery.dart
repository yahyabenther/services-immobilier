import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.imageUrls, this.height = 280});

  final List<String> imageUrls;
  final double height;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: urls.isEmpty
          ? const _Placeholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _Placeholder(),
                  ),
                ),
                if (urls.length > 1)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1}/${urls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF1F5),
      alignment: Alignment.center,
      child: const Icon(Icons.home_work_outlined, size: 56, color: C.muted),
    );
  }
}