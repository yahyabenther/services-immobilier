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

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).clearError());
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          phone: Validators.normalizePhone(_phone.text),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider) is AuthAuthenticating;

    return AuthScaffold(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 48)),
              const SizedBox(height: 20),
              const Text('Create Your Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 6),
              const Text('Join ImmoFind and start exploring amazing properties today.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 22),
              const AuthErrorMessage(),
              AuthTextField(
                controller: _name,
                hint: 'Full Name',
                icon: Icons.person_outline,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
                enabled: !loading,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _email,
                hint: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                enabled: !loading,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _phone,
                hint: 'Phone Number (e.g. 22 123 456)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: Validators.phone,
                enabled: !loading,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                validator: Validators.password,
                newPassword: true,
                enabled: !loading,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                hint: 'Confirm Password',
                validator: (v) => Validators.confirmPassword(v, _password.text),
                newPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !loading,
              ),
              const SizedBox(height: 20),
              AuthButton(label: 'Create Account', loading: loading, onPressed: _submit),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?', style: TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: loading ? null : () => context.pushReplacement(Routes.login),
                    child: const Text('Log In'),
                  ),
                ],
              ),
              const OrDivider(),
              GoogleSignInButton(
                disabled: loading,
                onPressed: ref.read(authControllerProvider.notifier).signInWithGoogle,
              ),
              const SizedBox(height: 16),
              const Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
