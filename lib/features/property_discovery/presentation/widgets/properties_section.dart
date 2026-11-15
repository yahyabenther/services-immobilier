import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/property_discovery_providers.dart';
import 'darna_property_cards.dart';
import 'discovery_states.dart';
import 'property_card_skeleton.dart';

enum PropertiesLayout { featured, list }

/// Header + list with its own loading / empty / error / retry states.
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
    this.layout = PropertiesLayout.featured,
    this.seeAllLabel = 'Explorer',
  });

  final String title;
  final String? subtitle;
  final AsyncValue<SectionData> data;
  final Widget empty;
  final VoidCallback onRetry;
  final VoidCallback? onSeeAll;
  final PropertiesLayout layout;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final value = data.value; // previous value is kept while refreshing
    final showSeeAll = value != null && !value.hasError && value.items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
          onSeeAll: showSeeAll ? onSeeAll : null,
          seeAllLabel: seeAllLabel,
        ),
        const SizedBox(height: 8),
        if (value == null)
          data.hasError
              ? DiscoveryErrorState(message: 'Une erreur est survenue.', onRetry: onRetry)
              : (layout == PropertiesLayout.featured ? const _FeaturedSkeleton() : const _RowSkeleton())
        else if (value.hasError)
          DiscoveryErrorState(message: value.error!, onRetry: onRetry)
        else if (value.isEmpty)
          empty
        else if (layout == PropertiesLayout.featured)
          _FeaturedList(items: value.items)
        else
          _RowList(items: value.items),
      ],
    );
  }
}

double _featuredHeight(BuildContext context) {
  final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.4);
  return 288 * scale;
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _featuredHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const PropertyCardSkeleton(width: 290),
        ),
      );
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFFE9EEF6);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: grey, borderRadius: BorderRadius.circular(6)),
        );
    return Column(children: [
      for (var i = 0; i < 3; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(
              width: 88,
              height: 92,
              decoration: BoxDecoration(color: grey, borderRadius: BorderRadius.circular(14)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bar(110, 16),
              const SizedBox(height: 10),
              bar(150, 14),
              const SizedBox(height: 10),
              bar(100, 12),
            ]),
          ]),
        ),
    ]);
  }
}

class _FeaturedList extends StatelessWidget {
  const _FeaturedList({required this.items});
  final List<Property> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _featuredHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = items[i];
            return FeaturedPropertyCard(
              key: ValueKey(p.id), // stable ids as keys
              property: p,
              onTap: () => context.push(Routes.propertyDetails(p.id)),
              // Favorite control stays hidden until Module 07 provides a real toggle.
            );
          },
        ),
      );
}

class _RowList extends StatelessWidget {
  const _RowList({required this.items});
  final List<Property> items;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PropertyRowCard(
              key: ValueKey(p.id),
              property: p,
              onTap: () => context.push(Routes.propertyDetails(p.id)),
            ),
          ),
      ]);
}
