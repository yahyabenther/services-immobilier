import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/tunisia_governorate_centers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../map/map_config.dart';
import '../../../property_discovery/domain/repositories/location_service.dart';
import '../../../property_discovery/presentation/providers/property_discovery_providers.dart';
import '../../domain/entities/listing_draft.dart';

/// Optional exact position: the user taps the map or uses their device position.
/// The governorate centre is ONLY the camera starting point, never stored as the
/// property's coordinates (spec §3 step 3: never invent coordinates).
class LocationPinPicker extends ConsumerStatefulWidget {
  const LocationPinPicker({
    super.key,
    required this.governorate,
    required this.coordinates,
    required this.onChanged,
    this.error,
  });

  final String? governorate;
  final ListingCoordinates? coordinates;
  final ValueChanged<ListingCoordinates?> onChanged;
  final String? error;

  @override
  ConsumerState<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends ConsumerState<LocationPinPicker> {
  var _recenter =
      0; // bumps the map key so a device position re-centres the camera
  var _locating = false;
  String? _note;

  LatLng get _center {
    final c = widget.coordinates;
    if (c != null) return LatLng(c.latitude, c.longitude);
    final g = tunisiaGovernorateCenters[widget.governorate];
    return g != null ? LatLng(g.lat, g.lng) : const LatLng(34.0, 9.5);
  }

  double get _zoom => widget.coordinates != null
      ? 15
      : (widget.governorate != null ? 10.5 : 5.8);

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _note = null;
    });
    final result = await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    switch (result) {
      case DeviceLocationGranted(:final latitude, :final longitude):
        widget.onChanged(ListingCoordinates(latitude, longitude));
        _recenter++;
        _note = null;
      case DeviceLocationDenied():
        _note =
            'Location permission was not granted. You can tap the map instead.';
      case DeviceLocationDeniedForever():
        _note = 'Location is blocked in your settings. You can tap the map instead.';
      case DeviceLocationServiceDisabled():
        _note = 'Turn on location services, or tap the map instead.';
      case DeviceLocationError():
        _note = 'Could not get your position. You can tap the map instead.';
    }
    setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coordinates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exact position (optional)',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pin the property so it appears on the map. Without a pin the listing is still shown in search, but not on the map.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              key: ValueKey('${widget.governorate}_$_recenter'),
              options: MapOptions(
                initialCenter: _center,
                initialZoom: _zoom,
                minZoom: mapMinZoom,
                maxZoom: mapMaxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, point) => widget.onChanged(
                  ListingCoordinates(point.latitude, point.longitude),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrlTemplate,
                  userAgentPackageName: mapUserAgentPackageName,
                  maxNativeZoom: 19,
                ),
                if (c != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(c.latitude, c.longitude),
                        width: 44,
                        height: 44,
                        alignment:
                            Alignment.topCenter, // pin tip on the coordinate
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.error,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [TextSourceAttribution(mapAttribution)],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _locating ? null : _useMyLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Use my location'),
            ),
            if (c != null)
              TextButton.icon(
                onPressed: () => widget.onChanged(null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove pin'),
              ),
          ],
        ),
        if (c != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Pinned: ${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _note!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}
