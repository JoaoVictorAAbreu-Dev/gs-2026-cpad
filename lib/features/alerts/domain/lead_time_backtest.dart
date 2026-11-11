import '../../reservoir/domain/reservoir_models.dart';
import '../../reservoir/domain/trend_forecaster.dart';
import 'confidence.dart';

/// Benefício social medido, não suposto: reexecuta a regra "previsão abaixo do limite da faixa"
/// em cada dia do histórico, usando só dados até aquele dia, e verifica com quantos dias de
/// antecedência o app teria avisado cada piora de faixa que de fato aconteceu.
class LeadTimeResult {
  const LeadTimeResult({
    required this.worsenings,
    required this.detected,
    required this.leadDays,
    required this.alertDays,
    required this.falseAlarmDays,
    required this.from,
    required this.to,
  });

  /// Pioras de faixa observadas no período.
  final int worsenings;

  /// Pioras precedidas de alerta.
  final int detected;

  /// Antecedência (dias) de cada piora detectada.
  final List<int> leadDays;

  /// Dias em que a regra teria disparado.
  final int alertDays;

  /// Dias com alerta sem piora de faixa nos [horizon] dias seguintes.
  final int falseAlarmDays;
  final DateTime from;
  final DateTime to;

  double? get averageLeadDays =>
      leadDays.isEmpty ? null : leadDays.reduce((a, b) => a + b) / leadDays.length;

  double? get precision => alertDays == 0 ? null : (alertDays - falseAlarmDays) / alertDays;
}

class LeadTimeBacktest {
  const LeadTimeBacktest({
    this.forecaster = const TrendForecaster(),
    this.horizon = 7,
    this.minProbability = 0.30,
    this.warmup = 30,
  });

  final TrendForecaster forecaster;
  final int horizon;
  final double minProbability;

  /// Dias iniciais sem avaliação (precisa de histórico para a tendência).
  final int warmup;

  LeadTimeResult run(List<ReservoirPoint> series) {
    final n = series.length;
    if (n <= warmup + horizon) {
      return LeadTimeResult(
        worsenings: 0, detected: 0, leadDays: const [], alertDays: 0, falseAlarmDays: 0,
        from: series.isEmpty ? DateTime(0) : series.first.date,
        to: series.isEmpty ? DateTime(0) : series.last.date,
      );
    }

    // 1. Em quais dias a regra dispararia (só olhando o passado).
    final alert = List<bool>.filled(n, false);
    for (var t = warmup; t < n; t++) {
      final band = series[t].band;
      final floor = band.lower;
      if (!floor.isFinite) continue; // já na pior faixa
      final start = t + 1 - forecaster.window < 0 ? 0 : t + 1 - forecaster.window;
      final f = forecaster.forecast(series.sublist(start, t + 1), horizonDays: horizon);
      if (f == null) continue;
      final p = probabilityBelow(predicted: f.value, sigma: f.sigma, threshold: floor);
      alert[t] = p >= minProbability;
    }

    // 2. Pioras de faixa (dia em que a faixa ficou pior que a do dia anterior).
    final worsenAt = <int>[
      for (var t = warmup + 1; t < n; t++)
        if (series[t].band.isWorseThan(series[t - 1].band)) t,
    ];

    // 3. Antecedência: primeiro dia de uma sequência contínua de alertas que termina na piora,
    //    olhando no máximo [horizon] dias para trás.
    final leads = <int>[];
    for (final t in worsenAt) {
      int? first;
      for (var k = t - 1; k >= t - horizon && k >= 0; k--) {
        if (alert[k]) {
          first = k;
        } else if (first != null) {
          break;
        }
      }
      if (first != null) leads.add(t - first);
    }

    // 4. Alarmes falsos: alerta sem piora nos próximos [horizon] dias.
    var alertDays = 0, falseAlarms = 0;
    for (var t = warmup; t < n - horizon; t++) {
      if (!alert[t]) continue;
      alertDays++;
      final hit = worsenAt.any((w) => w > t && w <= t + horizon);
      if (!hit) falseAlarms++;
    }

    return LeadTimeResult(
      worsenings: worsenAt.length,
      detected: leads.length,
      leadDays: leads,
      alertDays: alertDays,
      falseAlarmDays: falseAlarms,
      from: series[warmup].date,
      to: series.last.date,
    );
  }
}
