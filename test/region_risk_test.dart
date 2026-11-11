import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/alerts/domain/alert.dart';
import 'package:pulso/features/map/region_risk.dart';
import 'package:pulso/features/reservoir/data/territory_data.dart';

Region region(int last, int prev) => Region(
      id: 'x',
      name: 'X',
      short: 'X',
      col: 0,
      row: 0,
      lastWeek: last,
      previousWeek: prev,
      population10k: 50,
      synthetic: true,
    );

void main() {
  test('risco pela contagem semanal', () {
    expect(RegionRisk.fromCount(9), Severity.high);
    expect(RegionRisk.fromCount(4), Severity.moderate);
    expect(RegionRisk.fromCount(3), Severity.low);
  });

  test('+7 dias repete a variação e não fica negativo', () {
    expect(RegionRisk.projectedCount(region(9, 4)), 14);
    expect(RegionRisk.in7Days(region(6, 5)), Severity.moderate);
    expect(RegionRisk.projectedCount(region(1, 6)), 0);
  });

  test('registros por 100 mil habitantes', () {
    expect(region(5, 0).reportsPer100k, closeTo(1.0, 1e-9));
  });
}
