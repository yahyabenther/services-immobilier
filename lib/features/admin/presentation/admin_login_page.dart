import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import 'admin_shell.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AdminService.instance.login(_email.text, _password.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const AdminShell()), (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(22), children: [
            const Icon(Icons.admin_panel_settings_outlined, size: 48, color: C.navy),
            const SizedBox(height: 12),
            const Text('Espace administrateur',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.navy)),
            const SizedBox(height: 6),
            const Text('Accès réservé aux administrateurs ImmoFind.', style: TextStyle(color: C.muted)),
            const SizedBox(height: 26),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _hide,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: C.navy, padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.amber.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Mode démo : admin@immofind.tn / Admin#2026\n'
                'À remplacer par Firebase Auth + custom claims avant la production.',
                style: TextStyle(fontSize: 12, color: C.text),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
