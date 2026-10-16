import 'package:flutter/material.dart';

import 'map_strings.dart';

class SearchThisAreaButton extends StatelessWidget {
  const SearchThisAreaButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.search, size: 18),
        label: const Text(MapStrings.searchArea),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      );
}
