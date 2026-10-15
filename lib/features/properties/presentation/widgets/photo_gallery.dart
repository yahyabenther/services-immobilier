import 'package:flutter/material.dart';

import '../../../../core/widgets/property_image.dart';

/// Swipeable photo gallery with an image counter. Tapping opens a full-screen
/// viewer. Missing / failed images fall back to a placeholder (via
/// [PropertyImage]) so the layout never collapses.
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.images, this.height = 280});

  final List<String> images;
  final double height;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  int _index = 0;

  void _openFullScreen() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _FullScreenGallery(images: widget.images, initialIndex: _index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: images.isEmpty
          ? const PropertyImage(url: null)
          : Stack(fit: StackFit.expand, children: [
              Semantics(
                button: true,
                label: 'Open photo ${_index + 1} of ${images.length} full screen',
                child: GestureDetector(
                  onTap: _openFullScreen,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => PropertyImage(url: images[i], size: PropertyImageSize.gallery),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Text('${_index + 1}/${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: PropertyImage(url: widget.images[i], size: PropertyImageSize.gallery, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

