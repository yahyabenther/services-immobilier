import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Title + helper text at the top of every wizard screen.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: AppColors.muted, height: 1.35)),
          ],
        ]),
      );
}

/// Small red message under a group of choices (fields use their own errorText).
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(message!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
        );
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({super.key, required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 2 : 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.muted),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.text,
                    )),
              ),
            ]),
          ),
        ),
      );
}

/// `- 3 +` control for bedrooms / bathrooms.
class CounterField extends StatelessWidget {
  const CounterField({super.key, required this.label, required this.value, required this.onChanged, this.error, this.max = 20});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? error;
  final int max;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: error == null ? AppColors.line : AppColors.error),
          ),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            IconButton(
              tooltip: 'Remove one $label',
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            IconButton(
              tooltip: 'Add one $label',
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ]),
        ),
        FieldError(error),
      ]);
}

/// Red / neutral banner used for submission failures and photo problems.
class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.text, height: 1.35))),
        ]),
      );
}
