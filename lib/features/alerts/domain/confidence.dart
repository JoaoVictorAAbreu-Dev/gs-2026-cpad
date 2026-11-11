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

/// Explicação, em linguagem simples, de como a confiança de cada regra é calculada e de quando
/// ela cai. Mostrada no detalhe do alerta e documentada no README.
class ConfidenceMethod {
  const ConfidenceMethod({required this.how, required this.dropsWhen});

  final String how;
  final List<String> dropsWhen;

  static const _common = [
    'Dados com mais de 3 dias: a confiança cai um nível.',
    'Dados com mais de 30 dias: o alerta vira apenas informativo e não deve orientar decisão.',
  ];

  static ConfidenceMethod forRule(String ruleId, {double? sigma}) => switch (ruleId) {
        'forecast_below_floor' => ConfidenceMethod(
            how: 'Comparamos a previsão com o limite da faixa. Supondo que o erro da previsão segue uma '
                'curva normal com desvio de ${sigma == null ? 'σ' : '±${sigma.toStringAsFixed(2).replaceAll('.', ',')} p.p.'} '
                '(erro medido no teste do modelo), calculamos a chance de o volume real ficar abaixo do '
                'limite. Abaixo de 60%: confiança baixa. De 60% a 85%: média. Acima de 85%: alta.',
            dropsWhen: [
              ..._common,
              'Chuva muito acima ou abaixo do padrão recente: o modelo aprende com o histórico e erra mais.',
              'Mudança de operação (transferências entre sistemas, obras, rodízio) não entra no modelo.',
              'Sem previsão do modelo treinado, o app usa a tendência dos últimos 14 dias, que é mais frágil.',
              'Dados sintéticos: a confiança descreve a regra, não o mundo real.',
            ],
          ),
        'continuous_decline' => const ConfidenceMethod(
            how: 'Confiança alta porque a regra descreve o que já aconteceu: compara médias observadas de '
                'janelas de 30 dias, sem previsão.',
            dropsWhen: [
              ..._common,
              'No período seco (abril a setembro) a queda é esperada; a regra não diz se é anormal.',
            ],
          ),
        'occurrence_surge' => const ConfidenceMethod(
            how: 'Depende de quantos registros sustentam o alerta: abaixo de 3 vezes o mínimo da regra, '
                'confiança baixa; acima disso, média. Nunca é alta, porque registros dependem de quem '
                'usa o app.',
            dropsWhen: [
              'Poucos registros na semana: uma ou duas pessoas mudam o resultado.',
              'Regiões com menos acesso ao app aparecem menos, mesmo com o mesmo problema.',
              'Registros repetidos da mesma pessoa inflam a contagem.',
              'Dados sintéticos: a confiança descreve a regra, não o mundo real.',
            ],
          ),
        _ => const ConfidenceMethod(how: 'Regra sem método de confiança declarado.', dropsWhen: _common),
      };
}
