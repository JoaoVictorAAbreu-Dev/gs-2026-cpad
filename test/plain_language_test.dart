import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/alerts/domain/alert.dart';
import 'package:pulso/features/alerts/domain/confidence.dart';
import 'package:pulso/features/alerts/domain/plain_language.dart';

Alert _alert({String rule = 'forecast_below_floor', ConfidenceLevel conf = ConfidenceLevel.high, bool reliable = true}) =>
    Alert(
      id: 'a',
      ruleId: rule,
      title: 't',
      summary: 'resumo técnico',
      severity: Severity.high,
      confidence: conf,
      horizon: AlertHorizon.shortTerm,
      evidence: const [],
      limitations: const [],
      ruleDescription: 'r',
      basedOnRealData: true,
      reliable: reliable,
    );

void main() {
  test('explica cada regra sem termos técnicos e lembra que a decisão é humana', () {
    for (final rule in ['forecast_below_floor', 'continuous_decline', 'occurrence_surge']) {
      final text = PlainLanguage.explain(_alert(rule: rule)).join(' ');
      expect(text, isNot(contains('p.p.')));
      expect(text, isNot(contains('%')));
      expect(text, contains('quem decide é a equipe responsável'));
    }
  });

  test('confiança vira frase simples', () {
    expect(PlainLanguage.explain(_alert(conf: ConfidenceLevel.low))[1], contains('incerto'));
    expect(PlainLanguage.explain(_alert(conf: ConfidenceLevel.medium))[1], contains('provável'));
  });

  test('dados antigos prevalecem sobre a confiança', () {
    expect(PlainLanguage.explain(_alert(reliable: false))[1], contains('antigos'));
  });
}
