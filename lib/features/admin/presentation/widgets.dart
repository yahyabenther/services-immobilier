import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/models.dart';

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String fmtPrice(double p) {
  final s = p.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b TND';
}

Color priorityColor(Priority p) => switch (p) {
      Priority.low => C.muted,
      Priority.medium => C.secondary,
      Priority.high => C.amber,
      Priority.critical => Colors.red.shade700,
    };

Color userStatusColor(UserStatus s) => switch (s) {
      UserStatus.active => C.green,
      UserStatus.suspended => C.amber,
      UserStatus.banned => Colors.red.shade700,
      UserStatus.pendingVerification => C.secondary,
      UserStatus.deleted => C.muted,
    };

Color propertyStatusColor(PropertyStatus s) => switch (s) {
      PropertyStatus.published => C.green,
      PropertyStatus.pendingReview => C.amber,
      PropertyStatus.rejected => Colors.red.shade700,
      PropertyStatus.suspended => C.amber,
      PropertyStatus.removed => C.muted,
      PropertyStatus.draft => C.muted,
      PropertyStatus.expired => C.muted,
    };

Color reportStatusColor(ReportStatus s) => switch (s) {
      ReportStatus.open => Colors.red.shade700,
      ReportStatus.investigating => C.amber,
      ReportStatus.resolved => C.green,
      ReportStatus.rejected => C.muted,
    };

Color verificationColor(VerificationStatus s) => switch (s) {
      VerificationStatus.approved => C.green,
      VerificationStatus.pending => C.amber,
      VerificationStatus.rejected => Colors.red.shade700,
      _ => C.muted,
    };

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? C.navy;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: c.withValues(alpha: .12), child: Icon(icon, color: c, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.text)),
            Text(label, style: const TextStyle(fontSize: 11, color: C.muted), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.navy))),
          ?trailing,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text(text, style: const TextStyle(color: C.muted))),
      );
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: C.muted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
}

class DocList extends StatelessWidget {
  final List<DocumentRef> docs;
  const DocList(this.docs, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final d in docs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.provided ? Icons.check_circle : Icons.cancel,
                  color: d.provided ? C.green : Colors.red.shade700, size: 20),
              title: Text(d.name),
              subtitle: Text(d.provided ? 'Fourni' : 'Manquant / invalide'),
            ),
        ],
      );
}

/// Dialogue de confirmation avec motif (spec §42). Retourne le motif, ou null si annulé.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  bool required = true,
  bool destructive = false,
}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: required ? 'Motif (obligatoire)' : 'Motif (optionnel)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700) : null,
            onPressed: required && ctrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String confirmLabel = 'Confirmer', bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

void snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Exécute une action admin en attrapant les refus de permission.
void guarded(BuildContext context, VoidCallback action, String successMsg) {
  try {
    action();
    snack(context, successMsg);
  } catch (e) {
    snack(context, e.toString());
  }
}
