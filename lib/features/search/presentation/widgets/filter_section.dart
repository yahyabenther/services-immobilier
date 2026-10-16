import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child, this.hint, this.error});

  final String title;
  final String? hint;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            if (hint != null) Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
      ],
    );
  }
}
