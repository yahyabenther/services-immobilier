import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'map_strings.dart';

/// Small non-blocking "loading" pill: the map and its markers stay usable.
class MapLoadingPill extends StatelessWidget {
  const MapLoadingPill({super.key});

  @override
  Widget build(BuildContext context) => Material(
        elevation: 3,
        shape: const StadiumBorder(),
        color: Colors.white,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text(MapStrings.loading, style: TextStyle(fontSize: 13, color: AppColors.text)),
          ]),
        ),
      );
}

/// Message over the map (empty area, query failure, no coordinates) with up to two actions.
class MapMessageCard extends StatelessWidget {
  const MapMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: isError ? AppColors.error : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              if (actionLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  if (actionLabel != null) FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  if (secondaryLabel != null) TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
