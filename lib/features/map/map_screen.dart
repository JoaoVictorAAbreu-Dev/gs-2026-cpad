import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../alerts/domain/alert.dart';
import '../reservoir/data/territory_data.dart';
import 'region_risk.dart';

/// Cartograma: cada hexágono é uma região, fora de escala. Cor + ícone + texto (nunca só cor).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _forecast = false;
  bool _asList = false;

  @override
  Widget build(BuildContext context) {
    final territory = ref.watch(territoryProvider);
    final reservoir = ref.watch(reservoirProvider).valueOrNull?.data;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppHeader(),
      body: territory.when(
        loading: () => const Padding(padding: EdgeInsets.all(PulsoSpacing.screen), child: LoadingSkeleton()),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          child: ErrorState(onRetry: () => ref.invalidate(territoryProvider)),
        ),
        data: (t) {
          final regions = t.data.regions;
          Severity sev(Region r) => _forecast ? RegionRisk.in7Days(r) : RegionRisk.today(r);
          return ListView(
            padding: const EdgeInsets.all(PulsoSpacing.screen),
            children: [
              Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text('Mapa territorial', style: text.headlineMedium))),
                  if (reservoir != null)
                    Chip(
                      avatar: const Icon(Icons.water_drop_outlined, size: 18),
                      label: Text('Cantareira ${Fmt.percent(reservoir.latest.volumePercent)}'),
                    ),
                ],
              ),
              const SizedBox(height: PulsoSpacing.md12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Hoje')),
                  ButtonSegment(value: true, label: Text('+7 dias (previsão)')),
                ],
                selected: {_forecast},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _forecast = s.first),
              ),
              const SizedBox(height: PulsoSpacing.md12),
              Wrap(
                spacing: PulsoSpacing.sm,
                runSpacing: PulsoSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Risco de abastecimento:', style: text.bodyMedium),
                  for (final s in Severity.values.reversed) SeverityBadge(severity: s),
                  const DataSourceTag(real: false),
                ],
              ),
              const SizedBox(height: PulsoSpacing.md),
              if (_asList)
                _RegionList(regions: regions, severityOf: sev, onTap: (r) => _openRegion(r, sev(r)))
              else
                _HexCartogram(regions: regions, severityOf: sev, onTap: (r) => _openRegion(r, sev(r))),
              const SizedBox(height: PulsoSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, kMinTouchTarget)),
                  onPressed: () => setState(() => _asList = !_asList),
                  icon: Icon(_asList ? Icons.hexagon_outlined : Icons.list),
                  label: Text(_asList ? 'Ver mapa' : 'Ver lista'),
                ),
              ),
              const SizedBox(height: PulsoSpacing.sm),
              Text(
                _forecast
                    ? '+7 dias: cada região repete a variação de registros da última semana. '
                        'Cartograma fora de escala; cores das regiões em cenário sintético de demonstração.'
                    : 'Cartograma: cada hexágono é uma região, fora de escala. Risco pelos registros '
                        'dos últimos 7 dias (≥ ${RegionRisk.highFrom} alto, ≥ ${RegionRisk.moderateFrom} moderado).',
                style: text.bodyMedium?.copyWith(color: context.pulso.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openRegion(Region r, Severity severity) {
    final alert = (ref.read(alertsProvider).valueOrNull ?? const <Alert>[])
        .where((a) => a.regionId == r.id)
        .firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _RegionSheet(region: r, severity: severity, alert: alert, forecast: _forecast),
    );
  }
}

class _HexCartogram extends StatelessWidget {
  const _HexCartogram({required this.regions, required this.severityOf, required this.onTap});
  final List<Region> regions;
  final Severity Function(Region) severityOf;
  final void Function(Region) onTap;

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) return const SizedBox.shrink();
    final maxCol = regions.map((r) => r.col).reduce(math.max);
    final maxRow = regions.map((r) => r.row).reduce(math.max);
    final reduce = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, c) {
        // Hexágono "ponta para cima": largura w, altura h = w·2/√3; linhas pares deslocadas meia largura.
        final w = math.min(72.0, c.maxWidth / (maxCol + 1.5));
        final h = w * 2 / math.sqrt(3);
        final stepY = h * 0.75;
        final totalW = (maxCol + 1.5) * w;
        final left0 = (c.maxWidth - totalW) / 2;
        return SizedBox(
          height: maxRow * stepY + h,
          child: Stack(
            children: [
              for (final r in regions)
                Positioned(
                  left: left0 + r.col * w + (r.row.isEven ? w / 2 : 0),
                  top: r.row * stepY,
                  width: w,
                  height: h,
                  child: _Hex(
                    region: r,
                    severity: severityOf(r),
                    onTap: () => onTap(r),
                    animate: !reduce,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Hex extends StatelessWidget {
  const _Hex({required this.region, required this.severity, required this.onTap, required this.animate});
  final Region region;
  final Severity severity;
  final VoidCallback onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final (fg, bg, icon) = switch (severity) {
      Severity.high => (c.danger, c.dangerContainer, Icons.square_rounded),
      Severity.moderate => (c.warning, c.warningContainer, Icons.change_history_rounded),
      Severity.low => (c.success, c.successContainer, Icons.circle),
    };
    return Semantics(
      button: true,
      label: '${region.name}: risco ${severity.label}. Toque para detalhes.',
      excludeSemantics: true,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: bg),
        duration: animate ? const Duration(milliseconds: 400) : Duration.zero,
        builder: (context, color, child) => Material(
          color: color,
          shape: _HexBorder(side: BorderSide(color: fg, width: 1.6)),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10, color: fg),
              const SizedBox(height: 2),
              Text(
                region.short,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Borda hexagonal (ponta para cima) usada como ShapeBorder do Material.
class _HexBorder extends OutlinedBorder {
  const _HexBorder({super.side});

  Path _path(Rect r) {
    final cx = r.center.dx;
    return Path()
      ..moveTo(cx, r.top)
      ..lineTo(r.right, r.top + r.height * 0.25)
      ..lineTo(r.right, r.top + r.height * 0.75)
      ..lineTo(cx, r.bottom)
      ..lineTo(r.left, r.top + r.height * 0.75)
      ..lineTo(r.left, r.top + r.height * 0.25)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(2));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(2)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => _HexBorder(side: side.scale(t));

  @override
  _HexBorder copyWith({BorderSide? side}) => _HexBorder(side: side ?? this.side);
}

class _RegionList extends StatelessWidget {
  const _RegionList({required this.regions, required this.severityOf, required this.onTap});
  final List<Region> regions;
  final Severity Function(Region) severityOf;
  final void Function(Region) onTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...regions]..sort((a, b) => severityOf(a).index.compareTo(severityOf(b).index));
    return Column(
      children: [
        for (final r in sorted)
          Card(
            margin: const EdgeInsets.only(bottom: PulsoSpacing.sm),
            child: ListTile(
              title: Text(r.name),
              subtitle: Text('${r.lastWeek} registros em 7 dias (antes: ${r.previousWeek})'),
              trailing: SeverityBadge(severity: severityOf(r)),
              onTap: () => onTap(r),
            ),
          ),
      ],
    );
  }
}

class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.region, required this.severity, required this.alert, required this.forecast});
  final Region region;
  final Severity severity;
  final Alert? alert;
  final bool forecast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final delta = region.lastWeek - region.previousWeek;
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(PulsoSpacing.md12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(PulsoRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: text.titleMedium),
                Text(label, style: text.bodyMedium),
              ],
            ),
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PulsoSpacing.lg, 0, PulsoSpacing.lg, PulsoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(region.name, style: text.titleLarge)),
                SeverityBadge(severity: severity),
              ],
            ),
            const SizedBox(height: PulsoSpacing.md),
            Row(
              children: [
                stat('${region.lastWeek}', 'registros em 7 dias'),
                const SizedBox(width: PulsoSpacing.sm),
                stat('${delta >= 0 ? '+' : '−'}${delta.abs()}', 'vs. semana anterior'),
                const SizedBox(width: PulsoSpacing.sm),
                stat(forecast ? '${RegionRisk.projectedCount(region)}' : Fmt.number(region.reportsPer100k), forecast ? 'previstos' : 'por 100 mil hab.'),
              ],
            ),
            const SizedBox(height: PulsoSpacing.md),
            Text(
              'Valores sintéticos de demonstração. A região é abastecida em parte pelo Cantareira '
              '(contexto, não causalidade).',
              style: text.bodyMedium?.copyWith(color: context.pulso.muted),
            ),
            const SizedBox(height: PulsoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pushNamed(Routes.newReport, queryParameters: {'regiao': region.id});
                    },
                    child: const Text('Registrar aqui'),
                  ),
                ),
                if (alert != null) ...[
                  const SizedBox(width: PulsoSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.pushNamed(Routes.alertDetail, pathParameters: {'id': alert!.id});
                      },
                      child: const Text('Ver alerta'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
