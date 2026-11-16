import 'alert.dart';
import 'confidence.dart';

/// Explicação do alerta em frases curtas, sem termos técnicos (modo de leitura simples).
/// Texto montado por regras a partir do próprio alerta: não inventa dados.
abstract final class PlainLanguage {
  static List<String> explain(Alert alert) => [
        switch (alert.ruleId) {
          'forecast_below_floor' => 'A água guardada nas represas pode baixar mais nos próximos dias.',
          'continuous_decline' => 'O nível das represas vem caindo mês após mês.',
          'occurrence_surge' => 'Mais pessoas desta região avisaram que faltou água nesta semana.',
          _ => alert.summary,
        },
        if (!alert.reliable)
          'Os dados estão antigos. Use este aviso só como informação.'
        else
          switch (alert.confidence) {
            ConfidenceLevel.high => 'Temos bastante certeza disso.',
            ConfidenceLevel.medium => 'É provável, mas ainda pode mudar.',
            ConfidenceLevel.low => 'Ainda é incerto. Pode não acontecer.',
          },
        'Use a água com cuidado e registre no app se faltar água na sua rua.',
        'Este aviso não decide nada sozinho: quem decide é a equipe responsável.',
      ];
}
