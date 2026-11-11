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
}
