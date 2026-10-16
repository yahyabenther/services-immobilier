import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/property_discovery_providers.dart';
import 'discovery_states.dart';
import 'property_card.dart';
import 'property_card_skeleton.dart';

/// Header + horizontal list with its own loading / empty / error / retry states.
/// While a refresh is running, the previous cards stay on screen.
class PropertiesSection extends StatelessWidget {
  const PropertiesSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.data,
    required this.empty,
    required this.onRetry,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final AsyncValue<SectionData> data;
  final Widget empty;
  final VoidCallback onRetry;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final value = data.value; // previous value is kept while refreshing
    final showSeeAll = value != null && !value.hasError && value.items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, subtitle: subtitle, onSeeAll: showSeeAll ? onSeeAll : null),
        const SizedBox(height: 10),
        if (value == null)
          data.hasError
              ? DiscoveryErrorState(message: 'Something went wrong.', onRetry: onRetry)
              : const _SkeletonList()
        else if (value.hasError)
          DiscoveryErrorState(message: value.error!, onRetry: onRetry)
        else if (value.isEmpty)
          empty
        else
          _CardList(items: value.items),
      ],
    );
  }
}

double _listHeight(BuildContext context) {
  final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.4);
  return 282 * scale;
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _listHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const PropertyCardSkeleton(),
        ),
      );
}

class _CardList extends StatelessWidget {
  const _CardList({required this.items});
  final List<Property> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _listHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = items[i];
            return PropertyCard(
              key: ValueKey(p.id), // stable ids as keys
              property: p,
              onTap: () => context.push(Routes.propertyDetails(p.id)),
              // Favorite control stays hidden until Module 07 provides a real toggle.
            );
          },
        ),
      );
}