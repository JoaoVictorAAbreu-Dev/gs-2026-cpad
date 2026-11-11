import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/settings/thresholds_validator.dart';

void main() {
  group('ThresholdsValidator', () {
    test('aceita vírgula decimal e símbolo de %', () {
      expect(ThresholdsValidator.parseNumber('25,5'), 25.5);
      expect(ThresholdsValidator.parseNumber(' 30% '), 30);
      expect(ThresholdsValidator.parseNumber(''), isNull);
    });

    test('volume mínimo é opcional, mas limitado a 1–99', () {
      expect(ThresholdsValidator.volumeFloor(''), isNull);
      expect(ThresholdsValidator.volumeFloor('25'), isNull);
      expect(ThresholdsValidator.volumeFloor('0'), isNotNull);
      expect(ThresholdsValidator.volumeFloor('abc'), contains('número'));
    });

    test('chance mínima entre 10 e 95', () {
      expect(ThresholdsValidator.minProbability('30'), isNull);
      expect(ThresholdsValidator.minProbability('5'), isNotNull);
      expect(ThresholdsValidator.minProbability(''), isNotNull);
    });

    test('meses, contagem e razão', () {
      expect(ThresholdsValidator.declineMonths('3'), isNull);
      expect(ThresholdsValidator.declineMonths('13'), isNotNull);
      expect(ThresholdsValidator.surgeMinCount('1'), isNotNull);
      expect(ThresholdsValidator.surgeRatio('1'), isNotNull);
      expect(ThresholdsValidator.surgeRatio('1,5'), isNull);
    });
  });
}
