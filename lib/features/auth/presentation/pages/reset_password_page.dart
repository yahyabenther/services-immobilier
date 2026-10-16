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
import '../widgets/password_field.dart';

/// Opened from the reset email via `/reset-password?oobCode=...`
/// (requires the deep-link / action-URL setup described in the README).
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.code});

  final String? code;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
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
      await ref
          .read(authControllerProvider.notifier)
          .confirmPasswordReset(code: widget.code!, newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated. You can log in now.')));
      context.go(Routes.login);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = widget.code != null && widget.code!.isNotEmpty;
    final rules = Validators.passwordRules(_password.text);

    return AuthScaffold(
      child: !hasCode
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const AuthErrorMessage(
                    message: 'This reset link is invalid or has expired. Please request a new one.'),
                AuthButton(label: 'Request a new link', onPressed: () => context.go(Routes.forgotPassword)),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.verified_user_outlined, size: 88, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text('Set New Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 10),
                  const Text('Choose a strong password to keep your account safe.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  AuthErrorMessage(message: _error),
                  PasswordField(
                    controller: _password,
                    hint: 'New Password',
                    validator: Validators.password,
                    newPassword: true,
                    onChanged: (_) => setState(() {}),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 12),
                  PasswordField(
                    controller: _confirm,
                    hint: 'Confirm Password',
                    validator: (v) => Validators.confirmPassword(v, _password.text),
                    newPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 16),
                  _Rule('At least ${Validators.minPasswordLength} characters', rules.minLength),
                  _Rule('One uppercase letter', rules.uppercase),
                  _Rule('One number', rules.number),
                  const SizedBox(height: 20),
                  AuthButton(label: 'Reset Password', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text, this.ok);
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18, color: ok ? AppColors.success : AppColors.muted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      );
}
