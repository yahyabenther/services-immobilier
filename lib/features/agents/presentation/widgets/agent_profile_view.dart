import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../property_discovery/presentation/widgets/property_card.dart';
import '../../domain/entities/agent_profile.dart';
import '../providers/agent_providers.dart';
import 'agent_header.dart';
import 'agent_states.dart';

/// Body shared by the public profile (`/agents/:id`) and the owner's own
/// preview (`/agent/profile`). Shows ONLY public data: no identity documents,
/// no verification files, no admin notes, no private account data (spec FR-03).
class AgentProfileView extends ConsumerWidget {
  const AgentProfileView({super.key, required this.profile});

  final AgentProfile profile;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Could not open this link.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final listings = ref.watch(agentPublishedListingsProvider(p.userId));
    final contacts = <Widget>[
      if (p.showPhone && p.phone.isNotEmpty)
        _ContactRow(icon: Icons.phone_outlined, text: p.phone, onTap: () => _open(context, Uri(scheme: 'tel', path: p.phone))),
      if (p.showEmail && p.publicEmail.isNotEmpty)
        _ContactRow(icon: Icons.email_outlined, text: p.publicEmail, onTap: () => _open(context, Uri(scheme: 'mailto', path: p.publicEmail))),
      if ((p.website ?? '').isNotEmpty)
        _ContactRow(
          icon: Icons.language_rounded,
          text: p.website!,
          onTap: () {
            final uri = Uri.tryParse(p.website!);
            if (uri != null) _open(context, uri);
          },
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            AgentHeader(profile: p),
            const SectionTitle('About'),
            Text(p.description, style: const TextStyle(height: 1.45, color: AppColors.text)),
            if (contacts.isNotEmpty) ...[
              const SectionTitle('Contact'),
              AgentCard(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6), child: Column(children: contacts)),
            ],
            const SectionTitle('Location'),
            AgentCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [if ((p.address ?? '').isNotEmpty) p.address!, p.city].join(', '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                if (p.serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Areas served', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final a in p.serviceAreas) Chip(label: Text(a))]),
                ],
                if (p.languages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Languages: ${p.languages.join(', ')}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ]),
            ),
            const SectionTitle('Published listings'),
            listings.when(
              loading: () => const Column(children: [SkeletonBox(height: 110), SizedBox(height: 10), SkeletonBox(height: 110)]),
              error: (_, _) => AgentErrorView(
                message: 'We could not load the listings of this professional.',
                onRetry: () => ref.invalidate(agentPublishedListingsProvider(p.userId)),
              ),
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No published listings yet.', style: TextStyle(color: AppColors.muted)),
                    )
                  : SizedBox(
                      height: 330,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => PropertyCard(
                          property: items[i],
                          onTap: () => context.push(Routes.propertyDetails(items[i].id)),
                        ),
                      ),
                    ),
            ),
            // Reviews are intentionally absent: no review feature exists (spec §5.3).
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      );
}
