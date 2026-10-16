import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import '../data/models.dart';
import 'widgets.dart';

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final s = AdminService.instance;
    final cards = <Widget>[
      StatCard(label: 'Utilisateurs', value: '${s.totalUsers}', icon: Icons.people_outline),
      StatCard(label: 'Annonces publiées', value: '${s.propertyCount(PropertyStatus.published)}', icon: Icons.home_work_outlined, color: C.green),
      StatCard(label: 'En attente', value: '${s.propertyCount(PropertyStatus.pendingReview)}', icon: Icons.hourglass_empty, color: C.amber),
      StatCard(label: 'Signalements ouverts', value: '${s.reportCount(ReportStatus.open)}', icon: Icons.flag_outlined, color: Colors.red.shade700),
      StatCard(label: 'Vérifiés', value: '${s.verifiedUsers}', icon: Icons.verified_outlined, color: C.green),
      StatCard(label: 'Suspendus / bannis', value: '${s.suspendedUsers}', icon: Icons.block, color: C.amber),
      StatCard(label: 'Nouveaux aujourd\'hui', value: '${s.newUsersToday}', icon: Icons.person_add_alt, color: C.secondary),
      StatCard(label: 'Actifs aujourd\'hui', value: '${s.activeToday}', icon: Icons.bolt, color: C.secondary),
    ];
    final urgent = s.urgentItems;
    final activity = s.recentActivity();

    return ListView(padding: const EdgeInsets.all(16), children: [
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: cols == 2 ? 2.0 : 2.6,
          children: cards,
        );
      }),
      const SectionTitle('À traiter en priorité'),
      if (urgent.isEmpty)
        const EmptyState('Rien d\'urgent 🎉')
      else
        Card(
          child: Column(children: [
            for (final it in urgent)
              ListTile(
                leading: StatusChip(it.priority.label, priorityColor(it.priority)),
                title: Text(it.text),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onNavigate(it.text.contains('vérification') ? 4 : (it.text.contains('signalement') ? 3 : 2)),
              ),
          ]),
        ),
      const SectionTitle('Annonces par ville'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            for (final e in (s.listingsByCity().entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(e.key)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: e.value / s.properties.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(6),
                      color: C.navy,
                      backgroundColor: C.line,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
      ),
      const SectionTitle('Activité récente'),
      Card(
        child: Column(children: [
          for (final a in activity)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 9, color: C.secondary),
              title: Text('${a.action} · ${a.targetType} ${a.targetId}'),
              subtitle: Text('${a.adminEmail} — ${fmtDateTime(a.timestamp)}'),
            ),
        ]),
      ),
    ]);
  }
}
