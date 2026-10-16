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
    final label = location == null ? 'Choose your location' : '${location.label}, Tunisia';
    return Semantics(
      button: true,
      label: 'Location: $label. Tap to change.',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showLocationPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: location == null ? AppColors.muted : AppColors.text)),
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
        _snack('Location permission was denied. You can still pick a governorate below.');
      case DeviceLocationOutcome.deniedForever:
        _snack(
          'Location is blocked for ImmoFind. Enable it in system settings, or pick a governorate.',
          action: SnackBarAction(label: 'Settings', onPressed: notifier.openSettings),
        );
      case DeviceLocationOutcome.serviceDisabled:
        _snack('Location services are turned off. Turn them on, or pick a governorate.');
      case DeviceLocationOutcome.error:
        _snack("Couldn't get your location. Pick a governorate instead.");
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
            child: Text('Choose your location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
        ListTile(
          leading: _locating
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, color: AppColors.primary),
          title: const Text('Use my current location'),
          subtitle: const Text('Find listings within 10 km'),
          onTap: _locating ? null : _useDeviceLocation,
        ),
        if (selected != null)
          ListTile(
            leading: const Icon(Icons.clear_rounded),
            title: const Text('Clear location'),
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
