import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import 'widgets.dart';

class NotificationsAdminPage extends StatefulWidget {
  const NotificationsAdminPage({super.key});
  @override
  State<NotificationsAdminPage> createState() => _NotificationsAdminPageState();
}

class _NotificationsAdminPageState extends State<NotificationsAdminPage> {
  final svc = AdminService.instance;
  final title = TextEditingController();
  final body = TextEditingController();
  String target = 'Tous les utilisateurs';
  String type = 'Annonce';

  static const targets = ['Tous les utilisateurs', 'Acheteurs / Locataires', 'Propriétaires', 'Agents'];
  static const types = ['Annonce', 'Nouveauté', 'Maintenance', 'Avertissement'];

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ok = await confirmDialog(
      context,
      'Envoyer la notification ?',
      'Elle sera envoyée à : $target.',
      confirmLabel: 'Envoyer',
      destructive: target == targets.first, // notification globale = action sensible
    );
    if (!ok || !mounted) return;
    guarded(context, () {
      svc.sendNotification(title: title.text.trim(), body: body.text.trim(), target: target, type: type);
      title.clear();
      body.clear();
    }, 'Notification enregistrée');
  }

  @override
  Widget build(BuildContext context) {
    final valid = title.text.trim().isNotEmpty && body.text.trim().isNotEmpty;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionTitle('Nouvelle notification'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 12),
            TextField(controller: body, maxLines: 3, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Message')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: target,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Cible'),
                  items: [for (final t in targets) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => setState(() => target = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [for (final t in types) DropdownMenuItem(value: t, child: Text(t))],
                  onChanged: (v) => setState(() => type = v!),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: valid ? _send : null,
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('L\'envoi push (FCM) sera branché côté backend.', style: TextStyle(color: C.muted, fontSize: 12)),
            ),
          ]),
        ),
      ),
      const SectionTitle('Historique'),
      if (svc.notifications.isEmpty)
        const EmptyState('Aucune notification envoyée')
      else
        Card(
          child: Column(children: [
            for (final n in svc.notifications)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
                title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${n.body}\n${n.target} · ${n.type} · ${fmtDateTime(n.createdAt)}'),
                isThreeLine: true,
              ),
          ]),
        ),
    ]);
  }
}
