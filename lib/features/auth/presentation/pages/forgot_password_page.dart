import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/errors/auth_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: _sent ? _confirmation(context) : _form(context),
    );
  }

  Widget _form(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.lock_reset_rounded, size: 88, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text('Forgot Password?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 10),
            const Text("No worries! Enter your email address and we'll send you a reset link.",
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 26),
            AuthErrorMessage(message: _error),
            AuthTextField(
              controller: _email,
              hint: 'Email Address',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: Validators.email,
              enabled: !_loading,
            ),
            const SizedBox(height: 18),
            AuthButton(label: 'Send Reset Link', loading: _loading, onPressed: _submit),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );

  // Same message whether or not the email exists (no account enumeration).
  Widget _confirmation(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.mark_email_read_outlined, size: 88, color: AppColors.primary),
          const SizedBox(height: 20),
          const Text('Check Your Email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 10),
          Text(
            'If an account exists for ${_email.text.trim()}, a password reset link is on its way.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          AuthButton(
            label: 'Back to Login',
            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.login),
          ),
        ],
      );
}
