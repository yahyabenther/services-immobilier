import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/property_discovery_providers.dart';

/// Looks like a search field but only opens Module 04 (no search engine here).
class DiscoverySearchEntry extends ConsumerWidget {
  const DiscoverySearchEntry({super.key, this.transactionType});

  final TransactionType? transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Rechercher un bien',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(
          Routes.searchWith(transactionType: transactionType, location: ref.read(selectedLocationProvider)),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.navy),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('La Marsa, Gammarth, Hammamet…',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted)),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}
