import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/property_image.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/listing_actions.dart';
import '../../providers/my_listings_providers.dart';

/// Module 09 — owner / agent dashboard of their own listings, grouped by status.
class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final all = listings.value ?? const <Property>[];

    return DefaultTabController(
      length: myListingsTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final s in myListingsTabs)
                Tab(text: '${_label(s)} (${all.where((p) => p.status == s).length})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.publish),
          icon: const Icon(Icons.add),
          label: const Text('New listing'),
        ),
        body: listings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(
            icon: Icons.cloud_off_outlined,
            text: 'Something went wrong.\nPlease try again.',
            action: TextButton(
              onPressed: () => ref.invalidate(myListingsProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (items) => TabBarView(
            children: [
              for (final s in myListingsTabs)
                _ListingsTab(status: s, items: items.where((p) => p.status == s).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(PropertyStatus s) => switch (s) {
      PropertyStatus.draft => 'Drafts',
      PropertyStatus.pendingReview => 'Pending',
      PropertyStatus.published => 'Published',
      PropertyStatus.rejected => 'Rejected',
      PropertyStatus.suspended => 'Suspended',
      PropertyStatus.removed => 'Withdrawn',
      PropertyStatus.expired => 'Expired',
    };

String _emptyText(PropertyStatus s) => switch (s) {
      PropertyStatus.draft => 'You have no drafts.',
      PropertyStatus.pendingReview => 'No listing is waiting for review.',
      PropertyStatus.published => 'You have no published listings.',
      PropertyStatus.rejected => 'No rejected listings.',
      PropertyStatus.suspended => 'No suspended listings.',
      PropertyStatus.removed => 'No withdrawn listings.',
      PropertyStatus.expired => 'No expired listings.',
    };

class _ListingsTab extends StatelessWidget {
  const _ListingsTab({required this.status, required this.items});

  final PropertyStatus status;
  final List<Property> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Message(icon: Icons.inbox_outlined, text: _emptyText(status));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // room for the FAB
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ListingCard(property: items[i]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: p.isPublic ? () => context.push(Routes.propertyDetails(p.id)) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: PropertyImage(url: p.mainImage, size: PropertyImageSize.thumb),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PriceFormatter.format(p.price, p.currency, p.transactionType),
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                    Text(p.locationLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(children: [
                      _Stat(Icons.visibility_outlined, p.views),
                      const SizedBox(width: 12),
                      _Stat(Icons.favorite_border, p.favoritesCount),
                    ]),
                  ],
                ),
              ),
            ),
            _ActionsMenu(property: p),
          ],
        ),
      ),
    );
  }
}

enum _Action { view, edit, submit, withdraw, toDraft, delete }

class _ActionsMenu extends ConsumerWidget {
  const _ActionsMenu({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ownerTransitions(property.status);
    return PopupMenuButton<_Action>(
      onSelected: (a) => _handle(context, ref, a),
      itemBuilder: (_) => [
        if (property.isPublic) const PopupMenuItem(value: _Action.view, child: Text('View listing')),
        const PopupMenuItem(value: _Action.edit, enabled: false, child: Text('Edit (coming with Module 08)')),
        if (next.contains(PropertyStatus.pendingReview))
          const PopupMenuItem(value: _Action.submit, child: Text('Submit for review')),
        // Drafts are deleted, not withdrawn.
        if (next.contains(PropertyStatus.removed) && property.status != PropertyStatus.draft)
          const PopupMenuItem(value: _Action.withdraw, child: Text('Withdraw')),
        if (next.contains(PropertyStatus.draft))
          const PopupMenuItem(value: _Action.toDraft, child: Text('Back to draft')),
        if (ownerCanDelete(property.status))
          const PopupMenuItem(value: _Action.delete, child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Future<void> _handle(BuildContext context, WidgetRef ref, _Action a) async {
    final repo = ref.read(myListingsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final id = property.id;
    try {
      switch (a) {
        case _Action.view:
          context.push(Routes.propertyDetails(id));
          return;
        case _Action.edit:
          return;
        case _Action.submit:
          await repo.setStatus(id, PropertyStatus.pendingReview);
        case _Action.withdraw:
          if (!await _confirm(context, 'Withdraw this listing?', 'It will no longer be visible to other users.')) return;
          await repo.setStatus(id, PropertyStatus.removed);
        case _Action.toDraft:
          await repo.setStatus(id, PropertyStatus.draft);
        case _Action.delete:
          if (!await _confirm(context, 'Delete this listing?', 'This cannot be undone.')) return;
          await repo.delete(id);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Listing updated')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
    }
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    ) ??
    false;

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value);

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text('$value', style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            ?action,
          ]),
        ),
      );
}