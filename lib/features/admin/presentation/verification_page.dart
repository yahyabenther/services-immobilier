import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import '../data/models.dart';
import 'widgets.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});
  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final svc = AdminService.instance;
  VerificationKind? kind;
  bool pendingOnly = true;

  @override
  Widget build(BuildContext context) {
    final list = svc.verifications.where((v) {
      if (kind != null && v.kind != kind) return false;
      if (pendingOnly && v.status != VerificationStatus.pending) return false;
      return true;
    }).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ChoiceChip(label: const Text('Tous'), selected: kind == null, onSelected: (_) => setState(() => kind = null)),
          for (final k in VerificationKind.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(label: Text(k.label), selected: kind == k, onSelected: (_) => setState(() => kind = k)),
          ],
          const SizedBox(width: 8),
          FilterChip(label: const Text('En attente uniquement'), selected: pendingOnly, onSelected: (v) => setState(() => pendingOnly = v)),
        ]),
      ),
      const SizedBox(height: 12),
      if (list.isEmpty)
        const EmptyState('Aucune demande')
      else
        for (final v in list)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  StatusChip(v.kind.label, C.secondary),
                  const SizedBox(width: 8),
                  StatusChip(v.status.label, verificationColor(v.status)),
                  const Spacer(),
                  Text(fmtDate(v.createdAt), style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                Text(v.subjectName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                DocList(v.documents),
                if (v.reason != null) Text('Motif : ${v.reason}', style: const TextStyle(fontStyle: FontStyle.italic)),
                if (v.reviewedBy != null) Text('Revu par ${v.reviewedBy}', style: const TextStyle(color: C.muted, fontSize: 12)),
                if (v.status == VerificationStatus.pending) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    FilledButton(
                      onPressed: v.documents.any((d) => !d.provided)
                          ? null
                          : () => guarded(context, () => svc.approveVerification(v.id), 'Vérification approuvée'),
                      child: const Text('Approuver'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final r = await askReason(context,
                            title: 'Rejeter la vérification',
                            message: 'Le motif sera envoyé au demandeur.',
                            confirmLabel: 'Rejeter',
                            destructive: true);
                        if (r != null && context.mounted) guarded(context, () => svc.rejectVerification(v.id, r), 'Vérification rejetée');
                      },
                      child: const Text('Rejeter'),
                    ),
                  ]),
                  if (v.documents.any((d) => !d.provided))
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Approbation bloquée : documents manquants.', style: TextStyle(color: C.muted, fontSize: 12)),
                    ),
                ],
              ]),
            ),
          ),
    ]);
  }
}
