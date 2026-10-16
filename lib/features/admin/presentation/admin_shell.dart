import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import 'admin_login_page.dart';
import 'audit_logs_page.dart';
import 'content_page.dart';
import 'dashboard_page.dart';
import 'notifications_admin_page.dart';
import 'properties_page.dart';
import 'reports_page.dart';
import 'users_page.dart';
import 'verification_page.dart';

class _Section {
  final String label;
  final IconData icon;
  final Widget page;
  const _Section(this.label, this.icon, this.page);
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final svc = AdminService.instance;
  int index = 0;

  late final List<_Section> sections = [
    _Section('Tableau de bord', Icons.dashboard_outlined, DashboardPage(onNavigate: (i) => setState(() => index = i))),
    const _Section('Utilisateurs', Icons.people_outline, UsersPage()),
    const _Section('Annonces', Icons.home_work_outlined, PropertiesPage()),
    const _Section('Signalements', Icons.flag_outlined, ReportsPage()),
    const _Section('Vérification', Icons.verified_user_outlined, VerificationPage()),
    const _Section('Notifications', Icons.notifications_none, NotificationsAdminPage()),
    const _Section('Contenu', Icons.category_outlined, ContentPage()),
    const _Section('Journal d\'audit', Icons.history, AuditLogsPage()),
  ];

  Future<void> _logout() async {
    svc.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const AdminLoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Garde d'accès : sans session admin, retour au login.
    if (!svc.isAuthenticated) return const AdminLoginPage();

    final wide = MediaQuery.of(context).size.width >= 900;
    final body = ListenableBuilder(
      listenable: svc,
      builder: (_, _) => sections[index].page,
    );

    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            extended: true,
            selectedIndex: index,
            backgroundColor: Colors.white,
            onDestinationSelected: (i) => setState(() => index = i),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('ImmoFind Admin', style: TextStyle(fontWeight: FontWeight.w900, color: C.navy, fontSize: 17)),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Déconnexion')),
                ),
              ),
            ),
            destinations: [
              for (final s in sections)
                NavigationRailDestination(icon: Icon(s.icon), label: Text(s.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sections[index].label, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(children: [
            ListTile(
              title: const Text('ImmoFind Admin', style: TextStyle(fontWeight: FontWeight.w900, color: C.navy, fontSize: 18)),
              subtitle: Text(svc.admin?.email ?? ''),
            ),
            const Divider(),
            Expanded(
              child: ListView(children: [
                for (var i = 0; i < sections.length; i++)
                  ListTile(
                    leading: Icon(sections[i].icon),
                    title: Text(sections[i].label),
                    selected: i == index,
                    onTap: () {
                      setState(() => index = i);
                      Navigator.pop(context);
                    },
                  ),
              ]),
            ),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Déconnexion'), onTap: _logout),
          ]),
        ),
      ),
      body: body,
    );
  }
}
