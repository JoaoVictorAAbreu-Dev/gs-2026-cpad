import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/alerts/domain/lead_time_backtest.dart';
import 'package:pulso/features/reservoir/data/territory_data.dart';
import 'package:pulso/features/reservoir/domain/reservoir_models.dart';

void main() {
  test('queda linear que cruza 40% é avisada com antecedência', () {
    final start = DateTime(2026, 1, 1);
    // 45% → 35% em 100 dias: cruza o limite Atenção/Alerta (40%) perto do dia 50.
    final series = [
      for (var i = 0; i < 100; i++)
        ReservoirPoint(date: start.add(Duration(days: i)), volumePercent: 45 - 0.1 * i),
    ];
    final r = const LeadTimeBacktest().run(series);
    expect(r.worsenings, 1);
    expect(r.detected, 1);
    expect(r.leadDays.single, inInclusiveRange(1, 7));
    expect(r.averageLeadDays, isNotNull);
  });

  test('série estável não gera alerta nem piora', () {
    final start = DateTime(2026, 1, 1);
    final series = [
      for (var i = 0; i < 100; i++) ReservoirPoint(date: start.add(Duration(days: i)), volumePercent: 50),
    ];
    final r = const LeadTimeBacktest().run(series);
    expect(r.worsenings, 0);
    expect(r.alertDays, 0);
    expect(r.precision, isNull);
  });

  test('série real embutida: resultado igual ao conferido em Python', () {
    final json = jsonDecode(File('assets/data/pulso_data.json').readAsStringSync()) as Map<String, dynamic>;
    final data = TerritoryData.fromJson(json);
    final r = const LeadTimeBacktest().run(data.reservoir.series);
    // Conferido com reimplementação independente em Python sobre o mesmo JSON (11/11/2026).
    expect(r.worsenings, 6);
    expect(r.detected, 6);
    expect(r.averageLeadDays, closeTo(5.83, 0.01));
    expect(r.alertDays, 51);
    expect(r.falseAlarmDays, 16);
  });
}
