import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/property_type_rules.dart';
import '../../domain/publishing_config.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'publish_widgets.dart';

/// Steps 4 + 5 + 6: price, surface, rooms (+ studio / new build flags).
class DetailsStep extends ConsumerWidget {
  const DetailsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    final d = s.draft;
    final type = d.propertyType;
    final rent = d.transactionType == TransactionType.rent;
    final studio = (type?.allowsStudio ?? false) && d.isStudio;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StepHeader(title: 'Price and details'),
      TextFormField(
        initialValue: d.priceText,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        decoration: InputDecoration(
          labelText: rent ? 'Monthly rent' : 'Price',
          suffixText: PublishingConfig.currency,
          errorText: s.errors[ListingField.price],
        ),
        onChanged: c.setPriceText,
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: d.surfaceText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(9)],
        decoration: InputDecoration(labelText: 'Surface', suffixText: 'm²', errorText: s.errors[ListingField.surface]),
        onChanged: c.setSurfaceText,
      ),
      if (type != null && (type.usesBedrooms || type.usesBathrooms)) ...[
        const SizedBox(height: 18),
        if (type.allowsStudio)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is a studio'),
            subtitle: const Text('A studio has no separate bedroom.'),
            value: d.isStudio,
            onChanged: c.setStudio,
          ),
        if (type.usesBedrooms && !studio) ...[
          CounterField(label: 'Bedrooms', value: d.bedrooms, max: PublishingConfig.maxRooms, onChanged: c.setBedrooms, error: s.errors[ListingField.bedrooms]),
          const SizedBox(height: 12),
        ],
        if (type.usesBathrooms)
          CounterField(label: 'Bathrooms', value: d.bathrooms, max: PublishingConfig.maxRooms, onChanged: c.setBathrooms, error: s.errors[ListingField.bathrooms]),
      ] else if (type != null) ...[
        const SizedBox(height: 18),
        Text('Bedrooms and bathrooms do not apply to a ${type.label.toLowerCase()}.', style: const TextStyle(color: Color(0xFF6B7A90))),
      ],
      const SizedBox(height: 10),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('New build'),
        subtitle: const Text('Listed under "New" in search.'),
        value: d.isNewBuild,
        onChanged: c.setNewBuild,
      ),
    ]);
  }
}
