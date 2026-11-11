import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../properties/domain/entities/amenity.dart';
import '../../domain/entities/listing_draft.dart';
import '../../domain/entities/property_type_rules.dart';
import '../../domain/publishing_config.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'publish_widgets.dart';

/// Step 10: what the listing will look like, built from the data really typed.
/// Every block has an "Edit" button that returns straight to the preview.
class PropertyPreview extends ConsumerWidget {
  const PropertyPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    final d = s.draft;
    final type = d.propertyType;
    final tx = d.transactionType;
    final price = ListingValidator.parsePrice(d.priceText);
    final surface = ListingValidator.parseSurface(d.surfaceText);
    final studio = (type?.allowsStudio ?? false) && d.isStudio;
    final location = [d.area.trim(), d.city.trim(), d.governorate ?? '']
        .where((e) => e.isNotEmpty)
        .fold<List<String>>([], (l, e) => l.any((x) => x.toLowerCase() == e.toLowerCase()) ? l : [...l, e])
        .join(', ');

    Widget section(String title, PublishStep step, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              TextButton(onPressed: s.isBusy ? null : () => c.editFromPreview(step), child: const Text('Edit')),
            ]),
            child,
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StepHeader(title: 'Review your listing', subtitle: 'This is how your listing will look once it has been approved.'),
      if (s.message != null) MessageBanner(s.message!),
      if (d.photos.isNotEmpty) _Gallery(photos: d.photos),
      const SizedBox(height: 14),
      Text(d.title.trim(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 6),
      if (price != null && tx != null)
        Text(PriceFormatter.format(price, PublishingConfig.currency, tx),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        if (tx != null) Chip(label: Text(tx.label)),
        if (type != null) Chip(label: Text(type.label)),
        if (d.isNewBuild) const Chip(label: Text('New build')),
      ]),
      section('Location', PublishStep.location, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.place_outlined, size: 18, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(child: Text(location)),
        ]),
        const SizedBox(height: 4),
        Text(d.coordinates == null ? 'No map pin: not shown on the map.' : 'Map pin set.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
      ])),
      section('Details', PublishStep.details, Wrap(spacing: 16, runSpacing: 6, children: [
        if (surface != null) _Fact(Icons.square_foot, '${_trim(surface)} m²'),
        if (studio) const _Fact(Icons.bed_outlined, 'Studio'),
        if ((type?.usesBedrooms ?? false) && !studio) _Fact(Icons.bed_outlined, '${d.bedrooms} bedrooms'),
        if (type?.usesBathrooms ?? false) _Fact(Icons.bathtub_outlined, '${d.bathrooms} bathrooms'),
      ])),
      section('Amenities', PublishStep.amenities,
          d.amenities.isEmpty
              ? const Text('None selected', style: TextStyle(color: AppColors.muted))
              : Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final id in d.amenities.toList()..sort())
                    Chip(label: Text(Amenity.tryParse(id)?.label ?? id)),
                ])),
      section('Description', PublishStep.description, Text(d.description.trim(), style: const TextStyle(height: 1.4))),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('After you submit, our team reviews your listing. It becomes visible to others only once it is approved.')),
        ]),
      ),
    ]);
  }

  static String _trim(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.photos});
  final List<ListingPhoto> photos;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  var _page = 0;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(children: [
            PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Image.memory(widget.photos[i].bytes,
                  fit: BoxFit.cover, cacheWidth: 900, semanticLabel: 'Photo ${i + 1}'),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Text('${_page + 1}/${widget.photos.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ]),
        ),
      );
}
