/// Faixas de operação do Sistema Cantareira — Resolução Conjunta ANA/DAEE nº 925/2017.
/// Limites em % do volume útil. O app usa as faixas como referência (sinal exploratório),
/// não como enquadramento oficial.
enum OperatingBand {
  normal(1, 'Normal', 60, double.infinity),
  attention(2, 'Atenção', 40, 60),
  alert(3, 'Alerta', 30, 40),
  restriction(4, 'Restrição', 20, 30),
  special(5, 'Especial', double.negativeInfinity, 20);

  const OperatingBand(this.level, this.label, this.lower, this.upper);

  /// 1 (Normal) … 5 (Especial). Maior = pior.
  final int level;
  final String label;

  /// Limite inferior (inclusivo) em %.
  final double lower;

  /// Limite superior (exclusivo) em %.
  final double upper;

  static OperatingBand of(double volumePercent) {
    for (final band in values) {
      if (volumePercent >= band.lower && volumePercent < band.upper) return band;
    }
    return special;
  }

  /// Próxima faixa pior, ou `null` se já é a Especial.
  OperatingBand? get worse => level < 5 ? values[level] : null;

  bool isWorseThan(OperatingBand other) => level > other.level;

  /// Frase curta para o cidadão (modo de leitura simples).
  String get citizenMeaning => switch (this) {
        normal => 'O reservatório está em situação normal.',
        attention => 'O nível pede atenção. Evitar desperdício já ajuda.',
        alert => 'O nível está baixo e a retirada de água é reduzida. Economizar em casa ajuda.',
        restriction => 'Há limite menor de retirada de água. Economizar em casa ajuda a preservar o reservatório.',
        special => 'Situação crítica: a retirada é fortemente limitada. Siga as orientações oficiais.',
      };
}
