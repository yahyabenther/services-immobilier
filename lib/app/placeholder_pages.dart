import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/property_seeder.dart';
import '../features/auth/providers/auth_provider.dart';
import 'routes.dart';

/// Stand-in for a module that is not built yet. It also prints the context it
/// received (route params), which proves Home passes the right data on.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.module, this.params = const {}});

  final String title;
  final String module;
  final Map<String, String> params;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_rounded, size: 56),
            const SizedBox(height: 12),
            Text('$title arrives with $module', textAlign: TextAlign.center),
            if (params.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Received context:', style: TextStyle(fontWeight: FontWeight.w700)),
              for (final e in params.entries) Text('${e.key} = ${e.value}'),
            ],
          ]),
        ),
      ),
    );
  }
}

class AdminPlaceholderPage extends ConsumerWidget {
  const AdminPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Welcome, ${user?.name ?? user?.email ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go(Routes.home), child: const Text('Open Home')),
            const SizedBox(height: 10),
            if (kDebugMode) ...[
              OutlinedButton(
                onPressed: () => _run(context, () => PropertySeeder(ref.read(firestoreProvider)).seed(), 'Sample listings added'),
                child: const Text('DEBUG: seed sample listings'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _run(context, () => PropertySeeder(ref.read(firestoreProvider)).clear(), 'Sample listings removed'),
                child: const Text('DEBUG: remove sample listings'),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, Future<int> Function() job, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await job();
      messenger.showSnackBar(SnackBar(content: Text('$done ($n)')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
