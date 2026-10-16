import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import 'widgets.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});
  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final svc = AdminService.instance;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final logs = svc.auditLogs.where((l) =>
        q.isEmpty ||
        l.action.toLowerCase().contains(q) ||
        l.targetId.toLowerCase().contains(q) ||
        l.adminEmail.toLowerCase().contains(q)).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(hintText: 'Filtrer : action, cible, admin', prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 12),
      if (logs.isEmpty)
        const EmptyState('Aucune entrée')
      else
        Card(
          child: Column(children: [
            for (final l in logs)
              ListTile(
                leading: const Icon(Icons.history, color: C.secondary),
                title: Text('${l.action} · ${l.targetType} ${l.targetId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([
                  '${l.adminEmail} — ${fmtDateTime(l.timestamp)}',
                  if (l.previousValue != null || l.newValue != null) '${l.previousValue ?? '—'} → ${l.newValue ?? '—'}',
                  if (l.reason != null) 'Motif : ${l.reason}',
                ].join('\n')),
                isThreeLine: l.reason != null || l.previousValue != null,
              ),
          ]),
        ),
    ]);
  }
}
