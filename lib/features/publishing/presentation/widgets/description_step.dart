import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/publishing_config.dart';
import '../../domain/services/listing_validator.dart';
import '../providers/publishing_provider.dart';
import 'publish_widgets.dart';

/// Step 9: title + description.
class DescriptionStep extends ConsumerWidget {
  const DescriptionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(publishingControllerProvider);
    final c = ref.read(publishingControllerProvider.notifier);
    final d = s.draft;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const StepHeader(title: 'Describe your property', subtitle: 'A clear title and a useful description get more answers.'),
      TextFormField(
        initialValue: d.title,
        maxLength: PublishingConfig.titleMax,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: 'Title', hintText: 'e.g. Bright S+2 apartment in La Marsa', errorText: s.errors[ListingField.title]),
        onChanged: c.setTitle,
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: d.description,
        maxLength: PublishingConfig.descriptionMax,
        minLines: 6,
        maxLines: 12,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Description',
          alignLabelWithHint: true,
          hintText: 'Condition, layout, special features, what is nearby...',
          errorText: s.errors[ListingField.description],
        ),
        onChanged: c.setDescription,
      ),
    ]);
  }
}
