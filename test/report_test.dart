import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/reports/domain/report.dart';

void main() {
  test('protocolo tem formato PUL-ANO-XXXXX sem caracteres ambíguos', () {
    final p = Report.newProtocol(DateTime(2026, 11, 11), math.Random(1));
    expect(p, matches(RegExp(r'^PUL-2026-[A-HJ-NP-Z2-9]{5}$')));
  });

  test('descrição exige 20 a 500 caracteres e informa quanto falta', () {
    expect(ReportValidator.description(''), isNotNull);
    expect(ReportValidator.description('Vazamento'), contains('faltam 11'));
    expect(ReportValidator.description('Sem água desde ontem à noite'), isNull);
    expect(ReportValidator.description('a' * 501), isNotNull);
  });

  test('tipo e região são obrigatórios', () {
    expect(ReportValidator.type(null), isNotNull);
    expect(ReportValidator.type(ReportType.noWater), isNull);
    expect(ReportValidator.region(''), isNotNull);
    expect(ReportValidator.region('zl2'), isNull);
  });

  test('serializa e lê de volta', () {
    final r = Report(
      protocol: 'PUL-2026-ABCDE',
      type: ReportType.lowPressure,
      regionId: 'zl2',
      regionName: 'Zona Leste 2',
      description: 'Pressão baixa desde segunda-feira',
      createdAt: DateTime(2026, 11, 11, 10),
      status: ReportStatus.queued,
    );
    final back = Report.fromJson(r.toJson());
    expect(back.type, ReportType.lowPressure);
    expect(back.status, ReportStatus.queued);
    expect(back.sentAt, isNull);
  });
}
