import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../properties/domain/entities/amenity.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'publish_widgets.dart';

/// Step 7: multi-select. The stored value is `Amenity.id` (the enum name), which
/// is what Search filters on and Details displays.
class AmenitiesStep extends ConsumerWidget {
  const AmenitiesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StepHeader(title: 'Amenities', subtitle: 'Select everything the property offers. You can skip this step.'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in Amenity.values)
          FilterChip(
            label: Text(a.label),
            selected: s.draft.amenities.contains(a.id),
            onSelected: (_) => c.toggleAmenity(a.id),
          ),
      ]),
      FieldError(s.errors[ListingField.amenities]),
    ]);
  }
}
