import 'package:flutter/material.dart';

import '../../core/result/data_result.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';

/// Aviso fixo: alertas apoiam, não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(PulsoSpacing.md12),
        decoration: BoxDecoration(
          color: c.infoContainer,
          borderRadius: BorderRadius.circular(PulsoRadius.button),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_outline, color: c.info, size: 20),
            const SizedBox(width: PulsoSpacing.sm),
            Expanded(
              child: Text(
                'Apoio à decisão: os alertas orientam, mas a decisão final é sempre de uma pessoa.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BannerTone { info, warning, danger }

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = BannerTone.warning,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
  });

  final IconData actionIcon;
  final IconData icon;
  final String title;
  final String message;
  final BannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final (fg, bg) = switch (tone) {
      BannerTone.info => (c.info, c.infoContainer),
      BannerTone.warning => (c.warning, c.warningContainer),
      BannerTone.danger => (c.danger, c.dangerContainer),
    };
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(PulsoSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PulsoRadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: PulsoSpacing.sm),
              Expanded(child: Text(title, style: text.titleMedium)),
            ]),
            const SizedBox(height: PulsoSpacing.sm),
            Text(message, style: text.bodyMedium),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: PulsoSpacing.sm),
                child: TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mostra offline/desatualizado com base no `DataResult` — uma regra, todas as telas.
class FreshnessBanner extends StatelessWidget {
  const FreshnessBanner({
    super.key,
    required this.freshness,
    required this.fetchedAt,
    required this.latestDataDate,
    required this.now,
    this.onRetry,
  });

  final Freshness freshness;
  final DateTime fetchedAt;
  final DateTime latestDataDate;
  final DateTime now;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ageDays = now.difference(latestDataDate).inDays;
    if (freshness == Freshness.cached) {
      return InfoBanner(
        icon: Icons.wifi_off_rounded,
        title: 'Mostrando a última cópia salva',
        message: 'Não foi possível atualizar agora. Cópia salva em '
            '${Fmt.date(fetchedAt)}, ${Fmt.time(fetchedAt)}.',
        actionLabel: 'Tentar de novo',
        onAction: onRetry,
      );
    }
    if (ageDays > 3) {
      return InfoBanner(
        icon: Icons.schedule_rounded,
        title: 'Dados com mais de 3 dias',
        message: 'Último dado da série: ${Fmt.date(latestDataDate)}. '
            'Previsões feitas com dados antigos têm confiança reduzida.',
        actionLabel: 'Verificar agora',
        onAction: onRetry,
      );
    }
    return const SizedBox.shrink();
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.label = 'Carregando indicadores'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    Widget bar(double w) => Container(
          height: 14,
          width: w,
          margin: const EdgeInsets.only(top: PulsoSpacing.md12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
        );
    return Semantics(
      label: label,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(PulsoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              bar(160),
              bar(300),
              bar(220),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined});
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PulsoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: PulsoSpacing.sm),
              Expanded(child: Text(title, style: text.titleMedium)),
            ]),
            const SizedBox(height: PulsoSpacing.sm),
            Text(message, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => InfoBanner(
        icon: Icons.cloud_off_rounded,
        tone: BannerTone.danger,
        title: 'Não foi possível carregar',
        message: message ?? 'Sem dados salvos neste aparelho. Verifique a conexão e tente de novo.',
        actionLabel: 'Tentar de novo',
        onAction: onRetry,
      );
}
