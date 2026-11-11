import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../alerts/domain/alert_engine.dart';
import 'thresholds_validator.dart';

/// Formulário do gestor: quando o app deve gerar alertas.
/// Validação ao sair do campo e ao salvar; foco vai para o primeiro campo inválido.
class ThresholdsScreen extends ConsumerStatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  ConsumerState<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends ConsumerState<ThresholdsScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _floor;
  late final TextEditingController _prob;
  late final TextEditingController _months;
  late final TextEditingController _surgeCount;
  late final TextEditingController _surgeRatio;

  @override
  void initState() {
    super.initState();
    final t = ref.read(thresholdsProvider);
    _floor = TextEditingController(text: t.volumeFloor == null ? '' : Fmt.number(t.volumeFloor!));
    _prob = TextEditingController(text: (t.minProbability * 100).round().toString());
    _months = TextEditingController(text: '${t.declineMonths}');
    _surgeCount = TextEditingController(text: '${t.surgeMinCount}');
    _surgeRatio = TextEditingController(text: Fmt.number(t.surgeRatio));
  }

  @override
  void dispose() {
    for (final c in [_floor, _prob, _months, _surgeCount, _surgeRatio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      SemanticsService.announce('Há campos com erro. Revise antes de salvar.', TextDirection.ltr);
      return;
    }
    final t = AlertThresholds(
      volumeFloor: ThresholdsValidator.parseNumber(_floor.text),
      minProbability: ThresholdsValidator.parseNumber(_prob.text)! / 100,
      declineMonths: int.parse(_months.text.trim()),
      surgeMinCount: int.parse(_surgeCount.text.trim()),
      surgeRatio: ThresholdsValidator.parseNumber(_surgeRatio.text)!,
    );
    await ref.read(thresholdsProvider.notifier).save(t);
    if (!mounted) return;
    final count = ref.read(alertsProvider).valueOrNull?.length ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Limiares salvos. $count alerta(s) com as novas regras.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await ref.read(thresholdsProvider.notifier).reset();
    if (!mounted) return;
    const d = AlertThresholds();
    setState(() {
      _floor.text = '';
      _prob.text = (d.minProbability * 100).round().toString();
      _months.text = '${d.declineMonths}';
      _surgeCount.text = '${d.surgeMinCount}';
      _surgeRatio.text = Fmt.number(d.surgeRatio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = ref.watch(reservoirProvider).valueOrNull?.data.latest;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final integer = [FilteringTextInputFormatter.digitsOnly];

    Widget field({
      required TextEditingController controller,
      required String label,
      required String helper,
      required String? Function(String?) validator,
      required List<TextInputFormatter> formatters,
      String? suffix,
      TextInputAction action = TextInputAction.next,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: PulsoSpacing.md),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label, helperText: helper, helperMaxLines: 3, suffixText: suffix),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            textInputAction: action,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          children: [
            Text(
              'Defina quando o PULSO deve gerar alertas. Os alertas continuam sendo só apoio: '
              'nenhuma ação acontece sem uma pessoa decidir.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: PulsoSpacing.lg),
            Semantics(header: true, child: Text('Reservatório', style: text.titleMedium)),
            const SizedBox(height: PulsoSpacing.sm),
            field(
              controller: _floor,
              label: 'Avisar abaixo de (opcional)',
              helper: current == null
                  ? 'Vazio = limite da faixa atual.'
                  : 'Vazio = limite da faixa atual (${current.band.label}, a partir de '
                      '${current.band.lower.isFinite ? Fmt.percent(current.band.lower, 0) : '—'}).',
              validator: ThresholdsValidator.volumeFloor,
              formatters: decimal,
              suffix: '%',
            ),
            field(
              controller: _prob,
              label: 'Chance mínima para alertar',
              helper: 'Mais baixo = mais alertas e mais alarmes falsos.',
              validator: ThresholdsValidator.minProbability,
              formatters: integer,
              suffix: '%',
            ),
            field(
              controller: _months,
              label: 'Meses seguidos de queda',
              helper: 'Para o alerta "queda contínua".',
              validator: ThresholdsValidator.declineMonths,
              formatters: integer,
            ),
            const SizedBox(height: PulsoSpacing.sm),
            Semantics(header: true, child: Text('Ocorrências por região', style: text.titleMedium)),
            const SizedBox(height: PulsoSpacing.sm),
            field(
              controller: _surgeCount,
              label: 'Mínimo de registros na semana',
              helper: 'Evita alerta com poucos registros.',
              validator: ThresholdsValidator.surgeMinCount,
              formatters: integer,
            ),
            field(
              controller: _surgeRatio,
              label: 'Aumento em relação à semana anterior',
              helper: 'Ex.: 1,5 = 50% a mais.',
              validator: ThresholdsValidator.surgeRatio,
              formatters: decimal,
              suffix: '×',
              action: TextInputAction.done,
            ),
            Text(
              'O aviso de erro aparece ao sair do campo ou ao salvar.',
              style: text.bodyMedium?.copyWith(color: context.pulso.muted),
            ),
            const SizedBox(height: PulsoSpacing.lg),
            FilledButton(onPressed: _save, child: const Text('Salvar limiares')),
            const SizedBox(height: PulsoSpacing.sm),
            OutlinedButton(onPressed: _reset, child: const Text('Restaurar padrão')),
            const SizedBox(height: PulsoSpacing.xl),
          ],
        ),
      ),
    );
  }
}
