import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/alerts/domain/alert.dart';
import 'package:pulso/features/alerts/domain/alert_engine.dart';
import 'package:pulso/features/alerts/domain/confidence.dart';
import 'package:pulso/features/reservoir/domain/operating_band.dart';
import 'package:pulso/features/reservoir/domain/reservoir_models.dart';

/// Série diária de [days] pontos terminando em [end], indo de [from] a [to] linearmente.
List<ReservoirPoint> linearSeries({
  required DateTime end,
  required int days,
  required double from,
  required double to,
}) {
  return [
    for (var i = 0; i < days; i++)
      ReservoirPoint(
        date: end.subtract(Duration(days: days - 1 - i)),
        volumePercent: from + (to - from) * i / (days - 1),
        rainMm: 1,
      ),
  ];
}

ReservoirSnapshot snapshot(List<ReservoirPoint> s, {Forecast? forecast}) => ReservoirSnapshot(
      name: 'Cantareira',
      series: s,
      origin: DataOrigin.real,
      sourceLabel: 'teste',
      forecast: forecast,
    );

void main() {
  final end = DateTime(2026, 11, 9);
  const engine = AlertEngine();

  group('OperatingBand', () {
    test('classifica pelos limites da Resolução 925/2017', () {
      expect(OperatingBand.of(60), OperatingBand.normal);
      expect(OperatingBand.of(59.9), OperatingBand.attention);
      expect(OperatingBand.of(32.99), OperatingBand.alert);
      expect(OperatingBand.of(20.2), OperatingBand.restriction);
      expect(OperatingBand.of(19.9), OperatingBand.special);
      expect(OperatingBand.of(-5), OperatingBand.special);
    });

    test('worse aponta a próxima faixa pior', () {
      expect(OperatingBand.normal.worse, OperatingBand.attention);
      expect(OperatingBand.restriction.worse, OperatingBand.special);
      expect(OperatingBand.special.worse, isNull);
    });
  });

  group('confiança', () {
    test('normalCdf aproxima valores conhecidos', () {
      expect(normalCdf(0), closeTo(0.5, 1e-6));
      expect(normalCdf(1.96), closeTo(0.975, 1e-3));
      expect(normalCdf(-1), closeTo(0.1587, 1e-3));
    });

    test('previsão 19,66% ±0,52 abaixo de 20% → ~74% → média', () {
      final p = probabilityBelow(predicted: 19.66, sigma: 0.52, threshold: 20);
      expect(p, closeTo(0.743, 0.01));
      expect(confidenceFromProbability(p), ConfidenceLevel.medium);
    });

    test('faixas de confiança', () {
      expect(confidenceFromProbability(0.59), ConfidenceLevel.low);
      expect(confidenceFromProbability(0.60), ConfidenceLevel.medium);
      expect(confidenceFromProbability(0.86), ConfidenceLevel.high);
    });
  });

  group('regra: previsão abaixo do limiar', () {
    final series = linearSeries(end: end, days: 30, from: 22, to: 20.3);

    test('emite alerta de gravidade alta ao ameaçar a faixa Especial', () {
      final f = Forecast(date: end.add(const Duration(days: 7)), value: 19.66, sigma: 0.52, method: 'Ridge');
      final alerts = engine.evaluate(reservoir: snapshot(series, forecast: f), now: end);
      final a = alerts.firstWhere((a) => a.ruleId == 'forecast_below_floor');
      expect(a.severity, Severity.high);
      expect(a.confidence, ConfidenceLevel.medium);
      expect(a.reliable, isTrue);
      expect(a.evidence, isNotEmpty);
      expect(a.limitations, isNotEmpty);
    });

    test('não emite quando a chance é menor que o mínimo', () {
      final f = Forecast(date: end.add(const Duration(days: 7)), value: 21.5, sigma: 0.5, method: 'Ridge');
      final alerts = engine.evaluate(reservoir: snapshot(series, forecast: f), now: end);
      expect(alerts.where((a) => a.ruleId == 'forecast_below_floor'), isEmpty);
    });

    test('limiar do gestor substitui o limite da faixa', () {
      final f = Forecast(date: end.add(const Duration(days: 7)), value: 24.5, sigma: 0.5, method: 'Ridge');
      final s = linearSeries(end: end, days: 30, from: 27, to: 25);
      final alerts = engine.evaluate(
        reservoir: snapshot(s, forecast: f),
        now: end,
        thresholds: const AlertThresholds(volumeFloor: 25),
      );
      expect(alerts.single.ruleId, 'forecast_below_floor');
      // 25% leva à faixa Restrição → gravidade alta.
      expect(alerts.single.severity, Severity.high);
    });
  });

  group('dados desatualizados', () {
    final series = linearSeries(end: end, days: 30, from: 22, to: 20.3);
    final f = Forecast(date: end.add(const Duration(days: 7)), value: 19.0, sigma: 0.3, method: 'Ridge');

    test('com mais de 3 dias, a confiança cai um nível', () {
      final fresh = engine.evaluate(reservoir: snapshot(series, forecast: f), now: end).first;
      final stale = engine
          .evaluate(reservoir: snapshot(series, forecast: f), now: end.add(const Duration(days: 5)))
          .first;
      expect(fresh.confidence, ConfidenceLevel.high);
      expect(stale.confidence, ConfidenceLevel.medium);
      expect(stale.limitations.first, contains('5 dias'));
    });

    test('com mais de 30 dias, o alerta vira informativo', () {
      final old = engine
          .evaluate(reservoir: snapshot(series, forecast: f), now: end.add(const Duration(days: 60)))
          .first;
      expect(old.reliable, isFalse);
      expect(old.confidence, ConfidenceLevel.low);
    });
  });

  group('regra: queda contínua', () {
    test('conta meses seguidos de queda', () {
      final s = linearSeries(end: end, days: 150, from: 50, to: 33);
      expect(consecutiveMonthlyDeclines(s), greaterThanOrEqualTo(4));
      final alerts = engine.evaluate(reservoir: snapshot(s), now: end);
      expect(alerts.any((a) => a.ruleId == 'continuous_decline'), isTrue);
    });

    test('série estável não gera alerta', () {
      final s = linearSeries(end: end, days: 150, from: 40, to: 40);
      expect(consecutiveMonthlyDeclines(s), 0);
      expect(engine.evaluate(reservoir: snapshot(s), now: end), isEmpty);
    });
  });

  group('regra: alta de ocorrências', () {
    final s = linearSeries(end: end, days: 30, from: 40, to: 40);

    test('alerta quando dobra e passa do mínimo', () {
      final alerts = engine.evaluate(
        reservoir: snapshot(s),
        now: end,
        regions: const [
          RegionActivity(regionId: 'zl2', regionName: 'Zona Leste 2', lastWeek: 9, previousWeek: 4, synthetic: true),
          RegionActivity(regionId: 'cen', regionName: 'Centro', lastWeek: 3, previousWeek: 1, synthetic: true),
        ],
      );
      expect(alerts, hasLength(1));
      expect(alerts.single.regionId, 'zl2');
      expect(alerts.single.basedOnRealData, isFalse);
      expect(alerts.single.limitations.first, contains('sintéticos'));
    });
  });

  test('ordena por gravidade (alto antes de moderado)', () {
    final s = linearSeries(end: end, days: 150, from: 50, to: 20.3);
    final f = Forecast(date: end.add(const Duration(days: 7)), value: 19.0, sigma: 0.3, method: 'Ridge');
    final alerts = engine.evaluate(reservoir: snapshot(s, forecast: f), now: end);
    expect(alerts.first.severity, Severity.high);
    expect(alerts.last.severity, Severity.moderate);
  });
}
