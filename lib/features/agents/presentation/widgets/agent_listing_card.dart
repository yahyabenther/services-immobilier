import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/agent_dashboard_stats.dart';
import '../../domain/services/listing_policy.dart';
import 'agent_formatters.dart';
import 'agent_states.dart';

/// Status chip: icon + text, never colour alone.
class ListingStatusChip extends StatelessWidget {
  const ListingStatusChip({super.key, required this.status});

  final PropertyStatus status;

  ({Color fg, Color bg, IconData icon}) get _style => switch (status) {
        PropertyStatus.published => (fg: AppColors.success, bg: const Color(0xFFE6F6EE), icon: Icons.check_circle_outline),
        PropertyStatus.pendingReview => (fg: const Color(0xFFB7791F), bg: const Color(0xFFFFF4DB), icon: Icons.hourglass_top_rounded),
        PropertyStatus.rejected => (fg: AppColors.error, bg: const Color(0xFFFDE8E6), icon: Icons.cancel_outlined),
        PropertyStatus.suspended => (fg: AppColors.error, bg: const Color(0xFFFDE8E6), icon: Icons.pause_circle_outline),
        PropertyStatus.draft => (fg: AppColors.muted, bg: const Color(0xFFEEF2F8), icon: Icons.edit_note_rounded),
        PropertyStatus.expired => (fg: AppColors.muted, bg: const Color(0xFFEEF2F8), icon: Icons.schedule_rounded),
        PropertyStatus.removed => (fg: AppColors.muted, bg: const Color(0xFFEEF2F8), icon: Icons.delete_outline),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 13, color: s.fg),
        const SizedBox(width: 4),
        Text(ListingPolicy.statusLabel(status),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.fg)),
      ]),
    );
  }
}

/// One listing in "My professional listings" (spec §5.5): image, title, price,
/// place, status, views / favorites, last update and the actions its status allows.
class AgentListingCard extends StatelessWidget {
  const AgentListingCard({
    super.key,
    required this.property,
    this.stats,
    required this.onOpen,
    this.onViewPublic,
    this.onEdit,
    this.onSubmit,
    this.onWithdraw,
  });

  final Property property;
  final PropertyStats? stats;
  final VoidCallback onOpen;
  final VoidCallback? onViewPublic;
  final VoidCallback? onEdit;
  final VoidCallback? onSubmit;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final views = stats?.views ?? p.views;
    final favorites = stats?.favorites ?? p.favoritesCount;
    final hint = ListingPolicy.statusHint(p.status);
    final actions = <Widget>[
      if (onViewPublic != null) TextButton.icon(onPressed: onViewPublic, icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('View')),
      if (onEdit != null) TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
      if (onSubmit != null)
        TextButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(p.status == PropertyStatus.rejected ? 'Resubmit' : 'Submit'),
        ),
      if (onWithdraw != null)
        TextButton.icon(
          onPressed: onWithdraw,
          icon: const Icon(Icons.archive_outlined, size: 18),
          label: const Text('Withdraw'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
        ),
    ];

    return AgentCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 88, height: 88, child: PropertyImage(url: p.mainImage, size: PropertyImageSize.thumb)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 3),
              Text(PriceFormatter.format(p.price, p.currency, p.transactionType),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 3),
              Text(p.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                ListingStatusChip(status: p.status),
                _Metric(Icons.visibility_outlined, formatCount(views), 'views'),
                _Metric(Icons.favorite_border, formatCount(favorites), 'favorites'),
              ]),
            ]),
          ),
        ]),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
        if (p.updatedAt != null) ...[
          const SizedBox(height: 4),
          Text('Updated ${formatShortDate(p.updatedAt!)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 4, children: actions),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.semantic);

  final IconData icon;
  final String value;
  final String semantic;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value $semantic',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 3),
          Text(value, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      );
}
