import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/feedback.dart';
import '../data/reports_controller.dart';
import '../domain/report.dart';
import 'report_status_timeline.dart';

class ReportSuccessScreen extends ConsumerWidget {
  const ReportSuccessScreen({super.key, required this.protocol});
  final String protocol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportsProvider).where((r) => r.protocol == protocol).firstOrNull;
    final text = Theme.of(context).textTheme;
    final c = context.pulso;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Padding(
          padding: EdgeInsets.all(PulsoSpacing.screen),
          child: EmptyState(title: 'Registro não encontrado', message: 'Ele pode ter sido apagado deste aparelho.'),
        ),
      );
    }
    final sent = report.status == ReportStatus.sent || report.status == ReportStatus.triaged;

    return Scaffold(
      appBar: AppBar(
        // Título reflete o estado real: não diz "enviado" se ainda está na fila.
        title: Text(sent ? 'Registro enviado' : 'Registro salvo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
          onPressed: () => context.goNamed(Routes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PulsoSpacing.screen),
        children: [
          const SizedBox(height: PulsoSpacing.md),
          Icon(Icons.check_circle, size: 72, color: c.success, semanticLabel: 'Sucesso'),
          const SizedBox(height: PulsoSpacing.md),
          Text(
            sent ? 'Obrigado! Seu registro foi enviado.' : 'Obrigado! Seu registro foi salvo.',
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
          const SizedBox(height: PulsoSpacing.sm),
          SelectableText(
            'Protocolo ${report.protocol}. Anônimo: guardamos só tipo, região, descrição e data.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: c.muted),
          ),
          if (!sent) ...[
            const SizedBox(height: PulsoSpacing.md),
            InfoBanner(
              icon: Icons.cloud_off_outlined,
              title: 'Sem internet agora',
              message: 'O envio acontece quando a conexão voltar. Você pode tentar em Meus registros.',
            ),
          ],
          const SizedBox(height: PulsoSpacing.lg),
          Text('O que acontece agora', textAlign: TextAlign.center, style: text.titleMedium),
          const SizedBox(height: PulsoSpacing.md),
          ReportStatusTimeline(status: report.status),
          const SizedBox(height: PulsoSpacing.lg),
          FilledButton(onPressed: () => context.goNamed(Routes.home), child: const Text('Voltar para a visão geral')),
          const SizedBox(height: PulsoSpacing.sm),
          OutlinedButton(onPressed: () => context.goNamed(Routes.myReports), child: const Text('Ver meus registros')),
        ],
      ),
    );
  }
}
