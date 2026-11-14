import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/pulso_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/pii_detector.dart';
import '../../reservoir/data/territory_data.dart';
import '../data/reports_controller.dart';
import '../domain/report.dart';

/// Registro em 4 etapas: Tipo → Local → Descrição → Revisar.
/// Estado do formulário é local (StatefulWidget); só o registro final vai para o estado global.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.initialRegionId});
  final String? initialRegionId;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  static const _steps = ['Tipo', 'Local', 'Descrição', 'Revisar'];

  int _step = 0;
  ReportType? _type;
  String? _regionId;
  final _description = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _descriptionKey = GlobalKey<FormFieldState<String>>();
  String? _stepError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _regionId = widget.initialRegionId;
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  String? _validateCurrent() => switch (_step) {
        0 => ReportValidator.type(_type),
        1 => ReportValidator.region(_knownRegionId(_regionId)),
        2 => ReportValidator.description(_description.text),
        _ => null,
      };

  void _next() {
    final error = _validateCurrent();
    if (_step == 2) _descriptionKey.currentState?.validate();
    if (error != null) {
      setState(() => _stepError = error);
      HapticFeedback.mediumImpact();
      unawaited(SemanticsService.sendAnnouncement(View.of(context), error, TextDirection.ltr));
      if (_step == 2) _descriptionFocus.requestFocus();
      return;
    }
    setState(() {
      _stepError = null;
      _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() {
        _stepError = null;
        _step--;
      });
    }
  }

  Future<void> _submit(List<Region> regions) async {
    final region = regions.where((r) => r.id == _regionId).firstOrNull;
    if (_type == null || region == null) {
      // Dados da região ainda não carregaram ou a região deixou de existir: volta para a etapa.
      setState(() {
        _step = _type == null ? 0 : 1;
        _stepError = _type == null ? ReportValidator.type(null) : ReportValidator.region(null);
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      final report = await ref.read(reportsProvider.notifier).create(
            type: _type!,
            regionId: region.id,
            regionName: region.name,
            description: _description.text,
          );
      if (!mounted) return;
      context.goNamed(Routes.reportSuccess, pathParameters: {'protocol': report.protocol});
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o registro. Tente de novo.')),
      );
    }
  }

  /// `null` quando o id não corresponde a nenhuma região carregada.
  String? _knownRegionId(String? id) {
    final regions = ref.read(territoryProvider).valueOrNull?.data.regions ?? const <Region>[];
    return regions.any((r) => r.id == id) ? id : null;
  }

  @override
  Widget build(BuildContext context) {
    final regions = ref.watch(territoryProvider).valueOrNull?.data.regions ?? const <Region>[];
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar ocorrência'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: PulsoSpacing.md),
              child: Center(child: Text('${_step + 1} de 4', style: text.labelLarge)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(PulsoSpacing.screen),
          children: [
            _Stepper(steps: _steps, current: _step),
            const SizedBox(height: PulsoSpacing.md),
            if (_step > 0) ...[
              _Summary(
                type: _type,
                region: regions.where((r) => r.id == _regionId).firstOrNull,
                showRegion: _step > 1,
                onEditType: () => setState(() => _step = 0),
                onEditRegion: () => setState(() => _step = 1),
              ),
              const SizedBox(height: PulsoSpacing.md),
            ],
            ...switch (_step) {
              0 => _typeStep(text),
              1 => _regionStep(text, regions),
              2 => _descriptionStep(text),
              _ => _reviewStep(text, regions),
            },
            if (_stepError != null && _step != 2) ...[
              const SizedBox(height: PulsoSpacing.sm),
              Text(_stepError!, style: text.bodyMedium?.copyWith(color: context.pulso.danger)),
            ],
            const SizedBox(height: PulsoSpacing.lg),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _submitting ? null : _back, child: const Text('Voltar'))),
                const SizedBox(width: PulsoSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : (_step == 3 ? () => _submit(regions) : _next),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_step == 3 ? 'Enviar' : 'Continuar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PulsoSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _typeStep(TextTheme text) => [
        Semantics(header: true, child: Text('O que está acontecendo?', style: text.titleLarge)),
        const SizedBox(height: PulsoSpacing.sm),
        RadioGroup<ReportType>(
          groupValue: _type,
          onChanged: (v) => setState(() {
            _type = v;
            _stepError = null;
          }),
          child: Column(
            children: [
              for (final t in ReportType.values)
                RadioListTile<ReportType>(value: t, title: Text(t.label), contentPadding: EdgeInsets.zero),
            ],
          ),
        ),
      ];

  List<Widget> _regionStep(TextTheme text, List<Region> regions) => [
        Semantics(header: true, child: Text('Onde?', style: text.titleLarge)),
        const SizedBox(height: PulsoSpacing.xs),
        Text(
          'Só a região. Não pedimos endereço.',
          style: text.bodyMedium?.copyWith(color: context.pulso.muted),
        ),
        const SizedBox(height: PulsoSpacing.md),
        DropdownButtonFormField<String>(
          // Região vinda do mapa (?regiao=) só é pré-selecionada se existir na lista.
          initialValue: regions.any((r) => r.id == _regionId) ? _regionId : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Região *'),
          items: [for (final r in regions) DropdownMenuItem(value: r.id, child: Text(r.name))],
          onChanged: (v) => setState(() {
            _regionId = v;
            _stepError = null;
          }),
        ),
      ];

  List<Widget> _descriptionStep(TextTheme text) {
    final pii = PiiDetector.kinds(_description.text);
    final length = _description.text.trim().length;
    return [
      Semantics(header: true, child: Text('Conte o que aconteceu', style: text.titleLarge)),
      const SizedBox(height: PulsoSpacing.md),
      TextFormField(
        key: _descriptionKey,
        controller: _description,
        focusNode: _descriptionFocus,
        minLines: 4,
        maxLines: 8,
        maxLength: ReportValidator.maxDescription,
        textCapitalization: TextCapitalization.sentences,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: ReportValidator.description,
        decoration: InputDecoration(
          labelText: 'Descrição *',
          alignLabelWithHint: true,
          helperText: length >= ReportValidator.minDescription
              ? 'Tudo certo. Toque em Continuar para revisar.'
              : 'Mínimo de ${ReportValidator.minDescription} caracteres.',
        ),
      ),
      if (pii.isNotEmpty) ...[
        const SizedBox(height: PulsoSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(PulsoSpacing.md12),
            decoration: BoxDecoration(
              color: context.pulso.warningContainer,
              borderRadius: BorderRadius.circular(PulsoRadius.button),
            ),
            child: Text(
              'Parece que há ${pii.map((k) => k.label).join(', ')} no texto. '
              'Isso será removido antes de salvar.',
              style: text.bodyMedium,
            ),
          ),
        ),
      ],
      const SizedBox(height: PulsoSpacing.sm),
      Container(
        padding: const EdgeInsets.all(PulsoSpacing.md12),
        decoration: BoxDecoration(
          color: context.pulso.infoContainer,
          borderRadius: BorderRadius.circular(PulsoRadius.button),
        ),
        child: Text(
          'Dica: diga desde quando e se afeta só sua casa ou a rua. Não inclua nomes, telefones ou endereço.',
          style: text.bodyMedium,
        ),
      ),
    ];
  }

  List<Widget> _reviewStep(TextTheme text, List<Region> regions) {
    final masked = PiiDetector.mask(_description.text.trim());
    return [
      Semantics(header: true, child: Text('Revise antes de enviar', style: text.titleLarge)),
      const SizedBox(height: PulsoSpacing.md),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(PulsoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descrição que será salva', style: text.labelLarge),
              const SizedBox(height: PulsoSpacing.xs),
              Text(masked, style: text.bodyLarge),
              TextButton(onPressed: () => setState(() => _step = 2), child: const Text('Editar descrição')),
            ],
          ),
        ),
      ),
      const SizedBox(height: PulsoSpacing.md),
      Text(
        'O registro é anônimo: guardamos só tipo, região, descrição e data.',
        style: text.bodyMedium?.copyWith(color: context.pulso.muted),
      ),
    ];
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.steps, required this.current});
  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'Etapa ${current + 1} de ${steps.length}: ${steps[current]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= current ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i < current ? '✓ ${steps[i]}' : steps[i],
                    style: (i == current ? text.labelLarge : text.bodyMedium),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.type,
    required this.region,
    required this.showRegion,
    required this.onEditType,
    required this.onEditRegion,
  });

  final ReportType? type;
  final Region? region;
  final bool showRegion;
  final VoidCallback onEditType;
  final VoidCallback onEditRegion;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(IconData icon, String label, VoidCallback onEdit) => Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: PulsoSpacing.sm),
            Expanded(child: Text(label, style: text.bodyMedium)),
            TextButton(onPressed: onEdit, child: const Text('Editar')),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PulsoSpacing.md12, vertical: PulsoSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PulsoRadius.button),
      ),
      child: Column(
        children: [
          row(Icons.check, 'Tipo: ${type?.label ?? '—'}', onEditType),
          if (showRegion) row(Icons.place_outlined, 'Região: ${region?.name ?? '—'} (sem endereço)', onEditRegion),
        ],
      ),
    );
  }
}
