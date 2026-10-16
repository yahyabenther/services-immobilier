import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/property_image.dart';
import '../../domain/entities/map_cluster.dart';

/// Tap on a cluster: zoom toward its bounds; when zooming cannot separate the members
/// (same point / max zoom) list them so none is unreachable (spec §6.3).
/// [onPropertyChosen] receives the chosen property ID.
Future<void> zoomIntoCluster({
  required BuildContext context,
  required MapController controller,
  required MapCluster cluster,
  required ValueChanged<String> onPropertyChosen,
}) async {
  if (cluster.canZoomFurther(controller.camera.zoom)) {
    controller.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(cluster.south, cluster.west), LatLng(cluster.north, cluster.east)),
      padding: const EdgeInsets.all(72),
      maxZoom: 18,
    ));
    return;
  }
  final id = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${cluster.count} properties here',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cluster.count,
              itemBuilder: (_, i) {
                final p = cluster.properties[i];
                return ListTile(
                  onTap: () => Navigator.pop(ctx, p.id),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 56, height: 56, child: PropertyImage(url: p.mainImage, size: PropertyImageSize.thumb)),
                  ),
                  title: Text(PriceFormatter.format(p.price, p.currency, p.transactionType),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  subtitle: Text('${p.title} · ${p.locationLabel}', maxLines: 2, overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ),
        ]),
      ),
    ),
  );
  if (id != null) onPropertyChosen(id);
}
