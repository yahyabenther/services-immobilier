import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/property_search_filter.dart';
import 'search_labels.dart';

/// One removable chip per active filter, so the user always sees WHY the list looks
/// the way it does and can drop a single condition.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({super.key, required this.filter, required this.onChanged, required this.onClearAll});

  final PropertySearchFilter filter;
  final ValueChanged<PropertySearchFilter> onChanged;
  final VoidCallback onClearAll;

  static String _n(double v) {
    final s = (v == v.roundToDouble() ? v.toInt() : v).toString();
    final b = StringBuffer();
    final intPart = s.split('.').first;
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) b.write(' ');
      b.write(intPart[i]);
    }
    return s.contains('.') ? '$b.${s.split('.').last}' : b.toString();
  }

  static String _range(double? min, double? max, String unit) {
    if (min != null && max != null) return '${_n(min)} – ${_n(max)} $unit';
    if (min != null) return 'from ${_n(min)} $unit';
    return 'up to ${_n(max!)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final f = filter;
    final chips = <Widget>[
      if (f.propertyType != null) _chip(f.propertyType!.label, () => onChanged(f.copyWith(propertyType: null))),
      if (f.governorate != null) _chip(f.governorate!, () => onChanged(f.copyWith(governorate: null))),
      if (f.city != null) _chip(f.city!, () => onChanged(f.copyWith(city: null))),
      if (f.area != null) _chip(f.area!, () => onChanged(f.copyWith(area: null))),
      if (f.minPrice != null || f.maxPrice != null)
        _chip(_range(f.minPrice, f.maxPrice, 'TND'), () => onChanged(f.copyWith(minPrice: null, maxPrice: null))),
      if (f.bedrooms != null) _chip('${f.bedrooms!.label} bed', () => onChanged(f.copyWith(bedrooms: null))),
      if (f.bathrooms != null) _chip('${f.bathrooms!.label} bath', () => onChanged(f.copyWith(bathrooms: null))),
      if (f.minSurface != null || f.maxSurface != null)
        _chip(_range(f.minSurface, f.maxSurface, 'm²'), () => onChanged(f.copyWith(minSurface: null, maxSurface: null))),
      for (final a in f.amenities)
        _chip(a.label, () => onChanged(f.copyWith(amenities: {...f.amenities}..remove(a)))),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...chips,
          TextButton(onPressed: onClearAll, child: const Text('Clear all')),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InputChip(
          label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
          onDeleted: onRemove,
          deleteButtonTooltipMessage: 'Remove filter',
          visualDensity: VisualDensity.compact,
          backgroundColor: const Color(0xFFE8F0FE),
          side: BorderSide.none,
        ),
      );
}
