import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/themes.dart';
import '../../core/theme/tokens.dart';
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
          SegmentedButton<PulsoThemeMode>(
            segments: const [
              ButtonSegment(value: PulsoThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: PulsoThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: PulsoThemeMode.dark, label: Text('Escuro')),
              ButtonSegment(value: PulsoThemeMode.highContrast, label: Text('Contraste')),
            ],
            selected: {s.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (v) => ctrl.setTheme(v.first),
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
