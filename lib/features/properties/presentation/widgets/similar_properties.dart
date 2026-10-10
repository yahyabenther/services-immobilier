import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_theme.dart';
import '../../../search/domain/entities/property_summary.dart';
import '../../../search/presentation/widgets/property_result_card.dart'
    show formatPrice;
import '../../providers/property_providers.dart';

class SimilarProperties extends ConsumerWidget {
  const SimilarProperties({
    super.key,
    required this.propertyId,
    required this.onTap,
  });

  final String propertyId;
  final void Function(PropertySummary) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(similarPropertiesProvider(propertyId));
    final items = async.hasValue ? async.value! : const <PropertySummary>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 22, bottom: 10),
          child: Text(
            'Biens similaires',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: C.text,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _SimilarCard(
              property: items[i],
              onTap: () => onTap(items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({required this.property, required this.onTap});
  final PropertySummary property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: p.imageUrls.isEmpty
                  ? Container(
                      color: const Color(0xFFEAF1F5),
                      child: const Icon(Icons.home_work_outlined, color: C.muted),
                    )
                  : Image.network(
                      p.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFEAF1F5),
                        child:
                            const Icon(Icons.home_work_outlined, color: C.muted),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatPrice(p.price)} TND',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: C.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: C.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}