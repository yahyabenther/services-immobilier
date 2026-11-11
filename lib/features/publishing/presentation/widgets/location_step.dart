import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/tunisia_governorates.dart';
import '../../domain/publishing_config.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'location_pin_picker.dart';
import 'publish_widgets.dart';

/// Step 3: governorate (from the canonical list), city, area, optional pin.
class LocationStep extends ConsumerWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    final d = s.draft;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StepHeader(title: 'Where is it?', subtitle: 'Search and the map rely on an accurate location.'),
      DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: d.governorate,
        isExpanded: true,
        decoration: InputDecoration(labelText: 'Governorate', errorText: s.errors[ListingField.governorate]),
        items: [for (final g in tunisiaGovernorates) DropdownMenuItem(value: g, child: Text(g))],
        onChanged: (v) {
          if (v != null) c.setGovernorate(v);
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: d.city,
        textCapitalization: TextCapitalization.words,
        maxLength: PublishingConfig.cityMax,
        decoration: InputDecoration(labelText: 'City', hintText: 'e.g. La Marsa', counterText: '', errorText: s.errors[ListingField.city]),
        onChanged: c.setCity,
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: d.area,
        textCapitalization: TextCapitalization.words,
        maxLength: PublishingConfig.areaMax,
        decoration: InputDecoration(labelText: 'Area / neighbourhood (optional)', hintText: 'e.g. Gammarth', counterText: '', errorText: s.errors[ListingField.area]),
        onChanged: c.setArea,
      ),
      const SizedBox(height: 22),
      LocationPinPicker(
        governorate: d.governorate,
        coordinates: d.coordinates,
        onChanged: c.setCoordinates,
        error: s.errors[ListingField.coordinates],
      ),
    ]);
  }
}
