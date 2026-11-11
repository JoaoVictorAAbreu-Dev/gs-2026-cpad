import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/reservoir/domain/reservoir_models.dart';
import 'package:pulso/features/reservoir/domain/trend_forecaster.dart';

void main() {
  test('extrapola tendência linear e aplica piso de erro', () {
    final end = DateTime(2026, 11, 9);
    final series = [
      for (var i = 0; i < 14; i++)
        ReservoirPoint(date: end.subtract(Duration(days: 13 - i)), volumePercent: 30 - 0.1 * i),
    ];
    final f = const TrendForecaster().forecast(series)!;
    // Último 28,7 − 0,1 × 7 = 28,0
    expect(f.value, closeTo(28.0, 1e-6));
    expect(f.sigma, 0.2); // série perfeitamente linear → piso
    expect(f.date, end.add(const Duration(days: 7)));
  });

  test('retorna null com poucos pontos', () {
    final p = ReservoirPoint(date: DateTime(2026), volumePercent: 30);
    expect(const TrendForecaster().forecast([p, p]), isNull);
  });
}
