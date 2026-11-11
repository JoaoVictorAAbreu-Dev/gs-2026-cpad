/// Validação do formulário de limiares — funções puras, testadas em unidade.
abstract final class ThresholdsValidator {
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().replaceAll('%', '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// Volume mínimo: vazio = usar o limite da faixa atual; senão 1–99.
  static String? volumeFloor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = parseNumber(raw);
    if (v == null) return 'Digite um número, por exemplo 25 ou 25,5.';
    if (v < 1 || v > 99) return 'Use um valor entre 1% e 99%.';
    return null;
  }

  /// Chance mínima em %: 10–95 (abaixo disso, alerta demais; acima, quase nunca alerta).
  static String? minProbability(String? raw) {
    final v = parseNumber(raw);
    if (v == null) return 'Informe a chance mínima em %.';
    if (v < 10 || v > 95) return 'Use um valor entre 10% e 95%.';
    return null;
  }

  static String? declineMonths(String? raw) {
    final v = int.tryParse(raw?.trim() ?? '');
    if (v == null) return 'Informe um número inteiro de meses.';
    if (v < 1 || v > 12) return 'Use de 1 a 12 meses.';
    return null;
  }

  static String? surgeMinCount(String? raw) {
    final v = int.tryParse(raw?.trim() ?? '');
    if (v == null) return 'Informe um número inteiro.';
    if (v < 2 || v > 100) return 'Use de 2 a 100 registros.';
    return null;
  }

  static String? surgeRatio(String? raw) {
    final v = parseNumber(raw);
    if (v == null) return 'Digite um número, por exemplo 1,5.';
    if (v <= 1 || v > 10) return 'Use um valor maior que 1 e até 10.';
    return null;
  }
}
