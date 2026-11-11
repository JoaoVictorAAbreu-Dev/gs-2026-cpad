import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/alerts/domain/alert.dart';
import 'package:pulso/features/alerts/domain/alert_engine.dart';
import 'package:pulso/features/indicators/domain/series_stats.dart';
import 'package:pulso/features/reservoir/domain/reservoir_models.dart';

List<ReservoirPoint> _series(DateTime start, int days, double Function(int i) vol, {double rain = 1}) => [
      for (var i = 0; i < days; i++)
        ReservoirPoint(date: start.add(Duration(days: i)), volumePercent: vol(i), rainMm: rain),
    ];

void main() {
  test('tendência linear recupera a inclinação e a direção', () {
    final t = LinearTrend.fit([10, 12, 14, 16])!;
    expect(t.slope, closeTo(2, 1e-9));
    expect(t.at(0), closeTo(10, 1e-9));
    expect(t.direction(), TrendDirection.up);
    expect(LinearTrend.fit([5, 5, 5])!.direction(tolerance: 0.1), TrendDirection.flat);
    expect(LinearTrend.fit([1]), isNull);
  });

  test('agregado mensal: média do volume, soma da chuva e mesmo mês do ano anterior', () {
    final s = _series(DateTime(2025, 1, 1), 730, (i) => i < 365 ? 40 : 50, rain: 2);
    final vol = SeriesStats.monthly(s, value: (p) => p.volumePercent, mean: true);
    expect(vol, hasLength(12));
    expect(vol.last.month, DateTime(2026, 12));
    expect(vol.last.value, 50);
    expect(vol.last.previousYear, 40);

    final rain = SeriesStats.monthly(s, value: (p) => p.rainMm, mean: false);
    expect(rain.first.value, 62); // janeiro/2026: 31 dias × 2 mm
    expect(rain.first.complete, isTrue);
  });

  test('mês sem ano anterior completo não ganha comparação', () {
    final s = _series(DateTime(2026, 6, 15), 60, (i) => 50);
    final m = SeriesStats.monthly(s, value: (p) => p.volumePercent, mean: true);
    expect(m.every((x) => x.previousYear == null), isTrue);
    expect(m.first.complete, isFalse);
  });

  test('blocos semanais terminam no último dia', () {
    final s = _series(DateTime(2026, 1, 1), 21, (i) => 50, rain: 1);
    final b = SeriesStats.blocks(s, value: (p) => p.rainMm ?? 0, count: 5);
    expect(b, hasLength(3));
    expect(b.last.end, DateTime(2026, 1, 21));
    expect(b.every((x) => x.value == 7), isTrue);
  });

  test('alerta de previsão traz a janela temporal do último dado até a data prevista', () {
    final s = _series(DateTime(2026, 9, 1), 60, (i) => 45 - i * 0.05);
    final snapshot = ReservoirSnapshot(
      name: 'Teste',
      origin: DataOrigin.real,
      sourceLabel: 'teste',
      series: s,
      forecast: Forecast(date: s.last.date.add(const Duration(days: 7)), value: 39, sigma: 1, method: 'Teste'),
    );
    final alerts = const AlertEngine().evaluate(reservoir: snapshot, now: s.last.date);
    final a = alerts.firstWhere((a) => a.ruleId == 'forecast_below_floor');
    expect(a.window!.kind, WindowKind.forecast);
    expect(a.window!.from, s.last.date);
    expect(a.window!.days, 7);
    expect(a.indicator, IndicatorId.volume);
  });
}
