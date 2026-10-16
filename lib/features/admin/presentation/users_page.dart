import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import '../data/models.dart';
import 'widgets.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final svc = AdminService.instance;
  String query = '';
  UserRole? role;
  UserStatus? status;
  VerificationStatus? verification;

  List<AppUser> get filtered {
    final q = query.trim().toLowerCase();
    return svc.users.where((u) {
      if (role != null && u.role != role) return false;
      if (status != null && u.status != status) return false;
      if (verification != null && u.verification != verification) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.id.toLowerCase() == q;
    }).toList();
  }

  Widget _filter<T>(String label, T? value, List<T> items, String Function(T) name, ValueChanged<T?> onChanged) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tous')),
          for (final i in items) DropdownMenuItem(value: i, child: Text(name(i), overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
            hintText: 'Rechercher : nom, email, téléphone, ID', prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _filter<UserRole>('Rôle', role, UserRole.values, (r) => r.label, (v) => setState(() => role = v)),
        _filter<UserStatus>('Statut', status, UserStatus.values, (s) => s.label, (v) => setState(() => status = v)),
        _filter<VerificationStatus>('Vérification', verification, VerificationStatus.values, (s) => s.label,
            (v) => setState(() => verification = v)),
      ]),
      const SizedBox(height: 8),
      Text('${list.length} utilisateur(s)', style: const TextStyle(color: C.muted)),
      const SizedBox(height: 8),
      if (list.isEmpty)
        const EmptyState('Aucun utilisateur trouvé')
      else
        Card(
          child: Column(children: [
            for (final u in list)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: C.navy.withValues(alpha: .1),
                  child: Text(u.name.isEmpty ? '?' : u.name[0], style: const TextStyle(color: C.navy, fontWeight: FontWeight.w800)),
                ),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${u.email} · ${u.role.label}'),
                trailing: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  StatusChip(u.status.label, userStatusColor(u.status)),
                  const Icon(Icons.chevron_right),
                ]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsPage(userId: u.id))),
              ),
          ]),
        ),
    ]);
  }
}

class UserDetailsPage extends StatelessWidget {
  final String userId;
  const UserDetailsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final u = svc.userById(userId)!;
        final deleted = u.status == UserStatus.deleted;
        return Scaffold(
          appBar: AppBar(title: Text(u.name)),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              StatusChip(u.status.label, userStatusColor(u.status)),
              const SizedBox(width: 8),
              StatusChip('Vérif. : ${u.verification.label}', verificationColor(u.verification)),
            ]),
            const SectionTitle('Informations personnelles'),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              InfoRow('ID', u.id),
              InfoRow('Email', u.email),
              InfoRow('Téléphone', u.phone),
            ]))),
            const SectionTitle('Compte'),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              InfoRow('Rôle', u.role.label),
              InfoRow('Créé le', fmtDate(u.createdAt)),
              InfoRow('Dernière connexion', u.lastLogin == null ? '—' : fmtDateTime(u.lastLogin!)),
              if (u.status == UserStatus.suspended)
                InfoRow('Suspendu jusqu\'au', u.suspendedUntil == null ? 'Permanent' : fmtDate(u.suspendedUntil!)),
              if (u.statusReason != null) InfoRow('Motif', u.statusReason!),
            ]))),
            const SectionTitle('Activité'),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              InfoRow('Annonces', '${u.listings}'),
              InfoRow('Signalements reçus', '${u.reportsAgainst}'),
            ]))),
            const SectionTitle('Actions admin'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (!deleted && u.status != UserStatus.suspended && u.status != UserStatus.banned)
                OutlinedButton.icon(
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Suspendre'),
                  onPressed: () => _suspend(context, u),
                ),
              if (u.status == UserStatus.suspended || u.status == UserStatus.banned || deleted)
                FilledButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurer'),
                  onPressed: () => guarded(context, () => svc.restoreUser(u.id), 'Utilisateur restauré'),
                ),
              if (!deleted && u.status != UserStatus.banned)
                OutlinedButton.icon(
                  icon: const Icon(Icons.gavel),
                  label: const Text('Bannir'),
                  onPressed: () async {
                    final r = await askReason(context,
                        title: 'Bannir ${u.name} ?',
                        message: 'Violation grave : le compte sera banni.',
                        confirmLabel: 'Bannir',
                        destructive: true);
                    if (r != null && context.mounted) guarded(context, () => svc.banUser(u.id, r), 'Utilisateur banni');
                  },
                ),
              if (!deleted)
                PopupMenuButton<UserRole>(
                  tooltip: 'Changer le rôle',
                  onSelected: (r) async {
                    final ok = await confirmDialog(context, 'Changer le rôle ?',
                        '${u.name} deviendra « ${r.label} ».');
                    if (ok && context.mounted) guarded(context, () => svc.changeUserRole(u.id, r), 'Rôle modifié');
                  },
                  itemBuilder: (_) => [
                    for (final r in UserRole.values.where((r) => r != u.role))
                      PopupMenuItem(value: r, child: Text(r.label)),
                  ],
                  child: const Chip(avatar: Icon(Icons.swap_horiz, size: 18), label: Text('Changer le rôle')),
                ),
              if (!deleted)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  onPressed: () async {
                    final r = await askReason(context,
                        title: 'Supprimer ${u.name} ?',
                        message: 'Suppression douce : le compte pourra être restauré.',
                        confirmLabel: 'Supprimer',
                        destructive: true);
                    if (r != null && context.mounted) guarded(context, () => svc.deleteUser(u.id, r), 'Compte supprimé');
                  },
                ),
            ]),
          ]),
        );
      },
    );
  }

  Future<void> _suspend(BuildContext context, AppUser u) async {
    final svc = AdminService.instance;
    Duration? duration = const Duration(days: 7);
    final ctrl = TextEditingController();
    final result = await showDialog<(String, Duration?)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Suspendre ${u.name}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Duration?>(
              initialValue: duration,
              decoration: const InputDecoration(labelText: 'Durée'),
              items: const [
                DropdownMenuItem(value: Duration(hours: 24), child: Text('24 heures')),
                DropdownMenuItem(value: Duration(days: 7), child: Text('7 jours')),
                DropdownMenuItem(value: Duration(days: 30), child: Text('30 jours')),
                DropdownMenuItem(value: null, child: Text('Permanent')),
              ],
              onChanged: (v) => setState(() => duration = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Motif (obligatoire)'),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: ctrl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, (ctrl.text.trim(), duration)),
              child: const Text('Suspendre'),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      guarded(context, () => svc.suspendUser(u.id, result.$1, result.$2), 'Utilisateur suspendu');
    }
  }
}
