import 'package:flutter/material.dart';

import '../../../../core/widgets/app_logo.dart';

/// Shown while the auth state is being read at startup (AuthState.initializing).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 72),
              SizedBox(height: 32),
              SizedBox(height: 26, width: 26, child: CircularProgressIndicator(strokeWidth: 2.6)),
            ],
          ),
        ),
      );
}
