import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/tunisia_governorates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../properties/domain/entities/amenity.dart';
import '../../domain/entities/filter_validation.dart';
import '../../domain/entities/property_search_filter.dart';
import '../../domain/entities/search_enums.dart';
import 'filter_section.dart';
import 'search_labels.dart';

/// Opens the filter panel. Returns the filter to APPLY, or null if dismissed.
/// The panel edits a draft: nothing changes until the user taps Apply, and
/// reopening it always shows the currently applied values.
Future<PropertySearchFilter?> showSearchFilterSheet(BuildContext context, PropertySearchFilter current) {
  return showModalBottomSheet<PropertySearchFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.94,
      child: SearchFilterSheet(initial: current),
    ),
  );
}

class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key, required this.initial});

  final PropertySearchFilter initial;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late PropertySearchFilter _draft = widget.initial;

  late final _minPrice = TextEditingController(text: _fmt(widget.initial.minPrice));
  late final _maxPrice = TextEditingController(text: _fmt(widget.initial.maxPrice));
  late final _minSurface = TextEditingController(text: _fmt(widget.initial.minSurface));
  late final _maxSurface = TextEditingController(text: _fmt(widget.initial.maxSurface));
  late final _city = TextEditingController(text: widget.initial.city ?? '');
  late final _area = TextEditingController(text: widget.initial.area ?? '');

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    for (final c in [_minPrice, _maxPrice, _minSurface, _maxSurface, _city, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "250 000" / "1,5" -> number. Blank -> null. Not a number -> `invalid`.
  ({double? value, bool invalid}) _parse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return (value: null, invalid: false);
    final v = double.tryParse(cleaned);
    return (value: v, invalid: v == null);
  }

  void _onNumbers() {
    setState(() {
      _draft = _draft.copyWith(
        minPrice: _parse(_minPrice.text).value,
        maxPrice: _parse(_maxPrice.text).value,
        minSurface: _parse(_minSurface.text).value,
        maxSurface: _parse(_maxSurface.text).value,
      );
    });
  }

  bool get _anyInvalidNumber => [_minPrice, _maxPrice, _minSurface, _maxSurface].any((c) => _parse(c.text).invalid);

  void _reset() {
    for (final c in [_minPrice, _maxPrice, _minSurface, _maxSurface, _city, _area]) {
      c.clear();
    }
    setState(() => _draft = _draft.cleared());
  }

  Future<void> _pickGovernorate() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ListView(
        children: [
          ListTile(
            title: const Text('Any governorate'),
            trailing: _draft.governorate == null ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () => Navigator.of(ctx).pop(''),
          ),
          for (final g in tunisiaGovernorates)
            ListTile(
              title: Text(g),
              trailing: _draft.governorate == g ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.of(ctx).pop(g),
            ),
        ],
      ),
    );
    if (picked == null) return; // dismissed
    setState(() => _draft = _draft.copyWith(governorate: picked.isEmpty ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    final errors = FilterValidator.validate(_draft);
    final canApply = !errors.hasErrors && !_anyInvalidNumber;

    final numberFormatter = [FilteringTextInputFormatter.allow(RegExp(r'[0-9 .,]'))];
    InputDecoration dec(String label, String hint, TextEditingController c) => InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: _parse(c.text).invalid ? 'Invalid number' : null,
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(children: [
            const Expanded(
              child: Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              FilterSection(
                title: 'Property type',
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final t in searchablePropertyTypes)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: _draft.propertyType == t,
                      onSelected: (sel) => setState(() => _draft = _draft.copyWith(propertyType: sel ? t : null)),
                    ),
                ]),
              ),
              FilterSection(
                title: 'Location',
                child: Column(children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickGovernorate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Governorate'),
                      child: Row(children: [
                        Expanded(child: Text(_draft.governorate ?? 'Any governorate')),
                        if (_draft.governorate != null)
                          GestureDetector(
                            onTap: () => setState(() => _draft = _draft.copyWith(governorate: null)),
                            child: const Icon(Icons.clear, size: 18),
                          )
                        else
                          const Icon(Icons.keyboard_arrow_down_rounded),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City', hintText: 'La Marsa, Hammamet...'),
                    onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(city: v.trim().isEmpty ? null : v.trim())),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _area,
                    decoration: const InputDecoration(labelText: 'Area / neighborhood'),
                    onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(area: v.trim().isEmpty ? null : v.trim())),
                  ),
                ]),
              ),
              FilterSection(
                title: 'Price (TND)',
                hint: 'Rent prices are per month',
                error: errors.price,
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _minPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberFormatter,
                      decoration: dec('Min', '250 000', _minPrice),
                      onChanged: (_) => _onNumbers(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _maxPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberFormatter,
                      decoration: dec('Max', '1 500 000', _maxPrice),
                      onChanged: (_) => _onNumbers(),
                    ),
                  ),
                ]),
              ),
              FilterSection(
                title: 'Bedrooms',
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final b in BedroomChoice.values)
                    ChoiceChip(
                      label: Text(b.label),
                      selected: _draft.bedrooms == b,
                      onSelected: (sel) => setState(() => _draft = _draft.copyWith(bedrooms: sel ? b : null)),
                    ),
                ]),
              ),
              FilterSection(
                title: 'Bathrooms',
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final b in BathroomChoice.values)
                    ChoiceChip(
                      label: Text(b.label),
                      selected: _draft.bathrooms == b,
                      onSelected: (sel) => setState(() => _draft = _draft.copyWith(bathrooms: sel ? b : null)),
                    ),
                ]),
              ),
              FilterSection(
                title: 'Surface (m²)',
                error: errors.surface,
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _minSurface,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberFormatter,
                      decoration: dec('Min', '80', _minSurface),
                      onChanged: (_) => _onNumbers(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _maxSurface,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: numberFormatter,
                      decoration: dec('Max', '300', _maxSurface),
                      onChanged: (_) => _onNumbers(),
                    ),
                  ),
                ]),
              ),
              FilterSection(
                title: 'Amenities',
                hint: _draft.amenities.isEmpty ? 'Must have all selected' : '${_draft.amenities.length} selected',
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final a in Amenity.values)
                    FilterChip(
                      label: Text(a.label),
                      selected: _draft.amenities.contains(a),
                      onSelected: (sel) => setState(() {
                        final next = {..._draft.amenities};
                        sel ? next.add(a) : next.remove(a);
                        _draft = _draft.copyWith(amenities: next);
                      }),
                    ),
                ]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(children: [
            Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Reset'))),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: canApply ? () => Navigator.of(context).pop(_draft) : null,
                child: const Text('Apply filters'),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
