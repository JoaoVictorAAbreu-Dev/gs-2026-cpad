import 'package:flutter/material.dart';

import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../domain/report.dart';

/// Etapas vêm do status real do registro (salvo → envio → triagem → resposta).
class ReportStatusTimeline extends StatelessWidget {
  const ReportStatusTimeline({super.key, required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final sent = status == ReportStatus.sent || status == ReportStatus.triaged;
    final steps = [
      ('Salvo no aparelho', 'Anônimo, com protocolo.', true),
      (
        'Envio',
        sent ? 'Enviado para a equipe.' : 'Acontece sozinho quando houver internet.',
        sent,
      ),
      ('Triagem por uma pessoa da equipe', 'O registro entra nos indicadores de Serviços.', status == ReportStatus.triaged),
      ('Resposta', 'Acompanhe em Meus registros.', false),
    ];
    final text = Theme.of(context).textTheme;
    final c = context.pulso;

    return Column(
      children: [
        for (final (title, subtitle, done) in steps)
          Semantics(
            label: '$title: ${done ? 'concluído' : 'pendente'}. $subtitle',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: PulsoSpacing.md12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? c.success : c.muted),
                  const SizedBox(width: PulsoSpacing.md12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.bodyLarge),
                        Text(subtitle, style: text.bodyMedium?.copyWith(color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
