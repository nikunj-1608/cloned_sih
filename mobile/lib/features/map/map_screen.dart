import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../voyage/voyage_controller.dart';
import 'demo_geo.dart';

/// The chart view.
///
/// Layers are colour-coded to the same scheme as the rest of the app: red is a
/// boundary you must not cross, amber is a protected area, green is where the
/// fish are. A legend is always on screen — nothing here depends on the user
/// remembering what a colour means.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _map = MapController();
  bool _following = true;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _recenter(LatLng target) {
    _map.move(target, _map.camera.zoom);
    setState(() => _following = true);
  }

  @override
  Widget build(BuildContext context) {
    final voyage = ref.watch(voyageProvider);
    final boundary = ref.watch(boundaryStatusProvider);

    // Keep the vessel in frame while a trip is running.
    ref.listen(voyageProvider, (previous, next) {
      if (_following && next.underway) {
        _map.move(next.position, _map.camera.zoom);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: DemoGeo.homePort,
              initialZoom: 9.2,
              minZoom: 5,
              maxZoom: 17,
              onPointerDown: (_, _) {
                if (_following) setState(() => _following = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: Env.mapTileUrl,
                userAgentPackageName: 'in.prismarine.orca',
                // Phase 2 swaps this for a cached offline tile provider.
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: DemoGeo.marineProtectedArea,
                    color: AppColors.mpa.withValues(alpha: 0.18),
                    borderColor: AppColors.mpa,
                    borderStrokeWidth: 2.5,
                  ),
                  for (final zone in DemoGeo.potentialFishingZones)
                    Polygon(
                      points: zone.polygon,
                      color: AppColors.pfz.withValues(alpha: 0.22),
                      borderColor: AppColors.pfz,
                      borderStrokeWidth: 2.5,
                    ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: DemoGeo.imbl,
                    color: AppColors.imbl,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: voyage.position,
                    width: 54,
                    height: 54,
                    child: _VesselMarker(headingDeg: voyage.headingDeg),
                  ),
                ],
              ),
            ],
          ),

          _TopBanner(
            distanceKm: boundary.distanceKm,
            headline: boundary.headline,
            accent: boundary.level.color,
          ),

          const Positioned(
            left: AppSizes.gutter,
            bottom: 24,
            child: _Legend(),
          ),

          Positioned(
            right: AppSizes.gutter,
            bottom: 24,
            child: Column(
              children: [
                _MapButton(
                  icon: _following
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  label: 'Recenter',
                  onTap: () => _recenter(voyage.position),
                ),
                const SizedBox(height: 12),
                _MapButton(
                  icon: voyage.underway
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: voyage.underway ? 'Pause' : 'Sail',
                  filled: true,
                  onTap: () => ref.read(voyageProvider.notifier).toggleVoyage(),
                ),
              ],
            ),
          ),

          const Positioned(
            right: 6,
            bottom: 2,
            child: _Attribution(),
          ),
        ],
      ),
    );
  }
}

class _VesselMarker extends StatelessWidget {
  const _VesselMarker({required this.headingDeg});

  final double headingDeg;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDeg * 3.1415926535 / 180,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.vessel,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.distanceKm,
    required this.headline,
    required this.accent,
  });

  final double distanceKm;
  final String headline;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: AppSizes.gutter,
      right: AppSizes.gutter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(width: 6, height: 38, color: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Border $headline',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '${distanceKm.toStringAsFixed(1)} km — எல்லை தூரம்',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AppColors.imbl, label: 'Border', labelTa: 'எல்லை'),
          SizedBox(height: 8),
          _LegendRow(color: AppColors.mpa, label: 'Protected', labelTa: 'தடை'),
          SizedBox(height: 8),
          _LegendRow(color: AppColors.pfz, label: 'Fish zone', labelTa: 'மீன்'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.labelTa,
  });

  final Color color;
  final String label;
  final String labelTa;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label · $labelTa',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.1),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = filled ? AppColors.deepSea : theme.colorScheme.surface;
    final foreground = filled ? Colors.white : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white70,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        Env.mapAttribution,
        style: const TextStyle(fontSize: 9.5, color: Colors.black87),
      ),
    );
  }
}
