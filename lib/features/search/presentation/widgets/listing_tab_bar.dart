import 'package:flutter/material.dart';

import '../../domain/entities/search_enums.dart';
import 'search_labels.dart';

/// All / Buy / Rent / New. Selecting a tab changes the real filter model
/// (not just a visual state) and the parent re-runs the search.
class ListingTabBar extends StatelessWidget {
  const ListingTabBar({super.key, required this.selected, required this.onSelected});

  final ListingTab selected;
  final ValueChanged<ListingTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        for (final t in ListingTab.values) ...[
          ChoiceChip(
            label: Text(t.label),
            selected: selected == t,
            showCheckmark: false,
            onSelected: (_) => onSelected(t),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }
}
