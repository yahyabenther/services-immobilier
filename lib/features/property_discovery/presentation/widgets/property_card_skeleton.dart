import 'package:flutter/material.dart';

class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key, this.width = 250});
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: const Color(0xFFE9EEF6), borderRadius: BorderRadius.circular(6)),
        );
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 16 / 10, child: Container(color: const Color(0xFFE9EEF6))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bar(110, 16),
              const SizedBox(height: 8),
              bar(170, 14),
              const SizedBox(height: 8),
              bar(120, 12),
            ]),
          ),
        ]),
      ),
    );
  }
}
