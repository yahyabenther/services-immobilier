import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../property_discovery/presentation/widgets/property_card.dart';
import '../../providers/favorite_providers.dart';
import '../favorite_feedback.dart';

/// [PropertyCard] already wired to the favorites module: the heart shows the real
/// state and toggles it. Use it anywhere a property card with a heart is needed
/// (Search, Favorites, later Map / Details).
class FavoritePropertyCard extends ConsumerWidget {
  const FavoritePropertyCard({
    super.key,
    required this.property,
    this.width = 250,
    this.distanceKm,
    this.onTap,
  });

  final Property property;
  final double width;
  final double? distanceKm;

  /// Defaults to opening the property details page.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(property.id));

    return PropertyCard(
      property: property,
      width: width,
      distanceKm: distanceKm,
      isFavorite: isFavorite,
      onTap: onTap ?? () => context.push(Routes.propertyDetails(property.id)),
      onFavoriteTap: () => toggleFavoriteWithFeedback(context, ref, property.id),
    );
  }
}