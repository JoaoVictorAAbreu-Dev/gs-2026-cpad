import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/result/data_result.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/reservoir_chart.dart';
import '../../shared/widgets/social_impact_card.dart';
import '../reservoir/data/territory_data.dart';
import '../alerts/domain/alert.dart';
import '../map/region_risk.dart';
import '../reservoir/domain/reservoir_models.dart';
import '../weather/weather_repository.dart';
import 'domain/series_stats.dart';
import 'indicator_charts.dart';

/// Três dashboards temáticos. Os slugs antigos (`recursos`, `servicos`) continuam aceitos.
enum IndicatorTab {
  water('agua', 'Água', Icons.water_drop_outlined),
  climate('clima', 'Clima', Icons.cloud_outlined),
  risk('risco', 'Risco', Icons.crisis_alert_outlined);

  const IndicatorTab(this.slug, this.label, this.icon);
  final String slug;
  final String label;
  final IconData icon;

  static IndicatorTab fromSlug(String? slug) => switch (slug) {
        'recursos' => water,
        'servicos' => risk,
        _ => values.firstWhere((t) => t.slug == slug, orElse: () => water),
      };
}

class IndicatorsScreen extends ConsumerStatefulWidget {
  const IndicatorsScreen({super.key, required this.tab});
  final IndicatorTab tab;

  @override
  ConsumerState<IndicatorsScreen> createState() => _IndicatorsScreenState();
}

class _IndicatorsScreenState extends ConsumerState<IndicatorsScreen> {
  /// Estado local: período escolhido não interessa a outras telas.
  int _days = 90;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final territory = ref.watch(territoryProvider);
    final reservoir = ref.watch(reservoirProvider);

    return Scaffold(
      appBar: const AppHeader(),
      body: ListView(
        padding: const EdgeInsets.all(PulsoSpacing.screen),
        children: [
          Semantics(header: true, child: Text('Indicadores', style: text.headlineMedium)),
          const SizedBox(height: PulsoSpacing.md),
          SegmentedButton<IndicatorTab>(
            segments: [
              for (final t in IndicatorTab.values)
                ButtonSegment(value: t, label: Text(t.label), icon: Icon(t.icon, size: 18)),
            ],
            selected: {widget.tab},
            showSelectedIcon: false,
            onSelectionChanged: (s) => context.goNamed(Routes.indicators, pathParameters: {'aba': s.first.slug}),
          ),
          const SizedBox(height: PulsoSpacing.sm),
          Text(widget.tab.subtitle, style: text.bodyMedium?.copyWith(color: context.pulso.muted)),
          // O período não se aplica ao Risco territorial (histórico semanal fixo dos registros).
          if (widget.tab != IndicatorTab.risk) ...[
          const SizedBox(height: PulsoSpacing.md),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 dias')),
              ButtonSegment(value: 30, label: Text('30 dias')),
              ButtonSegment(value: 90, label: Text('90 dias')),
            ],
            selected: {_days},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          ],
          const SizedBox(height: PulsoSpacing.md),
          ...switch (widget.tab) {
            IndicatorTab.water => reservoir.when<List<Widget>>(
                loading: () => const [LoadingSkeleton()],
                error: (_, __) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
                data: (r) => [_WaterTab(snapshot: r.data, days: _days)],
              ),
            IndicatorTab.risk => territory.when<List<Widget>>(
                loading: () => const [LoadingSkeleton()],
                error: (_, __) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
                data: (t) => [
                  _RiskTab(regions: t.data.regions),
                  if (ref.watch(socialImpactProvider) case final impact?) ...[
                    const SizedBox(height: PulsoSpacing.md),
                    SocialImpactCard(result: impact, realData: t.data.reservoir.origin == DataOrigin.real),
                  ],
                ],
              ),
            IndicatorTab.climate => reservoir.when<List<Widget>>(
                loading: () => const [LoadingSkeleton()],
                error: (_, __) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
                data: (r) => [_ClimateTab(snapshot: r.data, days: _days)],
              ),
          },
          const SizedBox(height: PulsoSpacing.md),
          const HumanDecisionBanner(),
          const SizedBox(height: PulsoSpacing.xl),
        ],
      ),
    );
  }
}

extension on IndicatorTab {
  String get subtitle => switch (this) {
        IndicatorTab.water => 'Reservatório: volume útil, histórico mensal, tendência e previsão de 7 dias.',
        IndicatorTab.climate => 'Chuva na bacia: semanas e meses contra o ano anterior, e previsão do tempo.',
        IndicatorTab.risk => 'Risco territorial: registros de falta de água por região, histórico e projeção.',
      };
}

/// Botão "Ver detalhe do indicador" (rota nomeada com parâmetro).
class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.indicator});
  final IndicatorId indicator;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.pushNamed(Routes.indicatorDetail, pathParameters: {'indicador': indicator.slug}),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Detalhe do indicador e alertas'),
        ),
      );
}

/// Card de seção padrão dos dashboards: título, subtítulo opcional, conteúdo.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(title, style: text.titleMedium)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: text.bodyMedium?.copyWith(color: context.pulso.muted)),
            ],
            const SizedBox(height: PulsoSpacing.md12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Mini-indicador (valor + rótulo) usado nas faixas de resumo.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.all(PulsoSpacing.md12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(PulsoRadius.button),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: text.titleMedium?.copyWith(color: color)),
            Text(label, style: text.labelSmall?.copyWith(color: context.pulso.muted)),
          ],
        ),
      ),
    );
  }
}

List<ReservoirPoint> _lastDays(List<ReservoirPoint> s, int days) {
  final from = s.last.date.subtract(Duration(days: days));
  return s.where((p) => p.date.isAfter(from)).toList();
}

class _WaterTab extends StatelessWidget {
  const _WaterTab({required this.snapshot, required this.days});
  final ReservoirSnapshot snapshot;
  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final pts = _lastDays(snapshot.series, days);
    final change = snapshot.changeOver(days);
    final m = snapshot.metrics;
    final range = SeriesStats.range(pts);
    final trend = LinearTrend.fit([for (final p in pts) p.volumePercent]);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volume útil · $days dias + 7 previstos', style: text.titleMedium),
                const SizedBox(height: PulsoSpacing.xs),
                DataSourceTag(real: snapshot.origin == DataOrigin.real),
                const SizedBox(height: PulsoSpacing.md12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: PulsoSpacing.sm,
                  children: [
                    Text(Fmt.percent(snapshot.latest.volumePercent), style: text.headlineMedium),
                    if (change != null)
                      Text(
                        '${Fmt.pp(change)} em $days dias',
                        style: text.labelLarge?.copyWith(color: change < 0 ? c.danger : c.success),
                      ),
                  ],
                ),
                const SizedBox(height: PulsoSpacing.md),
                ReservoirChart(points: pts, forecast: snapshot.forecast, height: 220),
                const SizedBox(height: PulsoSpacing.sm),
                Text(
                  'Unidade: % do volume útil. Toque no gráfico para ver o valor de cada dia. Faixas de fundo: '
                  'limites de referência da Resolução ANA/DAEE 925/2017.',
                  style: text.bodyMedium?.copyWith(color: c.muted),
                ),
                if (trend != null) ...[
                  const SizedBox(height: PulsoSpacing.sm),
                  TrendLine(trend: trend, unitPerStep: 'p.p. por dia', tolerance: 0.02),
                ],
                const _DetailButton(indicator: IndicatorId.volume),
              ],
            ),
          ),
        ),
        if (range != null) ...[
          const SizedBox(height: PulsoSpacing.md),
          Wrap(
            spacing: PulsoSpacing.sm,
            runSpacing: PulsoSpacing.sm,
            children: [
              _Stat(label: 'Mínimo em $days dias (${Fmt.dayMonth(range.minAt)})', value: Fmt.percent(range.min)),
              _Stat(label: 'Máximo em $days dias (${Fmt.dayMonth(range.maxAt)})', value: Fmt.percent(range.max)),
              _Stat(label: 'Faixa atual', value: snapshot.latest.band.label),
              if (snapshot.forecast != null)
                _Stat(
                  label: 'Previsão para ${Fmt.dayMonth(snapshot.forecast!.date)}',
                  value: Fmt.percent(snapshot.forecast!.value),
                  color: c.forecast,
                ),
            ],
          ),
        ],
        const SizedBox(height: PulsoSpacing.md),
        _Section(
          title: 'Histórico mensal do volume',
          subtitle: 'Média de cada mês nos últimos 12 meses, contra o mesmo mês do ano anterior.',
          children: [VolumeMonthlyChart(snapshot: snapshot)],
        ),
        const SizedBox(height: PulsoSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quanto a previsão erra', style: text.titleMedium),
                const SizedBox(height: PulsoSpacing.sm),
                if (m != null) ...[
                  _ErrorBar(label: 'Repetir o valor de hoje', value: m.maeBaseline, max: m.maeBaseline),
                  _ErrorBar(
                    label: snapshot.forecast?.method ?? 'Modelo',
                    value: m.maeModel,
                    max: m.maeBaseline,
                  ),
                  Text(
                    'Erro médio em 7 dias: ${(m.improvement * 100).round()}% menor que repetir o valor de hoje '
                    '(teste: ${m.testPeriod}).',
                    style: text.bodyMedium,
                  ),
                ] else
                  Text(
                    snapshot.forecast == null
                        ? 'Sem previsão disponível para esta série.'
                        : 'Previsão por ${snapshot.forecast!.method.toLowerCase()}, com erro típico de '
                            '±${Fmt.number(snapshot.forecast!.sigma, 2)} p.p. Métricas de teste do modelo '
                            'aparecem aqui quando o pacote de dados trouxer a previsão do modelo treinado.',
                    style: text.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
        if (snapshot.factors.isNotEmpty && snapshot.forecast != null) ...[
          const SizedBox(height: PulsoSpacing.md),
          _FactorsCard(snapshot: snapshot),
        ],
      ],
    );
  }
}

/// "O que levou à previsão": decomposição exata da previsão linear do Ridge.
class _FactorsCard extends StatelessWidget {
  const _FactorsCard({required this.snapshot});
  final ReservoirSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final f = snapshot.forecast!;
    final maxAbs = snapshot.factors.map((x) => x.contribution.abs()).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O que levou à previsão de ${Fmt.percent(f.value)}', style: text.titleMedium),
            const SizedBox(height: PulsoSpacing.md12),
            _FactorRow(label: 'Último dado (${Fmt.dayMonth(snapshot.latest.date)})', value: Fmt.percent(snapshot.latest.volumePercent)),
            for (final x in snapshot.factors)
              Semantics(
                label: '${x.label}: ${x.contribution >= 0 ? 'mais' : 'menos'} ${Fmt.number(x.contribution.abs(), 2)} pontos',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PulsoSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FactorRow(
                        label: x.label,
                        value: Fmt.pp(x.contribution, 2),
                        color: x.contribution < 0 ? c.danger : c.success,
                      ),
                      const SizedBox(height: 4),
                      LayoutBuilder(
                        builder: (context, box) {
                          final half = box.maxWidth / 2;
                          final w = maxAbs == 0 ? 0.0 : half * x.contribution.abs() / maxAbs;
                          return SizedBox(
                            height: 8,
                            child: Stack(
                              children: [
                                Positioned(left: half, top: 0, bottom: 0, child: Container(width: 1, color: c.muted)),
                                Positioned(
                                  left: x.contribution < 0 ? half - w : half,
                                  width: w,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: x.contribution < 0 ? c.danger : c.success,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            _FactorRow(label: 'Previsão para ${Fmt.dayMonth(f.date)}', value: Fmt.percent(f.value), color: c.forecast),
            const SizedBox(height: PulsoSpacing.sm),
            Text(
              'Contribuição de cada fator no modelo ${f.method}, em pontos percentuais. A soma dos fatores é a '
              'variação prevista em 7 dias. Erro típico: ±${Fmt.number(f.sigma, 2)} p.p.',
              style: text.bodyMedium?.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: PulsoSpacing.sm),
          Text(value, style: text.labelLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.label, required this.value, required this.max});
  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: PulsoSpacing.md12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: text.bodyMedium)),
            Text('${Fmt.number(value, 2)} p.p.', style: text.labelLarge),
          ]),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: max == 0 ? 0 : value / max,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            semanticsLabel: '$label: erro de ${Fmt.number(value, 2)} pontos',
          ),
        ],
      ),
    );
  }
}

class _ClimateTab extends ConsumerWidget {
  const _ClimateTab({required this.snapshot, required this.days});
  final ReservoirSnapshot snapshot;
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final pts = _lastDays(snapshot.series, days);
    final rain = pts.fold<double>(0, (sum, p) => sum + (p.rainMm ?? 0));
    final rainyDays = pts.where((p) => (p.rainMm ?? 0) >= 1).length;

    // Mesmo período um ano antes, quando a série cobre.
    final end = snapshot.latest.date.subtract(const Duration(days: 365));
    final start = end.subtract(Duration(days: days));
    final lastYear = snapshot.series.where((p) => p.date.isAfter(start) && !p.date.isAfter(end)).toList();
    final rainLastYear = lastYear.length >= days * 0.9
        ? lastYear.fold<double>(0, (sum, p) => sum + (p.rainMm ?? 0))
        : null;

    final weather = ref.watch(weatherProvider);
    final weekly = SeriesStats.blocks(snapshot.series, value: (p) => p.rainMm ?? 0, count: 12);
    final weeklyTrend = LinearTrend.fit([for (final w in weekly) w.value]);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chuva na bacia · $days dias', style: text.titleMedium),
                const SizedBox(height: PulsoSpacing.xs),
                DataSourceTag(real: snapshot.origin == DataOrigin.real),
                const SizedBox(height: PulsoSpacing.md12),
                Text('${rain.round()} mm', style: text.headlineMedium),
                Text('$rainyDays dias com chuva de 1 mm ou mais', style: text.bodyMedium),
                if (rainLastYear != null) ...[
                  const SizedBox(height: PulsoSpacing.sm),
                  Text(
                    'Mesmo período do ano anterior: ${rainLastYear.round()} mm '
                    '(${rain >= rainLastYear ? '+' : '−'}${(rain - rainLastYear).abs().round()} mm).',
                    style: text.labelLarge?.copyWith(color: rain >= rainLastYear ? c.success : c.danger),
                  ),
                ],
                const SizedBox(height: PulsoSpacing.sm),
                Text(
                  'Unidade: milímetros (mm). Média dos postos pluviométricos do sistema (Sabesp). '
                  'Não mostra a chuva em cada bairro.',
                  style: text.bodyMedium?.copyWith(color: c.muted),
                ),
                const _DetailButton(indicator: IndicatorId.rain),
              ],
            ),
          ),
        ),
        const SizedBox(height: PulsoSpacing.md),
        _Section(
          title: 'Chuva por semana · 12 semanas',
          subtitle: 'Cada barra soma 7 dias até a data indicada.',
          children: [
            RainWeeklyChart(snapshot: snapshot),
            if (weeklyTrend != null) TrendLine(trend: weeklyTrend, unitPerStep: 'mm por semana', tolerance: 0.5),
          ],
        ),
        const SizedBox(height: PulsoSpacing.md),
        _Section(
          title: 'Chuva por mês · histórico',
          subtitle: 'Total de cada mês contra o mesmo mês do ano anterior (marcador cinza).',
          children: [RainMonthlyChart(snapshot: snapshot)],
        ),
        const SizedBox(height: PulsoSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próximos dias na represa · Open-Meteo', style: text.titleMedium),
                const SizedBox(height: PulsoSpacing.md12),
                ...weather.when<List<Widget>>(
                  loading: () => [const LinearProgressIndicator()],
                  error: (_, __) => [Text('Previsão do tempo indisponível agora.', style: text.bodyMedium)],
                  data: (result) {
                    if (result == null) {
                      return [
                        Text(
                          'Sem conexão e sem previsão salva neste aparelho.',
                          style: text.bodyMedium,
                        ),
                        TextButton.icon(
                          onPressed: () => ref.invalidate(weatherProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Tentar de novo'),
                        ),
                      ];
                    }
                    return [
                      if (result.freshness == Freshness.cached)
                        Padding(
                          padding: const EdgeInsets.only(bottom: PulsoSpacing.sm),
                          child: Text(
                            'Cópia salva em ${Fmt.date(result.fetchedAt)}, ${Fmt.time(result.fetchedAt)}.',
                            style: text.bodyMedium?.copyWith(color: c.warning),
                          ),
                        ),
                      Wrap(
                        spacing: PulsoSpacing.sm,
                        runSpacing: PulsoSpacing.sm,
                        children: [for (final d in result.data) _WeatherDay(day: d)],
                      ),
                      const SizedBox(height: PulsoSpacing.sm),
                      Text(
                        'Previsão meteorológica externa, próxima à represa Jaguari-Jacareí. '
                        'Não entra no modelo de volume.',
                        style: text.bodyMedium?.copyWith(color: c.muted),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherDay extends StatelessWidget {
  const _WeatherDay({required this.day});
  final DailyWeather day;

  static const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wd = _weekdays[day.date.weekday - 1];
    final temp = day.maxTemp.isNaN ? '—' : '${day.maxTemp.round()}°';
    return Semantics(
      label: '$wd ${Fmt.dayMonth(day.date)}: máxima $temp, chuva ${Fmt.number(day.rainMm)} milímetros'
          '${day.rainProbability == null ? '' : ', chance de ${day.rainProbability} por cento'}',
      excludeSemantics: true,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: PulsoSpacing.sm, horizontal: PulsoSpacing.xs),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(PulsoRadius.button),
        ),
        child: Column(
          children: [
            Text(wd, style: text.labelLarge),
            Text(temp, style: text.titleMedium),
            Text('${day.rainMm.round()} mm', style: text.bodyMedium),
            if (day.rainProbability != null) Text('${day.rainProbability}%', style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _RiskTab extends StatelessWidget {
  const _RiskTab({required this.regions});
  final List<Region> regions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    if (regions.isEmpty) {
      return const EmptyState(title: 'Sem dados de regiões', message: 'O pacote de dados não trouxe regiões.');
    }
    final sorted = [...regions]..sort((a, b) => b.reportsPer100k.compareTo(a.reportsPer100k));
    final maxRate = sorted.first.reportsPer100k;
    int count(Severity s, Severity Function(Region) f) => regions.where((r) => f(r) == s).length;
    final totals = ReportsWeeklyChart.totals(regions);
    final trend = LinearTrend.fit([for (final t in totals) t.toDouble()]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Regiões por nível de risco',
          subtitle: 'Hoje e projeção ingênua para +7 dias (repete a variação da última semana).',
          children: [
            DataSourceTag(real: !regions.first.synthetic),
            const SizedBox(height: PulsoSpacing.md12),
            Wrap(
              spacing: PulsoSpacing.sm,
              runSpacing: PulsoSpacing.sm,
              children: [
                _Stat(label: 'Alto hoje', value: '${count(Severity.high, RegionRisk.today)}', color: c.danger),
                _Stat(label: 'Moderado hoje', value: '${count(Severity.moderate, RegionRisk.today)}', color: c.warning),
                _Stat(label: 'Alto em +7 dias', value: '${count(Severity.high, RegionRisk.in7Days)}', color: c.danger),
                _Stat(label: 'Total na semana', value: totals.isEmpty ? '—' : '${totals.last} registros'),
              ],
            ),
            const SizedBox(height: PulsoSpacing.sm),
            Text(
              'Alto: ${RegionRisk.highFrom} ou mais registros na semana. Moderado: ${RegionRisk.moderateFrom} a '
              '${RegionRisk.highFrom - 1}.',
              style: text.bodyMedium?.copyWith(color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: PulsoSpacing.md),
        _Section(
          title: 'Registros de falta de água por semana',
          subtitle: 'Soma das ${regions.length} regiões nas últimas ${totals.length} semanas.',
          children: [
            ReportsWeeklyChart(regions: regions),
            if (trend != null)
              TrendLine(trend: trend, unitPerStep: 'registros por semana', tolerance: 0.5, upIsGood: false),
            const _DetailButton(indicator: IndicatorId.reports),
          ],
        ),
        const SizedBox(height: PulsoSpacing.md),
        _Section(
          title: 'Registros por 100 mil habitantes · últimos 7 dias',
          subtitle: 'Normalizar pela população evita que regiões maiores pareçam sempre piores.',
          children: [
            for (final r in sorted)
              Semantics(
                label: '${r.name}: ${Fmt.number(r.reportsPer100k)} registros por 100 mil habitantes, '
                    'risco ${RegionRisk.today(r).label}, ${r.lastWeek >= r.previousWeek ? 'subiu' : 'caiu'} '
                    'em relação à semana anterior',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PulsoSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text(r.name, style: text.bodyMedium)),
                      Expanded(
                        flex: 4,
                        child: LinearProgressIndicator(
                          value: maxRate == 0 ? 0 : r.reportsPer100k / maxRate,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          color: switch (RegionRisk.today(r)) {
                            Severity.high => c.danger,
                            Severity.moderate => c.warning,
                            Severity.low => c.muted,
                          },
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(Fmt.number(r.reportsPer100k), textAlign: TextAlign.end, style: text.labelLarge),
                      ),
                      Icon(
                        r.lastWeek > r.previousWeek
                            ? Icons.arrow_upward
                            : (r.lastWeek < r.previousWeek ? Icons.arrow_downward : Icons.remove),
                        size: 16,
                        color: r.lastWeek > r.previousWeek ? c.danger : c.muted,
                      ),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.goNamed(Routes.map),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Ver no mapa'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
