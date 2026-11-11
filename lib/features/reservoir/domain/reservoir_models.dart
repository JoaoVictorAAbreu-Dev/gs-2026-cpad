import 'operating_band.dart';

/// Origem do dado — vira a etiqueta "DADOS REAIS" / "DADOS SINTÉTICOS" na interface.
enum DataOrigin { real, synthetic }

class ReservoirPoint {
  const ReservoirPoint({required this.date, required this.volumePercent, this.rainMm});

  final DateTime date;

  /// % do volume útil.
  final double volumePercent;

  /// Chuva do dia (mm), quando disponível.
  final double? rainMm;

  OperatingBand get band => OperatingBand.of(volumePercent);

  factory ReservoirPoint.fromJson(Map<String, dynamic> json) => ReservoirPoint(
        date: DateTime.parse(json['date'] as String),
        volumePercent: (json['volume'] as num).toDouble(),
        rainMm: (json['rain'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'volume': volumePercent,
        if (rainMm != null) 'rain': rainMm,
      };
}

/// Previsão pontual com erro típico (desvio-padrão do erro no conjunto de teste).
class Forecast {
  const Forecast({
    required this.date,
    required this.value,
    required this.sigma,
    required this.method,
  });

  final DateTime date;
  final double value;
  final double sigma;

  /// Ex.: "Ridge (projeto DSA)" ou "Tendência linear de 14 dias".
  final String method;

  double get lower => value - sigma;
  double get upper => value + sigma;
}

/// Contribuição de um fator para a previsão (gráfico "o que levou à previsão").
class ForecastFactor {
  const ForecastFactor(this.label, this.contribution);
  final String label;

  /// Em pontos percentuais.
  final double contribution;
}

class ModelMetrics {
  const ModelMetrics({required this.maeModel, required this.maeBaseline, required this.testPeriod});

  /// Erro médio absoluto do modelo em 7 dias (p.p.).
  final double maeModel;

  /// Erro do baseline "repetir o valor de hoje" (p.p.).
  final double maeBaseline;
  final String testPeriod;

  double get improvement => maeBaseline == 0 ? 0 : 1 - maeModel / maeBaseline;
}

class ReservoirSnapshot {
  const ReservoirSnapshot({
    required this.name,
    required this.series,
    required this.origin,
    required this.sourceLabel,
    this.forecast,
    this.factors = const [],
    this.metrics,
  });

  final String name;

  /// Ordenada por data crescente.
  final List<ReservoirPoint> series;
  final DataOrigin origin;
  final String sourceLabel;
  final Forecast? forecast;
  final List<ForecastFactor> factors;
  final ModelMetrics? metrics;

  ReservoirPoint get latest => series.last;

  /// Variação em p.p. entre o último ponto e o ponto ~`days` dias antes.
  double? changeOver(int days) {
    final target = latest.date.subtract(Duration(days: days));
    ReservoirPoint? ref;
    for (final p in series) {
      if (!p.date.isAfter(target)) ref = p;
    }
    return ref == null ? null : latest.volumePercent - ref.volumePercent;
  }

  /// Data em que a série entrou na faixa atual (para "voltou à Restrição em …").
  DateTime? enteredCurrentBandOn() {
    final current = latest.band;
    for (var i = series.length - 1; i > 0; i--) {
      if (series[i - 1].band != current) return series[i].date;
    }
    return null;
  }
}
