import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/feedback.dart';
import '../domain/alert.dart';
import 'alert_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(territoryProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Alertas', style: text.headlineMedium)),
                Text('Por gravidade e prazo', style: text.bodyMedium?.copyWith(color: context.pulso.muted)),
              ],
            ),
            const SizedBox(height: PulsoSpacing.md),
            ...alerts.when<List<Widget>>(
              loading: () => const [LoadingSkeleton(label: 'Calculando alertas')],
              error: (e, _) => [ErrorState(onRetry: () => ref.invalidate(territoryProvider))],
              data: (list) => _content(context, list),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, List<Alert> list) {
    final text = Theme.of(context).textTheme;
    final short = list.where((a) => a.horizon == AlertHorizon.shortTerm).toList();
    final monitor = list.where((a) => a.horizon == AlertHorizon.monitor).toList();
    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: PulsoSpacing.lg, bottom: PulsoSpacing.sm),
          child: Semantics(header: true, child: Text(title, style: text.labelLarge)),
        );

    return [
      _SeveritySummary(alerts: list),
      const SizedBox(height: PulsoSpacing.md),
      const HumanDecisionBanner(),
      if (list.isEmpty) ...[
        const SizedBox(height: PulsoSpacing.md),
        const EmptyState(
          title: 'Nenhum alerta agora',
          message: 'Não significa risco zero: nenhuma regra foi acionada com os dados atuais.',
        ),
      ],
      if (short.isNotEmpty) section('PRAZO CURTO'),
      for (final a in short) ...[AlertCard(alert: a), const SizedBox(height: PulsoSpacing.md12)],
      if (monitor.isNotEmpty) section('ACOMPANHAR'),
      for (final a in monitor) ...[AlertCard(alert: a), const SizedBox(height: PulsoSpacing.md12)],
      const SizedBox(height: PulsoSpacing.md),
      Text(
        'Risco e confiança são coisas diferentes: risco é o impacto se acontecer; '
        'confiança é o quanto os dados sustentam a previsão.',
        style: text.bodyMedium?.copyWith(color: context.pulso.muted),
      ),
    ];
  }
}

class _SeveritySummary extends StatelessWidget {
  const _SeveritySummary({required this.alerts});
  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final text = Theme.of(context).textTheme;
    Widget tile(Severity s, Color fg, Color bg) {
      final n = alerts.where((a) => a.severity == s).length;
      return Expanded(
        child: Semantics(
          label: '$n alertas de risco ${s.label}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(PulsoSpacing.md12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PulsoRadius.button)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$n', style: text.headlineMedium?.copyWith(color: fg)),
                Text(s.label, style: text.bodyMedium?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(Severity.high, c.danger, c.dangerContainer),
        const SizedBox(width: PulsoSpacing.sm),
        tile(Severity.moderate, c.warning, c.warningContainer),
        const SizedBox(width: PulsoSpacing.sm),
        tile(Severity.low, c.success, c.successContainer),
      ],
    );
  }
}
