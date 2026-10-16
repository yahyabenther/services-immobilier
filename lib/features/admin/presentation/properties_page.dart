import 'package:flutter/material.dart';
import '../../../core/theme/legacy_colors.dart';
import '../data/admin_service.dart';
import '../data/models.dart';
import 'widgets.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});
  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  final svc = AdminService.instance;
  String query = '';
  PropertyStatus? status = PropertyStatus.pendingReview;
  bool reportedOnly = false;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final list = svc.properties.where((p) {
      if (status != null && p.status != status) return false;
      if (reportedOnly && p.reportCount == 0) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.ownerName.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.id.toLowerCase() == q;
    }).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(hintText: 'Rechercher : titre, propriétaire, ville, ID', prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ChoiceChip(label: const Text('Tous'), selected: status == null, onSelected: (_) => setState(() => status = null)),
          for (final s in PropertyStatus.values.where((s) => s != PropertyStatus.draft && s != PropertyStatus.expired)) ...[
            const SizedBox(width: 8),
            ChoiceChip(label: Text('${s.label} (${svc.propertyCount(s)})'), selected: status == s, onSelected: (_) => setState(() => status = s)),
          ],
          const SizedBox(width: 8),
          FilterChip(label: const Text('Signalées'), selected: reportedOnly, onSelected: (v) => setState(() => reportedOnly = v)),
        ]),
      ),
      const SizedBox(height: 12),
      if (list.isEmpty)
        const EmptyState('Aucune annonce')
      else
        for (final p in list)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
              title: Row(children: [
                Expanded(child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (p.verified) const Icon(Icons.verified, color: C.green, size: 18),
              ]),
              subtitle: Text('${p.ownerName} · ${p.area}, ${p.city}\n${fmtPrice(p.price)}'),
              isThreeLine: true,
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                StatusChip(p.status.label, propertyStatusColor(p.status)),
                const SizedBox(height: 4),
                if (p.riskScore >= 60) StatusChip('Risque ${p.riskScore}', Colors.red.shade700),
              ]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyReviewPage(propertyId: p.id))),
            ),
          ),
    ]);
  }
}

class PropertyReviewPage extends StatelessWidget {
  final String propertyId;
  const PropertyReviewPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final p = svc.propertyById(propertyId)!;
        final risky = p.riskScore >= 70;
        final missingDocs = p.documents.any((d) => !d.provided);
        final duplicates = svc.properties.where((o) => o.id != p.id && o.ownerId == p.ownerId && o.title == p.title).length;

        final warnings = <String>[
          if (risky) 'Score de risque élevé (${p.riskScore}/100)',
          if (missingDocs) 'Documents manquants ou invalides',
          if (p.photos < 3) 'Moins de 3 photos',
          if (p.price < 100000 && p.type != 'Bureau' && p.type != 'Commerce' && p.surface >= 100) 'Prix suspect par rapport à la surface',
          if (p.reportCount > 0) '${p.reportCount} signalement(s)',
          if (duplicates > 0) 'Doublon potentiel',
        ];

        return Scaffold(
          appBar: AppBar(title: Text('Annonce ${p.id}')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              height: 140,
              decoration: BoxDecoration(color: C.navy.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_library_outlined, color: C.navy, size: 34),
                const SizedBox(height: 6),
                Text('${p.photos} photo(s)', style: const TextStyle(color: C.muted)),
              ])),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.navy))),
              StatusChip(p.status.label, propertyStatusColor(p.status)),
            ]),
            const SizedBox(height: 4),
            Text(fmtPrice(p.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.secondary)),
            if (p.verified)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(children: [Icon(Icons.verified, color: C.green, size: 18), SizedBox(width: 6), Text('ImmoFind Certifié')]),
              ),
            if (warnings.isNotEmpty) ...[
              const SectionTitle('Points d\'attention'),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final w in warnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700), const SizedBox(width: 8), Expanded(child: Text(w))]),
                      ),
                  ]),
                ),
              ),
            ],
            const SectionTitle('Détails'),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              InfoRow('Propriétaire', p.ownerName),
              InfoRow('Type', p.type),
              InfoRow('Localisation', '${p.area}, ${p.city}'),
              InfoRow('Surface', '${p.surface} m²'),
              InfoRow('Chambres', '${p.bedrooms}'),
              InfoRow('Salles de bain', '${p.bathrooms}'),
              InfoRow('Soumise le', fmtDateTime(p.createdAt)),
              if (p.statusReason != null) InfoRow('Motif', p.statusReason!),
            ]))),
            const SectionTitle('Description'),
            Text(p.description),
            const SectionTitle('Documents'),
            Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: p.documents.isEmpty ? const Padding(padding: EdgeInsets.all(14), child: Text('Aucun document')) : DocList(p.documents))),
            const SectionTitle('Actions'),
            Wrap(spacing: 10, runSpacing: 10, children: _actions(context, svc, p)),
          ]),
        );
      },
    );
  }

  List<Widget> _actions(BuildContext context, AdminService svc, AdminProperty p) {
    final red = Colors.red.shade700;
    Widget reasonBtn(String label, IconData icon, String title, String msg, void Function(String) fn, String ok,
            {bool danger = false}) =>
        OutlinedButton.icon(
          style: danger ? OutlinedButton.styleFrom(foregroundColor: red) : null,
          icon: Icon(icon),
          label: Text(label),
          onPressed: () async {
            final r = await askReason(context, title: title, message: msg, confirmLabel: label, destructive: danger);
            if (r != null && context.mounted) guarded(context, () => fn(r), ok);
          },
        );

    switch (p.status) {
      case PropertyStatus.pendingReview:
        return [
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Approuver'),
            onPressed: () => guarded(context, () => svc.approveProperty(p.id), 'Annonce publiée'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: C.green),
            icon: const Icon(Icons.verified),
            label: const Text('Approuver + certifier'),
            onPressed: () => guarded(context, () => svc.approveProperty(p.id, verified: true), 'Annonce publiée et certifiée'),
          ),
          reasonBtn('Rejeter', Icons.close, 'Rejeter l\'annonce', 'Le propriétaire recevra ce motif.', (r) => svc.rejectProperty(p.id, r), 'Annonce rejetée', danger: true),
        ];
      case PropertyStatus.published:
        return [
          if (!p.verified)
            OutlinedButton.icon(
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Certifier'),
              onPressed: () => guarded(context, () => svc.verifyProperty(p.id), 'Annonce certifiée'),
            ),
          reasonBtn('Suspendre', Icons.pause_circle_outline, 'Suspendre l\'annonce', 'Elle ne sera plus visible.', (r) => svc.suspendProperty(p.id, r), 'Annonce suspendue'),
          reasonBtn('Retirer', Icons.delete_outline, 'Retirer l\'annonce', 'Action sensible, tracée dans l\'audit.', (r) => svc.removeProperty(p.id, r), 'Annonce retirée', danger: true),
        ];
      case PropertyStatus.suspended:
      case PropertyStatus.removed:
        return [
          FilledButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Restaurer'),
            onPressed: () => guarded(context, () => svc.restoreProperty(p.id), 'Annonce restaurée'),
          ),
        ];
      default:
        return [const Text('Aucune action disponible pour ce statut.', style: TextStyle(color: C.muted))];
    }
  }
}
