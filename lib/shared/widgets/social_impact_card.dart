import 'package:flutter/material.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../features/alerts/domain/lead_time_backtest.dart';
import 'badges.dart';

/// Indicador de benefício social: antecedência medida pelo backtest sobre a série real.
class SocialImpactCard extends StatelessWidget {
  const SocialImpactCard({super.key, required this.result, required this.realData, this.compact = false});

  final LeadTimeResult result;
  final bool realData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final avg = result.averageLeadDays;
    final precision = result.precision;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Benefício social', style: text.titleMedium)),
                DataSourceTag(real: realData),
              ],
            ),
            const SizedBox(height: PulsoSpacing.md12),
            if (avg == null)
              Text('Ainda não houve piora de faixa no período para medir a antecedência.', style: text.bodyMedium)
            else ...[
              Semantics(
                label: '${Fmt.number(avg)} dias de antecedência média',
                excludeSemantics: true,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: PulsoSpacing.sm,
                  children: [
                    Text(Fmt.number(avg), style: text.displaySmall),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('dias de antecedência média', style: text.titleMedium),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PulsoSpacing.sm),
              Text(
                'Tempo extra para avisar a população e preparar a operação antes de o Cantareira mudar '
                'para uma faixa pior.',
                style: text.bodyMedium,
              ),
            ],
            if (!compact) ...[
              const SizedBox(height: PulsoSpacing.md12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PulsoSpacing.md12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(PulsoRadius.button),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Como medimos', style: text.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Reexecutamos a regra de alerta em cada dia de ${Fmt.date(result.from)} a '
                      '${Fmt.date(result.to)}, usando só os dados até aquele dia. '
                      'Pioras de faixa avisadas: ${result.detected} de ${result.worsenings}. '
                      'Dias com alerta: ${result.alertDays}, dos quais ${result.falseAlarmDays} sem piora '
                      'nos 7 dias seguintes'
                      '${precision == null ? '' : ' (acerto de ${(precision * 100).round()}%)'}. '
                      'A antecedência é limitada ao horizonte de 7 dias da previsão.',
                      style: text.bodyMedium?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
