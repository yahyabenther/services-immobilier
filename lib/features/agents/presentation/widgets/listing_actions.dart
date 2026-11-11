import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/agent_failure.dart';
import '../../../properties/domain/entities/property.dart';
import '../providers/agent_providers.dart';
import 'agent_listing_card.dart';
import '../../domain/entities/agent_dashboard_stats.dart';
import '../../domain/services/listing_policy.dart';

/// The status-dependent actions of one listing, wired to the use cases.
/// Shared by the listings page and the listing detail page.
class ListingActions {
  ListingActions._();

  static Future<void> submit(BuildContext context, WidgetRef ref, Property p) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(submitAgentListingProvider)(p);
      messenger.showSnackBar(const SnackBar(content: Text('Listing submitted for review.')));
    } on AgentFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(const AgentFailure(AgentFailureType.unknown).message)));
    }
  }

  static Future<void> withdraw(BuildContext context, WidgetRef ref, Property p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw this listing?'),
        content: Text(
          '"${p.title}" will no longer be visible to users. '
          'You can create a new listing later.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(withdrawAgentListingProvider)(p);
      messenger.showSnackBar(const SnackBar(content: Text('Listing withdrawn.')));
    } on AgentFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(const AgentFailure(AgentFailureType.unknown).message)));
    }
  }

  /// Card with exactly the actions the listing status allows.
  static Widget card(BuildContext context, WidgetRef ref, Property p, {PropertyStats? stats, bool detail = false}) =>
      AgentListingCard(
        property: p,
        stats: stats,
        onOpen: () => detail ? context.push(Routes.propertyDetails(p.id)) : context.push(Routes.agentListing(p.id)),
        onViewPublic: ListingPolicy.canViewPublic(p.status) ? () => context.push(Routes.propertyDetails(p.id)) : null,
        onEdit: ListingPolicy.canEdit(p.status) ? () => context.push(Routes.publishWith(editPropertyId: p.id)) : null,
        onSubmit: ListingPolicy.canSubmit(p.status) ? () => submit(context, ref, p) : null,
        onWithdraw: ListingPolicy.canWithdraw(p.status) ? () => withdraw(context, ref, p) : null,
      );
}
