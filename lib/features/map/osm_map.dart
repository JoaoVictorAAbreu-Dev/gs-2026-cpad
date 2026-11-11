import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/pulso_colors.dart';
import '../alerts/domain/alert.dart';
import '../reservoir/data/territory_data.dart';

/// Desligável nos testes: sem tiles, sem rede.
final osmTilesEnabledProvider = Provider<bool>((ref) => true);

/// Reservatórios do Sistema Cantareira (posições aproximadas das represas).
class Reservoir {
  const Reservoir(this.name, this.point);
  final String name;
  final LatLng point;
}

const cantareiraReservoirs = [
  Reservoir('Jaguari-Jacareí', LatLng(-22.917, -46.390)),
  Reservoir('Cachoeira', LatLng(-23.030, -46.330)),
  Reservoir('Atibainha', LatLng(-23.175, -46.385)),
  Reservoir('Paiva Castro', LatLng(-23.335, -46.620)),
];

/// Mapa base do OpenStreetMap (flutter_map, a versão Flutter do Leaflet) com as represas do
/// Cantareira e as regiões coloridas pelo risco. Exige internet para os tiles.
class OsmTerritoryMap extends ConsumerWidget {
  const OsmTerritoryMap({
    super.key,
    required this.regions,
    required this.severityOf,
    required this.onTap,
    this.height = 420,
  });

  final List<Region> regions;
  final Severity Function(Region) severityOf;
  final void Function(Region) onTap;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.pulso;
    final scheme = Theme.of(context).colorScheme;
    final withCoords = regions.where((r) => r.lat != null && r.lon != null).toList();

    return Semantics(
      label: 'Mapa da Região Metropolitana com as represas do Cantareira e ${withCoords.length} regiões. '
          'Use "Ver lista" para navegar pelas regiões com leitor de tela.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: FlutterMap(
            options: MapOptions(
              // Centro entre as represas (norte) e as regiões da RMSP (sul); zoom que mostra os dois.
              initialCenter: const LatLng(-23.34, -46.55),
              initialZoom: 9,
              minZoom: 7,
              maxZoom: 15,
              backgroundColor: scheme.surfaceContainerHighest,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (ref.watch(osmTilesEnabledProvider))
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.fiap.pulso',
                  maxNativeZoom: 19,
                ),
              MarkerLayer(
                markers: [
                  for (final res in cantareiraReservoirs)
                    Marker(
                      point: res.point,
                      width: 120,
                      height: 44,
                      child: _ReservoirPin(name: res.name),
                    ),
                  for (final r in withCoords)
                    Marker(
                      point: LatLng(r.lat!, r.lon!),
                      width: 40,
                      height: 40,
                      child: _RegionPin(region: r, severity: severityOf(r), onTap: () => onTap(r), colors: c),
                    ),
                ],
              ),
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionPin extends StatelessWidget {
  const _RegionPin({required this.region, required this.severity, required this.onTap, required this.colors});
  final Region region;
  final Severity severity;
  final VoidCallback onTap;
  final PulsoColors colors;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = switch (severity) {
      Severity.high => (colors.danger, colors.dangerContainer, Icons.square_rounded),
      Severity.moderate => (colors.warning, colors.warningContainer, Icons.change_history_rounded),
      Severity.low => (colors.success, colors.successContainer, Icons.circle),
    };
    return Semantics(
      button: true,
      label: '${region.name}: risco ${severity.label}. Toque para detalhes.',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: CircleBorder(side: BorderSide(color: fg, width: 2)),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 9, color: fg),
              Text(
                region.short,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservoirPin extends StatelessWidget {
  const _ReservoirPin({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    return Semantics(
      label: 'Represa $name',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop, color: c.info, size: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.info),
            ),
          ),
        ],
      ),
    );
  }
}
