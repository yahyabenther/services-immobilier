import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../property_discovery/presentation/providers/property_discovery_providers.dart';
import '../../domain/usecases/get_current_location.dart';
import 'map_strings.dart';

/// Explains WHY location is useful before the system permission prompt (spec §9.2).
Future<bool> showMapLocationExplainer(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(MapStrings.explainTitle),
      content: const Text(MapStrings.explainBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
      ],
    ),
  );
  return ok == true;
}

/// Tells the user why the position is unavailable. The map itself stays usable.
void showLocateFailure(BuildContext context, WidgetRef ref, LocateOutcome outcome) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(MapStrings.locationNotice(outcome)),
      action: outcome == LocateOutcome.deniedForever
          ? SnackBarAction(
              label: 'Settings',
              onPressed: () => ref.read(locationServiceProvider).openSettings(),
            )
          : null,
    ));
}
