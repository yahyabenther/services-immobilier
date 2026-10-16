import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import '../data/models.dart';
import 'properties_page.dart';
import 'users_page.dart';
import 'widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final svc = AdminService.instance;
  ReportStatus status = ReportStatus.open;

  @override
  Widget build(BuildContext context) {
    final list = svc.reports.where((r) => r.status == status).toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return ListView(padding: const EdgeInsets.all(16), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final s in ReportStatus.values) ...[
            ChoiceChip(
              label: Text('${s.label} (${svc.reportCount(s)})'),
              selected: status == s,
              onSelected: (_) => setState(() => status = s),
            ),
            const SizedBox(width: 8),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      if (list.isEmpty)
        const EmptyState('Aucun signalement')
      else
        for (final r in list) _ReportCard(report: r),
    ]);
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  const _ReportCard({required this.report});

  void _openTarget(BuildContext context) {
    final r = report;
    if (r.targetType == TargetType.property) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyReviewPage(propertyId: r.targetId)));
    } else if (r.targetType == TargetType.user || r.targetType == TargetType.agent) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsPage(userId: r.targetId)));
    } else {
      snack(context, 'La consultation des messages sera disponible avec la messagerie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = AdminService.instance;
    final r = report;
    final active = r.status == ReportStatus.open || r.status == ReportStatus.investigating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StatusChip(r.priority.label, priorityColor(r.priority)),
            const SizedBox(width: 8),
            StatusChip(r.status.label, reportStatusColor(r.status)),
            const Spacer(),
            Text(r.id, style: const TextStyle(color: C.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text('${r.targetType.label} : ${r.targetLabel}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Motif : ${r.reason}', style: const TextStyle(color: C.secondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(r.description),
          const SizedBox(height: 6),
          Text('Signalé par ${r.reporterName} · ${fmtDateTime(r.createdAt)}', style: const TextStyle(color: C.muted, fontSize: 12)),
          if (r.assignedTo != null) Text('Assigné à ${r.assignedTo}', style: const TextStyle(color: C.muted, fontSize: 12)),
          if (r.resolution != null) ...[
            const SizedBox(height: 6),
            Text('Résolution : ${r.resolution}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: () => _openTarget(context), child: const Text('Voir la cible')),
            if (r.status == ReportStatus.open)
              FilledButton(
                onPressed: () => guarded(context, () => svc.startInvestigation(r.id), 'Enquête démarrée'),
                child: const Text('Enquêter'),
              ),
            if (active) ...[
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: C.green),
                onPressed: () async {
                  final res = await askReason(context,
                      title: 'Résoudre le signalement',
                      message: 'Décrivez l\'action prise (violation confirmée).',
                      confirmLabel: 'Résoudre');
                  if (res != null && context.mounted) guarded(context, () => svc.resolveReport(r.id, res), 'Signalement résolu');
                },
                child: const Text('Violation confirmée'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final res = await askReason(context,
                      title: 'Rejeter le signalement',
                      message: 'Aucune violation constatée : indiquez le motif.',
                      confirmLabel: 'Rejeter');
                  if (res != null && context.mounted) guarded(context, () => svc.rejectReport(r.id, res), 'Signalement rejeté');
                },
                child: const Text('Aucune violation'),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}
