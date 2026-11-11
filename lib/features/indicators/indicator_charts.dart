import 'package:flutter/material.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/bar_chart.dart';
import '../reservoir/data/territory_data.dart';
import '../reservoir/domain/reservoir_models.dart';
import 'domain/series_stats.dart';

/// Gráficos de histórico compartilhados entre os dashboards e o detalhe do indicador.

String _mmLabel(DateTime m) => Fmt.shortMonth(m);

/// Volume médio de cada mês (12 meses) com o mesmo mês do ano anterior e a tendência.
class VolumeMonthlyChart extends StatelessWidget {
  const VolumeMonthlyChart({super.key, required this.snapshot, this.months = 12});
  final ReservoirSnapshot snapshot;
  final int months;

  @override
  Widget build(BuildContext context) {
    final data = SeriesStats.monthly(snapshot.series, value: (p) => p.volumePercent, mean: true, months: months);
    if (data.isEmpty) return const SizedBox.shrink();
    final low = data.map((d) => [d.value, d.previousYear ?? d.value]).expand((e) => e).reduce((a, b) => a < b ? a : b);
    return PulsoBarChart(
      data: [
        for (final d in data)
          BarDatum(label: _mmLabel(d.month), value: d.value, compare: d.previousYear, highlight: !d.complete),
      ],
      unit: '% do volume útil',
      valueLabel: 'Média do mês',
      compareLabel: 'Mesmo mês, ano anterior',
      showTrend: true,
      minY: (((low - 5) / 10).floor() * 10.0).clamp(0, 100).toDouble(),
      format: (v) => Fmt.percent(v),
      semanticsSummary: 'Volume médio mensal de ${Fmt.spokenDate(data.first.month)} a '
          '${Fmt.spokenDate(data.last.month)}. Último mês: ${Fmt.spokenPercent(data.last.value)}'
          '${data.last.previousYear == null ? '' : ', contra ${Fmt.spokenPercent(data.last.previousYear!)} um ano antes'}.',
    );
  }
}

/// Chuva somada por mês (12 meses) contra o mesmo mês do ano anterior.
class RainMonthlyChart extends StatelessWidget {
  const RainMonthlyChart({super.key, required this.snapshot, this.months = 12});
  final ReservoirSnapshot snapshot;
  final int months;

  @override
  Widget build(BuildContext context) {
    final data = SeriesStats.monthly(snapshot.series, value: (p) => p.rainMm, mean: false, months: months);
    if (data.isEmpty) return const SizedBox.shrink();
    return PulsoBarChart(
      data: [
        for (final d in data)
          BarDatum(label: _mmLabel(d.month), value: d.value, compare: d.previousYear, highlight: !d.complete),
      ],
      unit: 'mm no mês',
      valueLabel: 'Chuva do mês',
      compareLabel: 'Mesmo mês, ano anterior',
      color: context.pulso.info,
      format: (v) => '${v.round()} mm',
      semanticsSummary: 'Chuva mensal na bacia de ${Fmt.spokenDate(data.first.month)} a '
          '${Fmt.spokenDate(data.last.month)}. Último mês: ${data.last.value.round()} milímetros'
          '${data.last.previousYear == null ? '' : ', contra ${data.last.previousYear!.round()} um ano antes'}.',
    );
  }
}

/// Chuva por semana (blocos de 7 dias terminando no último dado) com tendência.
class RainWeeklyChart extends StatelessWidget {
  const RainWeeklyChart({super.key, required this.snapshot, this.weeks = 12});
  final ReservoirSnapshot snapshot;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final data = SeriesStats.blocks(snapshot.series, value: (p) => p.rainMm ?? 0, count: weeks);
    if (data.isEmpty) return const SizedBox.shrink();
    return PulsoBarChart(
      data: [for (final d in data) BarDatum(label: Fmt.dayMonth(d.end), value: d.value)],
      unit: 'mm por semana',
      valueLabel: 'Chuva na semana (até a data)',
      showTrend: true,
      color: context.pulso.info,
      format: (v) => '${v.round()} mm',
      semanticsSummary: 'Chuva semanal nas últimas ${data.length} semanas. Última semana: '
          '${data.last.value.round()} milímetros.',
    );
  }
}

/// Soma de registros de falta de água de todas as regiões, por semana, com tendência.
class ReportsWeeklyChart extends StatelessWidget {
  const ReportsWeeklyChart({super.key, required this.regions, this.region});
  final List<Region> regions;

  /// Quando informado, mostra só esta região.
  final Region? region;

  static List<int> totals(List<Region> regions) {
    if (regions.isEmpty) return const [];
    final n = regions.map((r) => r.weeklyHistory.length).reduce((a, b) => a < b ? a : b);
    return [
      for (var i = 0; i < n; i++)
        regions.fold<int>(0, (s, r) => s + r.weeklyHistory[r.weeklyHistory.length - n + i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final values = region != null ? region!.weeklyHistory : totals(regions);
    if (values.isEmpty) return const SizedBox.shrink();
    final n = values.length;
    return PulsoBarChart(
      data: [
        for (var i = 0; i < n; i++)
          BarDatum(label: i == n - 1 ? 'atual' : 'S−${n - 1 - i}', value: values[i].toDouble()),
      ],
      unit: 'registros por semana',
      valueLabel: region == null ? 'Registros (todas as regiões)' : 'Registros em ${region!.name}',
      showTrend: true,
      color: context.pulso.warning,
      format: (v) => '${v.round()} registros',
      semanticsSummary: 'Registros de falta de água por semana nas últimas $n semanas'
          '${region == null ? ', somando todas as regiões' : ' em ${region!.name}'}. '
          'Semana atual: ${values.last}; semana anterior: ${values[n - 2]}.',
    );
  }
}

/// Seta + texto da tendência ("subindo 0,3 p.p. por semana").
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.trend, required this.unitPerStep, this.tolerance = 0, this.upIsGood = true});

  final LinearTrend trend;

  /// Ex.: "p.p. por dia", "mm por semana".
  final String unitPerStep;
  final double tolerance;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final dir = trend.direction(tolerance: tolerance);
    final (icon, word) = switch (dir) {
      TrendDirection.up => (Icons.trending_up, 'Subindo'),
      TrendDirection.down => (Icons.trending_down, 'Caindo'),
      TrendDirection.flat => (Icons.trending_flat, 'Estável'),
    };
    final good = dir == TrendDirection.flat ? null : (dir == TrendDirection.up) == upIsGood;
    final color = good == null ? c.muted : (good ? c.success : c.danger);
    final mag = Fmt.number(trend.slope.abs(), 2);
    return Semantics(
      label: 'Tendência: $word${dir == TrendDirection.flat ? '' : ', $mag $unitPerStep'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              dir == TrendDirection.flat ? 'Tendência: estável' : 'Tendência: $word ${'$mag $unitPerStep'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
