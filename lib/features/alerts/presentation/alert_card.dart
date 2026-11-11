import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/badges.dart';
import '../domain/alert.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert});
  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final text = Theme.of(context).textTheme;
    final accent = switch (alert.severity) {
      Severity.high => c.danger,
      Severity.moderate => c.warning,
      Severity.low => c.success,
    };
    final window = windowText(alert);

    return Semantics(
      button: true,
      label: 'Alerta: ${alert.title}. Risco ${alert.severity.label}. ${alert.confidence.label}. $window.'
          '${alert.reliable ? '' : ' Apenas informativo.'} Toque para ver como chegamos a este alerta.',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(Routes.alertDetail, pathParameters: {'id': alert.id}),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(PulsoSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: PulsoSpacing.md,
                          runSpacing: PulsoSpacing.sm,
                          children: [
                            _Labeled(label: 'RISCO', child: SeverityBadge(severity: alert.severity)),
                            _Labeled(label: 'CONFIANÇA', child: ConfidencePill(level: alert.confidence)),
                          ],
                        ),
                        const SizedBox(height: PulsoSpacing.md12),
                        Text(alert.title, style: text.titleMedium),
                        const SizedBox(height: PulsoSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: c.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                window,
                                style: text.bodyMedium?.copyWith(color: c.muted),
                              ),
                            ),
                            if (!alert.reliable)
                              Text('INFORMATIVO', style: text.labelSmall?.copyWith(color: c.warning))
                            else
                              DataSourceTag(real: alert.basedOnRealData),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Previsão de 07/11 a 14/11 (7 dias)" ou "Observado de 03/11 a 10/11 (7 dias)".
String windowText(Alert a) {
  final w = a.window;
  if (w == null) {
    return a.validUntil != null ? 'Até ${Fmt.date(a.validUntil!)}' : 'Observado na série atual';
  }
  final kind = w.kind == WindowKind.forecast ? 'Previsão' : 'Observado';
  return '$kind de ${Fmt.dayMonth(w.from)} a ${Fmt.dayMonth(w.to)}/${w.to.year} (${w.days} dias)';
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.pulso.muted)),
          const SizedBox(height: 4),
          child,
        ],
      );
}
