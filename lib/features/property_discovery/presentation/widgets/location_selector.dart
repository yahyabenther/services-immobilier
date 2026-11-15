import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/tunisia_governorates.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/property_discovery_providers.dart';

/// Shows the selected area (never an assumed one) and opens the picker.
class LocationSelector extends ConsumerWidget {
  const LocationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final label = location == null ? 'Choisir ma zone' : location.label;
    return Semantics(
      button: true,
      label: 'Zone : $label. Touchez pour changer.',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showLocationPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            const Icon(Icons.location_on, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: location == null ? AppColors.muted : AppColors.text)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}

Future<void> showLocationPicker(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const LocationPickerSheet(),
    );

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  bool _locating = false;

  void _snack(String message, {SnackBarAction? action}) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));

  /// Only runs on an explicit tap: permission is never requested automatically.
  Future<void> _useDeviceLocation() async {
    setState(() => _locating = true);
    final notifier = ref.read(selectedLocationProvider.notifier);
    final outcome = await notifier.useDeviceLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (outcome) {
      case DeviceLocationOutcome.success:
        Navigator.of(context).pop();
      case DeviceLocationOutcome.denied:
        _snack('Permission de localisation refusée. Vous pouvez choisir un gouvernorat ci-dessous.');
      case DeviceLocationOutcome.deniedForever:
        _snack(
          'La localisation est bloquée pour l\'application. Activez-la dans les paramètres ou choisissez un gouvernorat.',
          action: SnackBarAction(label: 'Paramètres', onPressed: notifier.openSettings),
        );
      case DeviceLocationOutcome.serviceDisabled:
        _snack('Les services de localisation sont désactivés. Activez-les ou choisissez un gouvernorat.');
      case DeviceLocationOutcome.error:
        _snack("Impossible d'obtenir votre position. Choisissez un gouvernorat.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedLocationProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Choisir ma zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        ListTile(
          leading: _locating
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, color: AppColors.primary),
          title: const Text('Utiliser ma position actuelle'),
          subtitle: const Text('Biens dans un rayon de 10 km'),
          onTap: _locating ? null : _useDeviceLocation,
        ),
        if (selected != null)
          ListTile(
            leading: const Icon(Icons.clear_rounded),
            title: const Text('Effacer la zone'),
            onTap: () {
              ref.read(selectedLocationProvider.notifier).clear();
              Navigator.of(context).pop();
            },
          ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            itemCount: tunisiaGovernorates.length,
            itemBuilder: (context, i) {
              final governorate = tunisiaGovernorates[i];
              final isSelected = selected?.governorate == governorate && !(selected?.hasCoordinates ?? false);
              return ListTile(
                title: Text(governorate),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(selectedLocationProvider.notifier).selectGovernorate(governorate);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
