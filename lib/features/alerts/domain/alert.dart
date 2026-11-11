import 'confidence.dart';

/// Gravidade = impacto se acontecer. Independe da confiança (probabilidade).
enum Severity {
  high('Alto'),
  moderate('Moderado'),
  low('Baixo');

  const Severity(this.label);
  final String label;
}

/// Prazo: orienta o agrupamento "Prazo curto" / "Acompanhar".
enum AlertHorizon { shortTerm, monitor }

class Evidence {
  const Evidence({required this.label, required this.value, this.date});
  final String label;
  final String value;
  final DateTime? date;
}

/// Período a que o alerta se refere: o que já foi observado ou o que está sendo previsto.
enum WindowKind { observed, forecast }

class AlertWindow {
  const AlertWindow({required this.from, required this.to, required this.kind});
  final DateTime from;
  final DateTime to;
  final WindowKind kind;

  int get days => to.difference(from).inDays;
}

/// Indicadores que podem originar alertas (rota de detalhe do indicador).
enum IndicatorId {
  volume('volume', 'Volume útil do Sistema Cantareira'),
  rain('chuva', 'Chuva na bacia'),
  reports('registros', 'Registros de falta de água');

  const IndicatorId(this.slug, this.label);
  final String slug;
  final String label;

  static IndicatorId? fromSlug(String? slug) {
    for (final i in values) {
      if (i.slug == slug) return i;
    }
    return null;
  }
}

class Alert {
  const Alert({
    required this.id,
    required this.ruleId,
    required this.title,
    required this.summary,
    required this.severity,
    required this.confidence,
    required this.horizon,
    required this.evidence,
    required this.limitations,
    required this.ruleDescription,
    required this.basedOnRealData,
    this.probability,
    this.validUntil,
    this.regionId,
    this.reliable = true,
    this.window,
  });

  final String id;
  final String ruleId;
  final String title;

  /// Uma frase, linguagem simples.
  final String summary;
  final Severity severity;
  final ConfidenceLevel confidence;
  final AlertHorizon horizon;
  final List<Evidence> evidence;
  final List<String> limitations;
  final String ruleDescription;
  final bool basedOnRealData;

  /// Probabilidade estimada (0–1), quando a regra é probabilística.
  final double? probability;
  final DateTime? validUntil;
  final String? regionId;

  /// `false` quando os dados estão velhos demais: o alerta vira apenas informativo.
  final bool reliable;

  /// Janela temporal da evidência (observada) ou da previsão.
  final AlertWindow? window;

  /// Indicador que originou o alerta.
  IndicatorId get indicator => switch (ruleId) {
        'occurrence_surge' => IndicatorId.reports,
        _ => IndicatorId.volume,
      };
}
