import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'agent_formatters.dart';

class AgentStatCard extends StatelessWidget {
  const AgentStatCard({super.key, required this.icon, required this.label, required this.value, this.onTap});

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label: $value',
        button: onTap != null,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 10),
                Text(formatCount(value),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ),
        ),
      );
}

/// Two-column responsive grid of stat cards (no fixed-height overflow).
class AgentStatGrid extends StatelessWidget {
  const AgentStatGrid({super.key, required this.cards});

  final List<AgentStatCard> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 520 ? 3 : 2;
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final card in cards) SizedBox(width: w, child: card),
        ]);
      });
}
