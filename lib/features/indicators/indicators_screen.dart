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
import '../../shared/widgets/reservoir_chart.dart';
import '../reservoir/data/territory_data.dart';
import '../reservoir/domain/reservoir_models.dart';

enum IndicatorTab {
  climate('clima', 'Clima'),
  resources('recursos', 'Recursos'),
  services('servicos', 'Serviços');

  const IndicatorTab(this.slug, this.label);
  final String slug;
  final String label;

  static IndicatorTab fromSlug(String? slug) =>
      values.firstWhere((t) => t.slug == slug, orElse: () => IndicatorTab.resources);
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
            segments: [for (final t in IndicatorTab.values) ButtonSegment(value: t, label: Text(t.label))],
            selected: {widget.tab},
            showSelectedIcon: false,
            onSelectionChanged: (s) => context.goNamed(Routes.indicators, pathParameters: {'aba': s.first.slug}),
          ),
          // O período não se aplica a Serviços (janela fixa de 7 dias dos registros).
          if (widget.tab != IndicatorTab.services) ...[
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
            IndicatorTab.resources => reservoir.when<List<Widget>>(
                loading: () => const [LoadingSkeleton()],
                error: (_, __) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
                data: (r) => [_ResourcesTab(snapshot: r.data, days: _days)],
              ),
            IndicatorTab.services => territory.when<List<Widget>>(
                loading: () => const [LoadingSkeleton()],
                error: (_, __) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
                data: (t) => [_ServicesTab(regions: t.data.regions)],
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

List<ReservoirPoint> _lastDays(List<ReservoirPoint> s, int days) {
  final from = s.last.date.subtract(Duration(days: days));
  return s.where((p) => p.date.isAfter(from)).toList();
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.snapshot, required this.days});
  final ReservoirSnapshot snapshot;
  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final pts = _lastDays(snapshot.series, days);
    final change = snapshot.changeOver(days);
    final m = snapshot.metrics;

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
                  'Toque no gráfico para ver o valor de cada dia. Faixas de fundo: limites de referência '
                  'da Resolução ANA/DAEE 925/2017.',
                  style: text.bodyMedium?.copyWith(color: c.muted),
                ),
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
                Text('Quanto a previsão erra', style: text.titleMedium),
                const SizedBox(height: PulsoSpacing.sm),
                if (m != null) ...[
                  _ErrorBar(label: 'Repetir o valor de hoje', value: m.maeBaseline, max: m.maeBaseline),
                  _ErrorBar(label: 'Modelo', value: m.maeModel, max: m.maeBaseline),
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
      ],
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

class _ClimateTab extends StatelessWidget {
  const _ClimateTab({required this.snapshot, required this.days});
  final ReservoirSnapshot snapshot;
  final int days;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pts = _lastDays(snapshot.series, days);
    final rain = pts.fold<double>(0, (sum, p) => sum + (p.rainMm ?? 0));
    final rainyDays = pts.where((p) => (p.rainMm ?? 0) >= 1).length;

    return Card(
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
            const SizedBox(height: PulsoSpacing.md),
            Text(
              'Previsão do tempo para os próximos dias (Open-Meteo) entra na próxima etapa.',
              style: text.bodyMedium?.copyWith(color: context.pulso.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({required this.regions});
  final List<Region> regions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    if (regions.isEmpty) {
      return const EmptyState(title: 'Sem dados de serviços', message: 'O pacote de dados não trouxe regiões.');
    }
    final sorted = [...regions]..sort((a, b) => b.reportsPer100k.compareTo(a.reportsPer100k));
    final maxRate = sorted.first.reportsPer100k;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registros por 100 mil habitantes · últimos 7 dias', style: text.titleMedium),
            const SizedBox(height: PulsoSpacing.xs),
            DataSourceTag(real: !regions.first.synthetic),
            const SizedBox(height: PulsoSpacing.md12),
            for (final r in sorted)
              Semantics(
                label: '${r.name}: ${Fmt.number(r.reportsPer100k)} registros por 100 mil habitantes',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: PulsoSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(flex: 5, child: Text(r.name, style: text.bodyMedium)),
                      Expanded(
                        flex: 5,
                        child: LinearProgressIndicator(
                          value: maxRate == 0 ? 0 : r.reportsPer100k / maxRate,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          color: r == sorted.first ? c.forecast : c.muted,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(Fmt.number(r.reportsPer100k), textAlign: TextAlign.end, style: text.labelLarge),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: PulsoSpacing.sm),
            Text(
              'Normalizar pela população evita que regiões maiores pareçam sempre piores.',
              style: text.bodyMedium?.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
