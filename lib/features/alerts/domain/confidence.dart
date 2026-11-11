import 'dart:math' as math;

enum ConfidenceLevel {
  low('Confiança baixa', 'O modelo não tem certeza de que vai acontecer.'),
  medium('Confiança média', 'É provável, mas há incerteza relevante.'),
  high('Confiança alta', 'Os dados indicam com clareza.');

  const ConfidenceLevel(this.label, this.explanation);
  final String label;
  final String explanation;

  ConfidenceLevel get downgraded => switch (this) {
        high => medium,
        medium => low,
        low => low,
      };
}

/// Função de distribuição acumulada da normal padrão (aproximação de Abramowitz & Stegun 7.1.26,
/// erro < 1,5e-7) — suficiente para classificar confiança em faixas.
double normalCdf(double z) {
  final x = z.abs() / math.sqrt2;
  const p = 0.3275911;
  const a1 = 0.254829592, a2 = -0.284496736, a3 = 1.421413741, a4 = -1.453152027, a5 = 1.061405429;
  final t = 1 / (1 + p * x);
  final erf = 1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
  return z >= 0 ? 0.5 * (1 + erf) : 0.5 * (1 - erf);
}

/// Probabilidade de o valor real ficar abaixo de [threshold], dada a previsão [predicted] com
/// erro típico [sigma] (supõe erro aproximadamente normal — limitação declarada na interface).
double probabilityBelow({required double predicted, required double sigma, required double threshold}) {
  if (sigma <= 0) return predicted < threshold ? 1 : 0;
  return normalCdf((threshold - predicted) / sigma);
}

/// < 60% baixa · 60–85% média · > 85% alta.
ConfidenceLevel confidenceFromProbability(double p) {
  if (p > 0.85) return ConfidenceLevel.high;
  if (p >= 0.60) return ConfidenceLevel.medium;
  return ConfidenceLevel.low;
}
