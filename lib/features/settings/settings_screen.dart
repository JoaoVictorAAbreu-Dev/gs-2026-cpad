import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/themes.dart';
import '../../core/theme/tokens.dart';
import '../notifications/band_notification_policy.dart';
import '../notifications/notification_service.dart';
import '../reports/data/reports_controller.dart';
import '../reservoir/domain/operating_band.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;

    Widget header(String t) => Padding(
          padding: const EdgeInsets.only(top: PulsoSpacing.lg, bottom: PulsoSpacing.sm),
          child: Semantics(header: true, child: Text(t, style: text.labelLarge)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações e privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(PulsoSpacing.screen),
        children: [
          header('Tema'),
          // Chips em Wrap: com texto grande os rótulos descem de linha em vez de quebrar palavras.
          Wrap(
            spacing: PulsoSpacing.sm,
            runSpacing: PulsoSpacing.sm,
            children: [
              for (final (mode, label, icon) in const [
                (PulsoThemeMode.system, 'Sistema', Icons.brightness_auto_outlined),
                (PulsoThemeMode.light, 'Claro', Icons.light_mode_outlined),
                (PulsoThemeMode.dark, 'Escuro', Icons.dark_mode_outlined),
                (PulsoThemeMode.highContrast, 'Alto contraste', Icons.contrast),
              ])
                ChoiceChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  selected: s.themeMode == mode,
                  showCheckmark: false,
                  onSelected: (_) => ctrl.setTheme(mode),
                ),
            ],
          ),
          header('Tamanho do texto'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(PulsoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('A'),
                    Expanded(
                      child: Slider(
                        value: s.textScale,
                        min: 1,
                        max: 2,
                        divisions: 4,
                        label: '${(s.textScale * 100).round()}%',
                        semanticFormatterCallback: (v) => 'Texto em ${(v * 100).round()} por cento',
                        onChanged: ctrl.setTextScale,
                      ),
                    ),
                    Text('A', style: text.headlineMedium),
                  ]),
                  Text('Prévia · ${(s.textScale * 100).round()}%', style: text.labelSmall),
                  const SizedBox(height: 4),
                  Text('Volume útil do Cantareira na última medição', style: text.bodyLarge),
                ],
              ),
            ),
          ),
          header('Notificações'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Avisar quando a faixa mudar'),
                  subtitle: const Text(
                    'Notificação do sistema, uma vez por mudança. Verificada ao abrir o app e ao atualizar os dados.',
                  ),
                  value: s.notifyBandChange,
                  onChanged: (on) => _toggleNotifications(context, ref, on),
                ),
                ListTile(
                  title: const Text('Enviar notificação de teste'),
                  subtitle: const Text('Para conferir se o aparelho mostra os avisos.'),
                  trailing: const Icon(Icons.notifications_active_outlined),
                  enabled: s.notifyBandChange,
                  onTap: () => ref.read(notificationServiceProvider).show(
                        id: 99,
                        title: 'Teste · ${BandNotificationPolicy.title(OperatingBand.alert, OperatingBand.restriction)}',
                        body: 'Exemplo do aviso que o PULSO envia quando o Cantareira muda de faixa.',
                      ),
                ),
              ],
            ),
          ),
          header('Acessibilidade e privacidade'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Reduzir animações'),
                  subtitle: const Text('Também segue a configuração do sistema.'),
                  value: s.reduceMotion,
                  onChanged: ctrl.setReduceMotion,
                ),
                SwitchListTile(
                  title: const Text('Modo de leitura simples'),
                  subtitle: const Text('Frases curtas, sem termos técnicos.'),
                  value: s.simpleReading,
                  onChanged: ctrl.setSimpleReading,
                ),
                SwitchListTile(
                  title: const Text('Simular sem internet'),
                  subtitle: const Text('Demonstração: novos registros ficam na fila até religar.'),
                  value: !ref.watch(simulatedOnlineProvider),
                  onChanged: (offline) => ref.read(simulatedOnlineProvider.notifier).state = !offline,
                ),
                ListTile(
                  title: const Text('Meus registros'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(Routes.myReports),
                ),
                ListTile(
                  title: const Text('Limiares de alerta'),
                  subtitle: const Text('Para gestores: quando o app deve avisar.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(Routes.thresholds),
                ),
                ListTile(
                  title: Text('Apagar meus dados locais', style: TextStyle(color: context.pulso.danger)),
                  subtitle: const Text('Registros, preferências, decisões e cache deste aparelho.'),
                  trailing: Icon(Icons.delete_outline, color: context.pulso.danger),
                  onTap: () => _confirmErase(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: PulsoSpacing.md),
          if (s.consentAt != null)
            Text(
              'Consentimento dado em ${s.consentAt!.day.toString().padLeft(2, '0')}/'
              '${s.consentAt!.month.toString().padLeft(2, '0')}/${s.consentAt!.year}.',
              style: text.bodyMedium?.copyWith(color: context.pulso.muted),
            ),
          const SizedBox(height: PulsoSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(BuildContext context, WidgetRef ref, bool on) async {
    final ctrl = ref.read(settingsProvider.notifier);
    if (!on) {
      await ctrl.setNotifyBandChange(false);
      return;
    }
    final granted = await ref.read(notificationServiceProvider).requestPermission();
    await ctrl.setNotifyBandChange(granted);
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão negada. Libere as notificações do PULSO nas configurações do aparelho.'),
        ),
      );
    }
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar dados deste aparelho?'),
        content: const Text(
          'Registros, preferências, limiares e decisões salvos aqui serão apagados. '
          'Não dá para desfazer. Você verá a tela de consentimento de novo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) await ref.read(settingsProvider.notifier).eraseLocalData();
  }
}
