import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/feedback.dart';
import '../alerts/domain/alert.dart';

/// Versão em lista do mapa (acessível). O cartograma hexagonal entra na próxima etapa.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territory = ref.watch(territoryProvider);
    final alerts = ref.watch(alertsProvider).valueOrNull ?? const <Alert>[];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppHeader(),
      body: territory.when(
        loading: () => const Padding(padding: EdgeInsets.all(PulsoSpacing.screen), child: LoadingSkeleton()),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          child: ErrorState(onRetry: () => ref.invalidate(territoryProvider)),
        ),
        data: (t) => ListView(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          children: [
            Semantics(header: true, child: Text('Regiões', style: text.headlineMedium)),
            const SizedBox(height: PulsoSpacing.md),
            for (final r in t.data.regions)
              Card(
                margin: const EdgeInsets.only(bottom: PulsoSpacing.sm),
                child: ListTile(
                  title: Text(r.name),
                  subtitle: Text('${r.lastWeek} registros em 7 dias (antes: ${r.previousWeek})'),
                  trailing: SeverityBadge(
                    severity: alerts.where((a) => a.regionId == r.id).firstOrNull?.severity ?? Severity.low,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
