/// Formatação pt-BR sem depender de inicialização de locale (funciona em testes puros).
abstract final class Fmt {
  static String number(double v, [int digits = 1]) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  static String percent(double v, [int digits = 1]) => '${number(v, digits)}%';

  static String pp(double v, [int digits = 1]) {
    final sign = v > 0 ? '+' : (v < 0 ? '−' : '');
    return '$sign${number(v.abs(), digits)} p.p.';
  }

  static String date(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year}';

  static String dayMonth(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// Texto para leitor de tela: "20,2 por cento".
  static String spokenPercent(double v) => '${number(v)} por cento';

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// Texto para leitor de tela: "31 de dezembro de 2025".
  static String spokenDate(DateTime d) => '${d.day} de ${_months[d.month - 1]} de ${d.year}';

  static String shortMonth(DateTime d) => _months[d.month - 1].substring(0, 3);

  static String _two(int v) => v.toString().padLeft(2, '0');
}
