import 'package:flutter/material.dart';

/// Zoom in / zoom out / my location.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    this.isLocating = false,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      FloatingActionButton.small(
        heroTag: null,
        tooltip: 'Zoom in',
        onPressed: onZoomIn,
        child: const Icon(Icons.add),
      ),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: null,
        tooltip: 'Zoom out',
        onPressed: onZoomOut,
        child: const Icon(Icons.remove),
      ),
      const SizedBox(height: 8),
      FloatingActionButton.small(
        heroTag: null,
        tooltip: 'My location',
        onPressed: isLocating ? null : onMyLocation,
        child: isLocating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.my_location),
      ),
    ]);
  }
}
