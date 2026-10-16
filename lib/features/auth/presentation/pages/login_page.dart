import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_error_message.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).clearError());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider) is AuthAuthenticating;
    final controller = ref.read(authControllerProvider.notifier);

    return AuthScaffold(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo()),
              const SizedBox(height: 28),
              const Text('Welcome Back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 6),
              const Text('Log in to your account', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 24),
              const AuthErrorMessage(),
              AuthTextField(
                controller: _email,
                hint: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !loading,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                validator: Validators.loginPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !loading,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : () => context.push(Routes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              AuthButton(label: 'Login', loading: loading, onPressed: _submit),
              const OrDivider(),
              GoogleSignInButton(disabled: loading, onPressed: controller.signInWithGoogle),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: loading ? null : () => context.pushReplacement(Routes.register),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
