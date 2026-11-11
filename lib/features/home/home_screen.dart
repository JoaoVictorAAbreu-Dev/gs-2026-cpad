import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        const _BandChangeNotice(),
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
        if (ref.watch(socialImpactProvider) case final impact?) ...[
          const SizedBox(height: PulsoSpacing.md),
          SocialImpactCard(result: impact, realData: r.origin == DataOrigin.real, compact: true),
        ],
        const SizedBox(height: PulsoSpacing.md),
        FilledButton.icon(
          onPressed: () => context.pushNamed(Routes.newReport),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Registrar ocorrência'),
        ),
        const SizedBox(height: PulsoSpacing.sm),
        OutlinedButton(
          onPressed: () => context.pushNamed(Routes.myReports),
          child: const Text('Meus registros'),
        ),
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
            // Wrap: com fonte grande a etiqueta desce de linha em vez de espremer o título.
            Wrap(
              spacing: PulsoSpacing.sm,
              runSpacing: PulsoSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('Cantareira · volume útil', style: text.titleMedium),
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
            const SizedBox(height: PulsoSpacing.xs),
            FilledButton.tonalIcon(
              onPressed: () => context.pushNamed(Routes.indicatorDetail, pathParameters: {'indicador': 'volume'}),
              icon: const Icon(Icons.show_chart, size: 18),
              label: const Text('Ver detalhe do indicador'),
            ),
            TextButton.icon(
              onPressed: () => _copySummary(context, snapshot),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar resumo para compartilhar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Texto curto para mandar no WhatsApp/e-mail — sempre com fonte e o aviso de sinal exploratório.
Future<void> _copySummary(BuildContext context, ReservoirSnapshot s) async {
  final last = s.latest;
  final year = s.changeOver(365);
  final f = s.forecast;
  final summary = [
    'PULSO · ${s.name}',
    '${Fmt.percent(last.volumePercent)} do volume útil em ${Fmt.date(last.date)} '
        '(faixa ${last.band.label}, ref.)',
    if (year != null) '${Fmt.pp(year)} em um ano',
    if (f != null) 'Previsão para ${Fmt.date(f.date)}: ${Fmt.percent(f.value)} (±${Fmt.number(f.sigma, 1)} p.p.)',
    'Fonte: ${s.sourceLabel}. Sinal exploratório, não é alerta oficial.',
  ].join('\n');
  await Clipboard.setData(ClipboardData(text: summary));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resumo copiado.')));
  }
}

/// Aviso quando a faixa mudou desde a última visita (substitui notificação push nesta versão).
class _BandChangeNotice extends ConsumerWidget {
  const _BandChangeNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = ref.watch(bandChangeProvider);
    if (change == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: PulsoSpacing.md),
      child: InfoBanner(
        icon: change.improved ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        tone: change.improved ? BannerTone.info : BannerTone.danger,
        title: 'A faixa mudou desde sua última visita',
        message: '${change.from.label} → ${change.to.label}. ${change.to.citizenMeaning}',
        actionLabel: 'Entendi',
        actionIcon: Icons.check,
        onAction: () => ref.read(bandChangeProvider.notifier).markSeen(),
      ),
    );
  }
}
