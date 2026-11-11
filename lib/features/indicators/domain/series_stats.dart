import '../../reservoir/domain/reservoir_models.dart';

/// Agregados e tendências usados pelos três dashboards. Dart puro, testável sem Flutter.

/// Valor de um mês, com o mesmo mês do ano anterior quando a série cobre.
class MonthlyValue {
  const MonthlyValue({
    required this.month,
    required this.value,
    required this.days,
    required this.complete,
    this.previousYear,
  });

  /// Primeiro dia do mês.
  final DateTime month;
  final double value;
  final double? previousYear;

  /// Dias com dado no mês.
  final int days;

  /// `false` para o mês corrente ainda incompleto.
  final bool complete;
}

/// Tendência linear (mínimos quadrados) de uma sequência igualmente espaçada.
class LinearTrend {
  const LinearTrend({required this.slope, required this.intercept, required this.n});

  /// Variação por passo (dia, semana…).
  final double slope;
  final double intercept;
  final int n;

  double at(int i) => intercept + slope * i;

  /// Direção com zona morta: variações menores que [tolerance] por passo contam como estável.
  TrendDirection direction({double tolerance = 0}) {
    if (slope > tolerance) return TrendDirection.up;
    if (slope < -tolerance) return TrendDirection.down;
    return TrendDirection.flat;
  }

  static LinearTrend? fit(List<double> ys) {
    final n = ys.length;
    if (n < 2) return null;
    final mx = (n - 1) / 2;
    final my = ys.reduce((a, b) => a + b) / n;
    var sxy = 0.0, sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (i - mx) * (ys[i] - my);
      sxx += (i - mx) * (i - mx);
    }
    final slope = sxx == 0 ? 0.0 : sxy / sxx;
    return LinearTrend(slope: slope, intercept: my - slope * mx, n: n);
  }
}

enum TrendDirection { up, flat, down }

abstract final class SeriesStats {
  /// Agrega por mês: média do volume ([mean] = true) ou soma da chuva ([mean] = false).
  /// Retorna os últimos [months] meses, do mais antigo ao mais recente.
  static List<MonthlyValue> monthly(
    List<ReservoirPoint> series, {
    required double? Function(ReservoirPoint p) value,
    required bool mean,
    int months = 12,
  }) {
    if (series.isEmpty) return const [];
    final sums = <DateTime, double>{};
    final counts = <DateTime, int>{};
    for (final p in series) {
      final v = value(p);
      if (v == null) continue;
      final key = DateTime(p.date.year, p.date.month);
      sums[key] = (sums[key] ?? 0) + v;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    double? agg(DateTime k) {
      final c = counts[k];
      if (c == null || c == 0) return null;
      return mean ? sums[k]! / c : sums[k]!;
    }

    final last = series.last.date;
    final out = <MonthlyValue>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(last.year, last.month - i);
      final v = agg(m);
      if (v == null) continue;
      final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
      final prevKey = DateTime(m.year - 1, m.month);
      // Mês anterior só conta se estiver completo o bastante (≥ 90% dos dias).
      final prevDays = counts[prevKey] ?? 0;
      final prevComplete = prevDays >= DateTime(prevKey.year, prevKey.month + 1, 0).day * 0.9;
      out.add(MonthlyValue(
        month: m,
        value: v,
        days: counts[m]!,
        complete: counts[m]! >= daysInMonth,
        previousYear: prevComplete ? agg(prevKey) : null,
      ));
    }
    return out;
  }

  /// Soma por blocos de [size] dias terminando no último ponto (ex.: chuva semanal).
  static List<({DateTime end, double value})> blocks(
    List<ReservoirPoint> series, {
    required double Function(ReservoirPoint p) value,
    int size = 7,
    int count = 12,
  }) {
    final out = <({DateTime end, double value})>[];
    for (var b = 0; b < count; b++) {
      final endIdx = series.length - 1 - b * size;
      final startIdx = endIdx - size + 1;
      if (startIdx < 0) break;
      var sum = 0.0;
      for (var i = startIdx; i <= endIdx; i++) {
        sum += value(series[i]);
      }
      out.insert(0, (end: series[endIdx].date, value: sum));
    }
    return out;
  }

  static ({double min, DateTime minAt, double max, DateTime maxAt})? range(List<ReservoirPoint> pts) {
    if (pts.isEmpty) return null;
    var lo = pts.first, hi = pts.first;
    for (final p in pts) {
      if (p.volumePercent < lo.volumePercent) lo = p;
      if (p.volumePercent > hi.volumePercent) hi = p;
    }
    return (min: lo.volumePercent, minAt: lo.date, max: hi.volumePercent, maxAt: hi.date);
  }
}
