import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/utils/pii_detector.dart';

void main() {
  group('PiiDetector', () {
    test('detecta CPF, telefone, e-mail, CEP e endereço com número', () {
      expect(PiiDetector.kinds('Meu CPF é 123.456.789-09'), {PiiKind.cpf});
      expect(PiiDetector.kinds('ligue (11) 91234-5678'), {PiiKind.phone});
      expect(PiiDetector.kinds('email joao@x.com.br'), {PiiKind.email});
      expect(PiiDetector.kinds('CEP 01310-100'), {PiiKind.cep});
      expect(PiiDetector.kinds('moro na Rua das Flores, 123'), {PiiKind.streetNumber});
    });

    test('não acusa descrição comum', () {
      expect(PiiDetector.find('Sem água desde ontem à noite em toda a rua'), isEmpty);
      expect(PiiDetector.find('Faltou água 3 dias, 20 mm de chuva'), isEmpty);
    });

    test('mascara mantendo o resto do texto', () {
      expect(
        PiiDetector.mask('Sem água. Contato (11) 91234-5678.'),
        'Sem água. Contato [telefone removido].',
      );
    });
  });
}
