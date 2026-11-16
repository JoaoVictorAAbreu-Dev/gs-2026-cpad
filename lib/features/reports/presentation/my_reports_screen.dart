import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback.dart';
import '../data/reports_controller.dart';
import '../domain/report.dart';
import 'copy_protocol_button.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);
    final pending = ref.watch(pendingReportsProvider);
    final online = ref.watch(simulatedOnlineProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus registros')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(Routes.newReport),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(PulsoSpacing.screen, PulsoSpacing.screen, PulsoSpacing.screen, 96),
        children: [
          if (pending > 0) ...[
            InfoBanner(
              icon: Icons.cloud_upload_outlined,
              title: '$pending aguardando internet',
              message: online
                  ? 'A conexão voltou. Toque para enviar agora.'
                  : 'Ficam salvos no aparelho e são enviados quando a conexão voltar.',
              actionLabel: online ? 'Enviar agora' : null,
              onAction: online
                  ? () async {
                      final n = await ref.read(reportsProvider.notifier).flushQueue();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n registro(s) enviados.')));
                      }
                    }
                  : null,
            ),
            const SizedBox(height: PulsoSpacing.md),
          ],
          if (reports.isEmpty)
            const EmptyState(
              title: 'Nenhum registro ainda',
              message: 'Quando você registrar uma ocorrência, ela aparece aqui com o status do envio.',
            ),
          for (final r in reports) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(PulsoSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r.type.label, style: text.titleMedium)),
                        _StatusChip(status: r.status),
                      ],
                    ),
                    const SizedBox(height: PulsoSpacing.xs),
                    Text('${r.regionName} · ${Fmt.date(r.createdAt)} ${Fmt.time(r.createdAt)}',
                        style: text.bodyMedium?.copyWith(color: context.pulso.muted)),
                    const SizedBox(height: PulsoSpacing.sm),
                    Text(r.description, style: text.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: PulsoSpacing.sm),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: PulsoSpacing.sm,
                      children: [
                        SelectableText('Protocolo ${r.protocol}', style: text.labelSmall),
                        CopyProtocolButton(protocol: r.protocol),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: PulsoSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final (fg, bg, icon) = switch (status) {
      ReportStatus.sent || ReportStatus.triaged => (c.success, c.successContainer, Icons.check),
      ReportStatus.queued => (c.warning, c.warningContainer, Icons.schedule),
      ReportStatus.savedLocally => (c.info, c.infoContainer, Icons.save_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PulsoRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(status.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
