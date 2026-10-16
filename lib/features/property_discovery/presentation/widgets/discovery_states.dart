import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DiscoveryEmptyState extends StatelessWidget {
  const DiscoveryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _Panel(
        icon: icon,
        iconColor: AppColors.primary,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class DiscoveryErrorState extends StatelessWidget {
  const DiscoveryErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Panel(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.error,
        title: "Couldn't load this section",
        message: message,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: [
        Icon(icon, size: 36, color: iconColor),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
            child: Text(actionLabel!),
          ),
        ],
      ]),
    );
  }
}
