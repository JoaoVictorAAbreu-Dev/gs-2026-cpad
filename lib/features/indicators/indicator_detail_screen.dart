import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/reservoir_chart.dart';
import '../alerts/domain/alert.dart';
import '../alerts/presentation/alert_card.dart';
import '../reservoir/data/territory_data.dart';
import '../reservoir/domain/reservoir_models.dart';
import 'domain/series_stats.dart';
import 'indicator_charts.dart';

/// Detalhe de um indicador: definição, unidade, fonte, histórico, tendência e os alertas que ele
/// originou. Fecha o fluxo visão geral → indicador → alerta → justificativa.
class IndicatorDetailScreen extends ConsumerWidget {
  const IndicatorDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicator = IndicatorId.fromSlug(slug);
    final territory = ref.watch(territoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(indicator?.label ?? 'Indicador')),
      body: indicator == null
          ? const Padding(
              padding: EdgeInsets.all(PulsoSpacing.screen),
              child: EmptyState(title: 'Indicador não encontrado', message: 'Volte e escolha um indicador da lista.'),
            )
          : territory.when(
              loading: () => const Padding(padding: EdgeInsets.all(PulsoSpacing.screen), child: LoadingSkeleton()),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(PulsoSpacing.screen),
                child: ErrorState(onRetry: () => ref.invalidate(territoryProvider)),
              ),
              data: (t) => _Body(indicator: indicator, data: t.data),
            ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.indicator, required this.data});
  final IndicatorId indicator;
  final TerritoryData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final snapshot = ref.watch(reservoirProvider).valueOrNull?.data ?? data.reservoir;
    final alerts = (ref.watch(alertsProvider).valueOrNull ?? const <Alert>[])
        .where((a) => a.indicator == indicator)
        .toList();
    final def = _definition(indicator, snapshot, data.regions);

    return ListView(
      padding: const EdgeInsets.all(PulsoSpacing.screen),
      children: [
        // Valor atual + tendência.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.currentLabel, style: text.labelSmall?.copyWith(color: c.muted)),
                const SizedBox(height: 4),
                Text(def.current, style: text.headlineMedium),
                const SizedBox(height: PulsoSpacing.xs),
                DataSourceTag(real: def.real),
                if (def.trend != null) ...[
                  const SizedBox(height: PulsoSpacing.sm),
                  TrendLine(
                    trend: def.trend!,
                    unitPerStep: def.trendUnit,
                    tolerance: def.trendTolerance,
                    upIsGood: def.upIsGood,
                  ),
                  Text(def.trendWindow, style: text.bodyMedium?.copyWith(color: c.muted)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: PulsoSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text('Histórico', style: text.titleMedium)),
                const SizedBox(height: PulsoSpacing.md12),
                ...switch (indicator) {
                  IndicatorId.volume => [
                      ReservoirChart(
                        points: _last(snapshot.series, 180),
                        forecast: snapshot.forecast,
                        height: 200,
                      ),
                      const SizedBox(height: PulsoSpacing.md),
                      VolumeMonthlyChart(snapshot: snapshot, months: 24),
                    ],
                  IndicatorId.rain => [
                      RainWeeklyChart(snapshot: snapshot, weeks: 16),
                      const SizedBox(height: PulsoSpacing.md),
                      RainMonthlyChart(snapshot: snapshot, months: 24),
                    ],
                  IndicatorId.reports => [ReportsWeeklyChart(regions: data.regions)],
                },
              ],
            ),
          ),
        ),
        const SizedBox(height: PulsoSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text('Sobre o indicador', style: text.titleMedium)),
                const SizedBox(height: PulsoSpacing.sm),
                _Row('O que mede', def.what),
                _Row('Unidade', def.unit),
                _Row('Frequência', def.frequency),
                _Row('Fonte', def.source),
                _Row('Limitações', def.limits),
              ],
            ),
          ),
        ),
        const SizedBox(height: PulsoSpacing.md),
        Semantics(
          header: true,
          child: Text('Alertas gerados por este indicador', style: text.titleMedium),
        ),
        const SizedBox(height: PulsoSpacing.sm),
        if (alerts.isEmpty)
          EmptyState(
            title: 'Nenhum alerta ativo',
            message: indicator == IndicatorId.rain
                ? 'A chuva não dispara alerta sozinha: ela entra como fator da previsão do volume.'
                : 'As regras deste indicador não foram acionadas com os dados e limiares atuais.',
          )
        else
          for (final a in alerts)
            Padding(padding: const EdgeInsets.only(bottom: PulsoSpacing.sm), child: AlertCard(alert: a)),
        const SizedBox(height: PulsoSpacing.md),
        const HumanDecisionBanner(),
        const SizedBox(height: PulsoSpacing.xl),
      ],
    );
  }
}

List<ReservoirPoint> _last(List<ReservoirPoint> s, int days) {
  if (s.isEmpty) return s;
  final from = s.last.date.subtract(Duration(days: days));
  return s.where((p) => p.date.isAfter(from)).toList();
}

class _Def {
  const _Def({
    required this.currentLabel,
    required this.current,
    required this.real,
    required this.what,
    required this.unit,
    required this.frequency,
    required this.source,
    required this.limits,
    required this.trendUnit,
    required this.trendWindow,
    this.trend,
    this.trendTolerance = 0,
    this.upIsGood = true,
  });
  final String currentLabel;
  final String current;
  final bool real;
  final String what;
  final String unit;
  final String frequency;
  final String source;
  final String limits;
  final LinearTrend? trend;
  final String trendUnit;
  final String trendWindow;
  final double trendTolerance;
  final bool upIsGood;
}

_Def _definition(IndicatorId id, ReservoirSnapshot r, List<Region> regions) {
  final real = r.origin == DataOrigin.real;
  switch (id) {
    case IndicatorId.volume:
      final last30 = _last(r.series, 30);
      return _Def(
        currentLabel: 'ÚLTIMO DADO · ${Fmt.date(r.latest.date)} · FAIXA ${r.latest.band.label.toUpperCase()}',
        current: Fmt.percent(r.latest.volumePercent),
        real: real,
        what: 'Quanto da água utilizável do Sistema Cantareira está armazenada.',
        unit: '% do volume útil (0% = volume morto; 100% = cheio).',
        frequency: 'Diária. Previsão para 7 dias à frente.',
        source: r.sourceLabel,
        limits: 'Mede o sistema inteiro, não cada represa nem cada bairro. A previsão erra em média '
            '${r.forecast == null ? '—' : '±${Fmt.number(r.forecast!.sigma, 2)} p.p.'} em 7 dias.',
        trend: LinearTrend.fit([for (final p in last30) p.volumePercent]),
        trendUnit: 'p.p. por dia',
        trendWindow: 'Reta ajustada aos últimos 30 dias.',
        trendTolerance: 0.02,
      );
    case IndicatorId.rain:
      final weeks = SeriesStats.blocks(r.series, value: (p) => p.rainMm ?? 0, count: 8);
      final last7 = weeks.isEmpty ? 0.0 : weeks.last.value;
      return _Def(
        currentLabel: 'CHUVA NOS ÚLTIMOS 7 DIAS · ATÉ ${Fmt.date(r.latest.date)}',
        current: '${last7.round()} mm',
        real: real,
        what: 'Chuva média dos postos pluviométricos da bacia do Cantareira.',
        unit: 'Milímetros (mm): 1 mm = 1 litro por metro quadrado.',
        frequency: 'Diária, agregada por semana e por mês nos gráficos.',
        source: r.sourceLabel,
        limits: 'Média da bacia: não representa a chuva em cada bairro da RMSP. Entra na previsão do volume '
            'como fator, não gera alerta sozinha.',
        trend: LinearTrend.fit([for (final w in weeks) w.value]),
        trendUnit: 'mm por semana',
        trendWindow: 'Reta ajustada às últimas 8 semanas.',
        trendTolerance: 0.5,
      );
    case IndicatorId.reports:
      final totals = ReportsWeeklyChart.totals(regions);
      return _Def(
        currentLabel: 'REGISTROS NA ÚLTIMA SEMANA · ${regions.length} REGIÕES',
        current: totals.isEmpty ? '—' : '${totals.last}',
        real: regions.isNotEmpty && !regions.first.synthetic,
        what: 'Relatos de falta de água ou pressão baixa enviados pelos cidadãos, por região.',
        unit: 'Registros por semana; no ranking, registros por 100 mil habitantes.',
        frequency: 'Semanal (últimas 8 semanas).',
        source: 'Valores SINTÉTICOS de demonstração: não há base pública de ocorrências por região.',
        limits: 'Depende de quem tem acesso ao app e pode ter registros repetidos. Serve para triagem, '
            'não para medir o abastecimento.',
        trend: LinearTrend.fit([for (final t in totals) t.toDouble()]),
        trendUnit: 'registros por semana',
        trendWindow: 'Reta ajustada às últimas ${totals.length} semanas.',
        trendTolerance: 0.5,
        upIsGood: false,
      );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: PulsoSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelLarge),
          Text(value, style: text.bodyMedium),
        ],
      ),
    );
  }
}
