import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../domain/entities/search_enums.dart';
import '../../providers/search_filter_provider.dart';
import '../widgets/filter_section.dart';
import '../widgets/option_chip.dart';
import '../widgets/search_labels.dart';

import 'search_results_page.dart';
class SearchFiltersPage extends ConsumerStatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  ConsumerState<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends ConsumerState<SearchFiltersPage> {
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  final _city = TextEditingController();

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _city.dispose();
    super.dispose();
  }

  double? _parse(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    return cleaned.isEmpty ? null : double.tryParse(cleaned);
  }

  void _onPriceChanged() {
    ref
        .read(searchFilterProvider.notifier)
        .setPriceRange(_parse(_minPrice.text), _parse(_maxPrice.text));
  }

  void _onCityChanged(String? governorate) {
    final c = _city.text.trim();
    ref
        .read(searchFilterProvider.notifier)
        .setLocation(governorate: governorate, city: c.isEmpty ? null : c);
  }

  void _reset() {
    _minPrice.clear();
    _maxPrice.clear();
    _city.clear();
    ref.read(searchFilterProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppBarSimple(
              f.activeCount == 0
                  ? 'Rechercher'
                  : 'Rechercher (${f.activeCount})',
            ),

            // Transaction
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in TransactionType.values)
                    FilterPill(
                      t.label,
                      selected: f.transactionType == t,
                      onTap: () => notifier.setTransaction(t),
                    ),
                ],
              ),
            ),

            // Type de bien
            FilterSection(
              title: 'Type de bien',
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
                childAspectRatio: 2.6,
                children: [
                  for (final p in PropertyType.values)
                    OptionChip(
                      label: p.label,
                      pill: false,
                      selected: f.propertyType == p,
                      onTap: () => notifier.setPropertyType(p),
                    ),
                ],
              ),
            ),

            // Localisation
            FilterSection(
              title: 'Localisation',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(f.governorate),
                    initialValue: f.governorate,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Gouvernorat'),
                    items: [
                      for (final g in tunisianGovernorates)
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: _onCityChanged,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      hintText: 'La Marsa, Sousse...',
                    ),
                    onChanged: (_) => _onCityChanged(f.governorate),
                  ),
                ],
              ),
            ),

            // Budget
            FilterSection(
              title: 'Fourchette de budget',
              hint: 'En dinars (TND)',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        hintText: '250 000',
                      ),
                      onChanged: (_) => _onPriceChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        hintText: '1 500 000',
                      ),
                      onChanged: (_) => _onPriceChanged(),
                    ),
                  ),
                ],
              ),
            ),

            // Chambres: 0 = Studio, 4 = "4+"
            FilterSection(
              title: 'Chambres (S+)',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final n in [0, 1, 2, 3, 4])
                    OptionChip(
                      label: n == 0 ? 'Studio' : (n == 4 ? '4+' : '$n'),
                      selected: f.bedrooms == n,
                      onTap: () => notifier.setBedrooms(n),
                    ),
                ],
              ),
            ),

            // Salles de bain: 3 = "3+"
            FilterSection(
              title: 'Salles de bain',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final n in [1, 2, 3])
                    OptionChip(
                      label: n == 3 ? '3+' : '$n',
                      selected: f.bathrooms == n,
                      onTap: () => notifier.setBathrooms(n),
                    ),
                ],
              ),
            ),

            // Superficie minimum (0 = pas de filtre)
            FilterSection(
              title: 'Superficie minimum',
              hint: f.minSurface == null ? 'Indifférent' : '${f.minSurface!.round()} m²',
              child: Slider(
                value: f.minSurface ?? 0,
                min: 0,
                max: 500,
                divisions: 50,
                activeColor: C.navy,
                onChanged: (v) =>
                    notifier.setSurfaceRange(v == 0 ? null : v, f.maxSurface),
              ),
            ),

            // Équipements
            FilterSection(
              title: 'Prestations & commodités',
              hint: f.amenities.isEmpty ? null : '${f.amenities.length} sélectionné(s)',
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in Amenity.values)
                    OptionChip(
                      label: a.label,
                      selected: f.amenities.contains(a),
                      onTap: () => notifier.toggleAmenity(a),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: C.navy),
                    // Step 6: navigation vers SearchResultsPage.
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchResultsPage()),
                    ),
                    child: const Text('Afficher les résultats'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}