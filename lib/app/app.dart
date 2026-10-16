import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class ImmoFindApp extends ConsumerWidget {
  const ImmoFindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ImmoFind',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
