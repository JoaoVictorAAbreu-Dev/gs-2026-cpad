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
import '../alerts/presentation/alert_card.dart';
import '../reservoir/domain/reservoir_models.dart';
import '../settings/settings_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservoir = ref.watch(reservoirProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(territoryProvider.notifier).refresh(),
        child: AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : PulsoDurations.page,
          child: reservoir.when(
            loading: () => ListView(
              key: const ValueKey('loading'),
              padding: const EdgeInsets.all(PulsoSpacing.screen),
              children: const [LoadingSkeleton(), SizedBox(height: PulsoSpacing.md), LoadingSkeleton()],
            ),
            error: (e, _) => ListView(
              key: const ValueKey('error'),
              padding: const EdgeInsets.all(PulsoSpacing.screen),
              children: [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
            ),
            data: (result) => _Content(key: const ValueKey('data'), result: result, now: now),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({super.key, required this.result, required this.now});
  final DataResult<ReservoirSnapshot> result;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = result.data;
    final alerts = ref.watch(alertsProvider).valueOrNull ?? const [];
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(PulsoSpacing.screen),
      children: [
        FreshnessBanner(
          freshness: result.freshness,
          fetchedAt: result.fetchedAt,
          latestDataDate: r.latest.date,
          now: now,
          onRetry: () => ref.read(territoryProvider.notifier).refresh(),
        ),
        if (result.freshness == Freshness.cached || now.difference(r.latest.date).inDays > 3)
          const SizedBox(height: PulsoSpacing.md),
        _ReservoirCard(snapshot: r),
        const SizedBox(height: PulsoSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(header: true, child: Text('Alerta em destaque', style: text.titleLarge)),
            ),
            if (alerts.isNotEmpty)
              TextButton(
                onPressed: () => context.goNamed(Routes.alerts),
                child: Text('Ver todos (${alerts.length})'),
              ),
          ],
        ),
        const SizedBox(height: PulsoSpacing.sm),
        if (alerts.isEmpty)
          const EmptyState(
            title: 'Nenhum alerta agora',
            message: 'Não significa risco zero: nenhuma regra foi acionada com os dados atuais.',
          )
        else
          AlertCard(alert: alerts.first),
        const SizedBox(height: PulsoSpacing.md),
        const HumanDecisionBanner(),
        const SizedBox(height: PulsoSpacing.xl),
      ],
    );
  }
}

class _ReservoirCard extends ConsumerWidget {
  const _ReservoirCard({required this.snapshot});
  final ReservoirSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final last = snapshot.latest;
    final band = last.band;
    final yearChange = snapshot.changeOver(365);
    final entered = snapshot.enteredCurrentBandOn();
    final f = snapshot.forecast;
    final simple = ref.watch(settingsProvider.select((s) => s.simpleReading));
    final recent = snapshot.series.length > 30
        ? snapshot.series.sublist(snapshot.series.length - 30)
        : snapshot.series;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Cantareira · volume útil', style: text.titleMedium)),
                DataSourceTag(real: snapshot.origin == DataOrigin.real),
              ],
            ),
            const SizedBox(height: PulsoSpacing.md12),
            Semantics(
              label: 'Volume útil ${Fmt.spokenPercent(last.volumePercent)} em ${Fmt.spokenDate(last.date)}',
              excludeSemantics: true,
              child: Text(Fmt.percent(last.volumePercent), style: text.displaySmall?.copyWith(fontSize: 48)),
            ),
            const SizedBox(height: PulsoSpacing.sm),
            BandBadge(band: band),
            if (yearChange != null) ...[
              const SizedBox(height: PulsoSpacing.sm),
              Text(
                '${Fmt.pp(yearChange)} em 1 ano',
                style: text.labelLarge?.copyWith(color: yearChange < 0 ? c.danger : c.success),
              ),
            ],
            if (entered != null)
              Text(
                'Na faixa ${band.label} desde ${Fmt.date(entered)}',
                style: text.bodyMedium?.copyWith(color: c.muted),
              ),
            const SizedBox(height: PulsoSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PulsoSpacing.md12),
              decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(PulsoRadius.button)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('O que isso significa', style: text.labelLarge),
                  const SizedBox(height: 4),
                  Text(band.citizenMeaning, style: text.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: PulsoSpacing.md),
            ReservoirChart(points: recent, forecast: f),
            if (f != null) ...[
              const SizedBox(height: PulsoSpacing.sm),
              Text(
                simple
                    ? 'Em ${Fmt.dayMonth(f.date)}, o nível deve ficar perto de ${Fmt.percent(f.value)}.'
                    : 'Previsão para ${Fmt.dayMonth(f.date)}: ${Fmt.percent(f.value)} '
                        '(${Fmt.percent(f.lower)} a ${Fmt.percent(f.upper)}). Método: ${f.method}.',
                style: text.bodyMedium,
              ),
            ],
            const SizedBox(height: PulsoSpacing.sm),
            Text(
              'Fonte: ${snapshot.sourceLabel}. Sinal exploratório, não é alerta oficial.',
              style: text.bodyMedium?.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
