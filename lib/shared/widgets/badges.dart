import 'package:flutter/material.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../features/alerts/domain/alert.dart';
import '../../features/alerts/domain/confidence.dart';
import '../../features/reservoir/domain/operating_band.dart';

/// "DADOS REAIS" / "DADOS SINTÉTICOS" — exigência de transparência em todo card com número.
class DataSourceTag extends StatelessWidget {
  const DataSourceTag({super.key, required this.real});
  final bool real;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final fg = real ? c.success : c.forecast;
    final bg = real ? c.successContainer : c.forecastContainer;
    return Semantics(
      label: real ? 'Dados reais' : 'Dados sintéticos de demonstração',
      excludeSemantics: true,
      child: _Pill(text: real ? 'DADOS REAIS' : 'DADOS SINTÉTICOS', fg: fg, bg: bg),
    );
  }
}

/// Gravidade sempre com ícone + texto, nunca só cor.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final (fg, bg, icon) = switch (severity) {
      Severity.high => (c.danger, c.dangerContainer, Icons.square_rounded),
      Severity.moderate => (c.warning, c.warningContainer, Icons.change_history_rounded),
      Severity.low => (c.success, c.successContainer, Icons.circle),
    };
    return Semantics(
      label: 'Risco ${severity.label}',
      excludeSemantics: true,
      child: _Pill(text: severity.label, fg: fg, bg: bg, icon: icon),
    );
  }
}

class ConfidencePill extends StatelessWidget {
  const ConfidencePill({super.key, required this.level});
  final ConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bars = switch (level) {
      ConfidenceLevel.low => 1,
      ConfidenceLevel.medium => 2,
      ConfidenceLevel.high => 3,
    };
    return Semantics(
      label: level.label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PulsoRadius.full),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 3,
                height: 5.0 + i * 3,
                margin: const EdgeInsets.only(right: 2),
                color: i < bars ? scheme.primary : scheme.outlineVariant,
              ),
            const SizedBox(width: 6),
            Text(level.label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class BandBadge extends StatelessWidget {
  const BandBadge({super.key, required this.band});
  final OperatingBand band;

  @override
  Widget build(BuildContext context) {
    final c = context.pulso;
    final (fg, bg) = switch (band) {
      OperatingBand.normal => (c.success, c.successContainer),
      OperatingBand.attention || OperatingBand.alert => (c.warning, c.warningContainer),
      OperatingBand.restriction || OperatingBand.special => (c.danger, c.dangerContainer),
    };
    return _Pill(text: 'Faixa ${band.label} (ref.)', fg: fg, bg: bg, large: true);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fg, required this.bg, this.icon, this.large = false});
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = (large ? Theme.of(context).textTheme.labelLarge : Theme.of(context).textTheme.labelSmall)
        ?.copyWith(color: fg);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8, vertical: large ? 5 : 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PulsoRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: fg), const SizedBox(width: 6)],
          Flexible(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
