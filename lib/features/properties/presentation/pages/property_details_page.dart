import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/property_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../property_discovery/domain/entities/discovery_location.dart';
import '../../domain/entities/property.dart';
import '../../providers/property_providers.dart';
import '../widgets/amenities_section.dart';
import '../widgets/expandable_description.dart';
import '../widgets/key_facts_row.dart';
import '../widgets/owner_card.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/similar_properties.dart';
import '../widgets/verification_badge.dart';

/// Integration flags for modules that do not exist yet. While a flag is false
/// the action is NOT shown as working (spec §8.12-8.14): Contact is disabled
/// with an honest caption, Favorite and Report are hidden.
class PropertyActionsConfig {
  const PropertyActionsConfig._();

  static const messagingEnabled = false; // Module 09
  static const favoritesEnabled = false; // Module 07
  static const reportsEnabled = false; // Module 13
}

/// Module 05. Always loads the authoritative record by stable id.
class PropertyDetailsPage extends ConsumerWidget {
  const PropertyDetailsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(propertyDetailsProvider(propertyId));
    final property = load.value?.property;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Property details')),
      body: load.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _StateMessage(
          message: const PropertyFailure(PropertyFailureType.unknown).message,
          onRetry: () => ref.invalidate(propertyDetailsProvider(propertyId)),
        ),
        data: (result) {
          final p = result.property;
          if (p == null) {
            final type = result.failure!.type;
            final retryable = type == PropertyFailureType.network || type == PropertyFailureType.unknown;
            return _StateMessage(
              message: result.failure!.message,
              onRetry: retryable ? () => ref.invalidate(propertyDetailsProvider(propertyId)) : null,
              onBack: retryable ? null : () => context.canPop() ? context.pop() : context.go(Routes.home),
            );
          }
          return _Content(property: p);
        },
      ),
      bottomNavigationBar: property == null ? null : const _ActionBar(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            PhotoGallery(images: p.images),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  _Tag(p.transactionType == TransactionType.rent ? 'For rent' : 'For sale'),
                  if (p.isNewBuild) const _Tag('New build'),
                  VerificationBadge(status: p.verificationStatus),
                ]),
                const SizedBox(height: 12),
                Text(
                  PriceFormatter.format(p.price, p.currency, p.transactionType),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(child: Text(p.locationLabel, style: const TextStyle(color: AppColors.muted))),
                ]),
                const SizedBox(height: 18),
                KeyFactsRow(property: p),
                if (p.ownerName != null) ...[
                  const _SectionTitle('Listed by'),
                  OwnerCard(name: p.ownerName!, role: p.ownerRole),
                ],
                const _SectionTitle('Description'),
                ExpandableDescription(text: p.description),
                if (p.amenities.isNotEmpty) ...[
                  const _SectionTitle('Amenities'),
                  AmenitiesSection(amenityIds: p.amenities),
                ],
                const _SectionTitle('Location'),
                _LocationCard(property: p),
                SimilarProperties(propertyId: p.id),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Textual hierarchy always; a map entry only when valid coordinates exist.
/// Coordinates are never printed, and no fake map is drawn.
class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final hierarchy = <String>[
      if (p.area != null) p.area!,
      if (p.city != null) p.city!,
      p.governorate,
    ].join(' › ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(hierarchy, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        if (p.hasCoordinates)
          OutlinedButton.icon(
            onPressed: () => context.go(Routes.mapWith(
              location: DiscoveryLocation.device(latitude: p.latitude!, longitude: p.longitude!),
            )),
            icon: const Icon(Icons.map_outlined),
            label: const Text('View on map'),
          )
        else
          const Text('The exact location was not provided for this listing.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    // Nothing to show once every integration is ready and wired elsewhere.
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // TODO(Module 09): open / create the conversation for this property.
              onPressed: PropertyActionsConfig.messagingEnabled ? () {} : null,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Contact the advertiser'),
            ),
          ),
          if (!PropertyActionsConfig.messagingEnabled)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Messaging is not available yet.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.onRetry, this.onBack});

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.home_work_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (onRetry != null) FilledButton(onPressed: onRetry, child: const Text('Try again')),
            if (onBack != null) FilledButton(onPressed: onBack, child: const Text('Go back')),
          ]),
        ),
      );
}
