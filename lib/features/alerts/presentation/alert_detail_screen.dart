import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/feedback.dart';
import '../../reservoir/domain/reservoir_models.dart';
import '../domain/alert.dart';

/// "Como chegamos a este alerta?" — evidência, risco × confiança, limites e regra usada.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});
  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final alert = ref.watch(alertByIdProvider(alertId));

    return Scaffold(
      appBar: AppBar(title: const Text('Como chegamos a este alerta?')),
      body: alerts.isLoading
          ? const Padding(padding: EdgeInsets.all(PulsoSpacing.screen), child: LoadingSkeleton())
          : alert == null
              ? const Padding(
                  padding: EdgeInsets.all(PulsoSpacing.screen),
                  child: EmptyState(
                    title: 'Este alerta não está mais ativo',
                    message: 'Os dados ou os limiares mudaram e a regra deixou de ser acionada.',
                  ),
                )
              : _Body(alert: alert),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.alert});
  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final reservoir = ref.watch(reservoirProvider).valueOrNull?.data;
    final forwarded = ref.watch(decisionsProvider).where((d) => d.alertId == alert.id).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(PulsoSpacing.screen),
      children: [
        Text(alert.title, style: text.headlineMedium),
        const SizedBox(height: PulsoSpacing.sm),
        Text(alert.summary, style: text.bodyLarge),
        if (!alert.reliable) ...[
          const SizedBox(height: PulsoSpacing.md),
          InfoBanner(
            icon: Icons.report_gmailerrorred,
            title: 'Apenas informativo',
            message: alert.limitations.first,
          ),
        ],
        const SizedBox(height: PulsoSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Panel(
                color: c.dangerContainer,
                title: 'RISCO',
                badge: SeverityBadge(severity: alert.severity),
                body: switch (alert.severity) {
                  Severity.high => 'Se acontecer, o impacto é sério.',
                  Severity.moderate => 'Se acontecer, pede acompanhamento.',
                  Severity.low => 'Impacto pequeno se acontecer.',
                },
              ),
            ),
            const SizedBox(width: PulsoSpacing.md12),
            Expanded(
              child: _Panel(
                title: 'CONFIANÇA',
                badge: ConfidencePill(level: alert.confidence),
                body: alert.probability == null
                    ? alert.confidence.explanation
                    : '${alert.confidence.explanation} Chance estimada: '
                        '${(alert.probability! * 100).round()}%.',
              ),
            ),
          ],
        ),
        if (reservoir != null && reservoir.factors.isNotEmpty && alert.ruleId == 'forecast_below_floor') ...[
          const SizedBox(height: PulsoSpacing.md),
          _FactorsCard(factors: reservoir.factors),
        ],
        const SizedBox(height: PulsoSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(PulsoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text('Evidências', style: text.titleMedium)),
                const SizedBox(height: PulsoSpacing.sm),
                for (final e in alert.evidence)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.date == null ? e.label : '${e.label} (${Fmt.date(e.date!)})',
                            style: text.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: PulsoSpacing.sm),
                        Text(e.value, style: text.labelLarge),
                      ],
                    ),
                  ),
                const SizedBox(height: PulsoSpacing.xs),
                DataSourceTag(real: alert.basedOnRealData),
              ],
            ),
          ),
        ),
        const SizedBox(height: PulsoSpacing.md),
        _Expandable(
          title: 'Limitações e quando não confiar',
          initiallyExpanded: true,
          children: [for (final l in alert.limitations) _Bullet(l)],
        ),
        const SizedBox(height: PulsoSpacing.sm),
        _Expandable(title: 'Regra usada', children: [Text(alert.ruleDescription, style: text.bodyMedium)]),
        if (reservoir?.metrics != null) ...[
          const SizedBox(height: PulsoSpacing.sm),
          _Expandable(
            title: 'Dados e métricas do teste',
            children: [
              Text(
                'Erro médio em 7 dias: modelo ${Fmt.number(reservoir!.metrics!.maeModel, 2)} p.p. × '
                'repetir o valor de hoje ${Fmt.number(reservoir.metrics!.maeBaseline, 2)} p.p. '
                '(teste: ${reservoir.metrics!.testPeriod}).',
                style: text.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: PulsoSpacing.md),
        const HumanDecisionBanner(),
        const SizedBox(height: PulsoSpacing.md),
        if (forwarded != null)
          InfoBanner(
            icon: Icons.check_circle_outline,
            tone: BannerTone.info,
            title: 'Encaminhado para análise humana',
            message: 'Em ${Fmt.date(forwarded.at)}, ${Fmt.time(forwarded.at)}. '
                'A equipe decide os próximos passos. Nenhuma ação automática foi tomada.',
          )
        else
          FilledButton.icon(
            icon: const Icon(Icons.forward_to_inbox_outlined),
            label: const Text('Encaminhar para análise humana'),
            onPressed: () async {
              await ref.read(decisionsProvider.notifier).forward(alert);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Encaminhado. Nenhuma ação automática foi tomada.')),
                );
              }
            },
          ),
        const SizedBox(height: PulsoSpacing.xl),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.badge, required this.body, this.color});
  final String title;
  final Widget badge;
  final String body;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md12 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.labelSmall?.copyWith(color: context.pulso.muted)),
            const SizedBox(height: PulsoSpacing.sm),
            badge,
            const SizedBox(height: PulsoSpacing.sm),
            Text(body, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _FactorsCard extends StatelessWidget {
  const _FactorsCard({required this.factors});
  final List<ForecastFactor> factors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O que levou à previsão', style: text.titleMedium),
            const SizedBox(height: PulsoSpacing.sm),
            for (final f in factors)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(f.label, style: text.bodyMedium)),
                    Text(
                      Fmt.pp(f.contribution, 2),
                      style: text.labelLarge?.copyWith(
                        color: f.contribution < 0 ? c.danger : c.success,
                      ),
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

class _Expandable extends StatelessWidget {
  const _Expandable({required this.title, required this.children, this.initiallyExpanded = false});
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(PulsoSpacing.md, 0, PulsoSpacing.md, PulsoSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}
