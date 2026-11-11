import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/pulso_logo.dart';
import '../settings/settings_controller.dart';

/// Consentimento explícito antes de qualquer uso. Lista o que é guardado e o que não é pedido.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;

    Widget box(String title, List<String> items, Color bg) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PulsoSpacing.md),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PulsoRadius.card)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.labelLarge),
              const SizedBox(height: PulsoSpacing.sm),
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('•  $i', style: text.bodyMedium),
                ),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(PulsoSpacing.lg),
              children: [
                const Align(alignment: Alignment.centerLeft, child: PulsoLogo(markSize: 36)),
                const SizedBox(height: PulsoSpacing.lg),
                Semantics(header: true, child: Text('Seus dados, suas regras', style: text.headlineMedium)),
                const SizedBox(height: PulsoSpacing.md),
                Text(
                  'O PULSO mostra indicadores do território e permite registrar ocorrências '
                  'sem identificar você.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: PulsoSpacing.lg),
                box('Guardamos só no seu aparelho', const [
                  'Preferências: tema e tamanho do texto',
                  'Seus registros: tipo, região e descrição, sem endereço',
                  'Última série de dados, para usar sem internet',
                ], c.infoContainer),
                const SizedBox(height: PulsoSpacing.md),
                box('Não pedimos', const [
                  'Nome, telefone, CPF, e-mail ou endereço.',
                  'Os registros seguem sem identificação para triagem por uma pessoa da equipe.',
                  'Você apaga tudo em Configurações › Apagar meus dados locais.',
                ], c.successContainer),
                const SizedBox(height: PulsoSpacing.md),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Li e concordo com o uso dos dados descrito acima.', style: text.bodyLarge),
                ),
                const SizedBox(height: PulsoSpacing.md),
                FilledButton(
                  onPressed: _agreed ? () => ref.read(settingsProvider.notifier).giveConsent() : null,
                  child: const Text('Aceitar e continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
