import 'package:flutter/material.dart';
import '../data/admin_service.dart';
import 'widgets.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AdminService.instance;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Group(title: 'Types de bien', kind: 'propertyType', items: s.propertyTypes),
      _Group(title: 'Équipements', kind: 'amenity', items: s.amenities),
      _Group(title: 'Villes', kind: 'city', items: s.cities),
    ]);
  }
}

class _Group extends StatelessWidget {
  final String title;
  final String kind;
  final List<String> items;
  const _Group({required this.title, required this.kind, required this.items});

  Future<void> _add(BuildContext context) async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter — $title'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'Valeur')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Ajouter')),
        ],
      ),
    );
    if (v != null && context.mounted) {
      guarded(context, () => AdminService.instance.addContent(items, kind, v), 'Ajouté');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title, trailing: IconButton(onPressed: () => _add(context), icon: const Icon(Icons.add_circle_outline))),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final i in items)
          InputChip(
            label: Text(i),
            onDeleted: () async {
              final ok = await confirmDialog(context, 'Supprimer « $i » ?', 'Cette valeur ne sera plus proposée.', confirmLabel: 'Supprimer', destructive: true);
              if (ok && context.mounted) guarded(context, () => AdminService.instance.removeContent(items, kind, i), 'Supprimé');
            },
          ),
      ]),
    ]);
  }
}
