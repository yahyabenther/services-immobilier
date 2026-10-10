import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_theme.dart';
import '../../../search/domain/entities/search_enums.dart';
import '../../../search/presentation/widgets/property_result_card.dart'
    show formatPrice;
import '../../../search/presentation/widgets/search_labels.dart';
import '../../domain/entities/property.dart';
import '../../providers/property_providers.dart';
import '../widgets/amenities_section.dart';
import '../widgets/key_facts_row.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/similar_properties.dart';
import '../widgets/verification_badge.dart';

void _comingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what: bientôt disponible')),
  );
}

class PropertyDetailsPage extends ConsumerWidget {
  const PropertyDetailsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(propertyDetailsProvider(propertyId));
    final property = async.hasValue ? async.value : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Détails du bien')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          icon: Icons.error_outline,
          title: 'Impossible de charger le bien',
          subtitle: '$e',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(propertyDetailsProvider(propertyId)),
        ),
        data: (p) => p == null
            ? _Message(
                icon: Icons.search_off_rounded,
                title: 'Bien introuvable',
                subtitle: "Cette annonce n'existe plus ou a été retirée.",
                actionLabel: 'Retour',
                onAction: () => Navigator.of(context).pop(),
              )
            : _Content(property: p),
      ),
      bottomNavigationBar: property == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _comingSoon(context, 'Favoris'),
                      icon: const Icon(Icons.favorite_border_rounded),
                      label: const Text('Favori'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: C.navy),
                        onPressed: () => _comingSoon(context, 'Messagerie'),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Contacter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final isRent = p.transactionType == TransactionType.rent;
    final location = [if (p.area != null) p.area, p.city, p.governorate]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PhotoGallery(imageUrls: p.imageUrls),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Tag(p.transactionType.label),
                  const SizedBox(width: 6),
                  _Tag(p.propertyType.label),
                  const Spacer(),
                  VerificationBadge(status: p.verificationStatus),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${formatPrice(p.price)} ${p.currency}${isRent ? ' / mois' : ''}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: C.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: C.text,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 15, color: C.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: C.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KeyFactsRow(property: p),
              const _SectionTitle('Description'),
              Text(
                p.description.isEmpty ? 'Aucune description.' : p.description,
                style: const TextStyle(fontSize: 13, height: 1.5, color: C.text),
              ),
              if (p.amenities.isNotEmpty) ...[
                const _SectionTitle('Prestations & commodités'),
                AmenitiesSection(amenities: p.amenities),
              ],
              const _SectionTitle('Localisation'),
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 32, color: C.muted),
                    SizedBox(height: 6),
                    Text(
                      'La carte sera disponible bientôt',
                      style: TextStyle(fontSize: 11, color: C.muted),
                    ),
                  ],
                ),
              ),
              SimilarProperties(
                propertyId: p.id,
                onTap: (s) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsPage(propertyId: s.id),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => _comingSoon(context, 'Signalement'),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Signaler cette annonce'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: C.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: C.text,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: C.muted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: C.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.navy),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}