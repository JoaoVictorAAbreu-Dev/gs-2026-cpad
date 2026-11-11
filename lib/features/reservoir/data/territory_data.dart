import '../../alerts/domain/alert_engine.dart';
import '../domain/reservoir_models.dart';

/// Região do território (cartograma hexagonal). Valores de ocorrências são sintéticos.
class Region {
  const Region({
    required this.id,
    required this.name,
    required this.short,
    required this.col,
    required this.row,
    required this.lastWeek,
    required this.previousWeek,
    required this.population10k,
    required this.synthetic,
  });

  final String id;
  final String name;
  final String short;
  final int col;
  final int row;
  final int lastWeek;
  final int previousWeek;

  /// População em dezenas de milhares (para normalizar registros por 10 mil habitantes).
  final double population10k;
  final bool synthetic;

  /// Registros da última semana por 100 mil habitantes (população vem em dezenas de milhares).
  double get reportsPer100k => population10k == 0 ? 0 : lastWeek / population10k * 10;

  RegionActivity toActivity() => RegionActivity(
        regionId: id,
        regionName: name,
        lastWeek: lastWeek,
        previousWeek: previousWeek,
        synthetic: synthetic,
      );

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        id: j['id'] as String,
        name: j['name'] as String,
        short: j['short'] as String,
        col: (j['col'] as num).toInt(),
        row: (j['row'] as num).toInt(),
        lastWeek: (j['lastWeek'] as num).toInt(),
        previousWeek: (j['previousWeek'] as num).toInt(),
        population10k: (j['population10k'] as num?)?.toDouble() ?? 0,
        synthetic: (j['origin'] as String?) != 'real',
      );
}

/// Pacote de dados do território (esquema v1 de `pulso_data.json`).
class TerritoryData {
  const TerritoryData({required this.reservoir, required this.regions, required this.generatedAt});

  final ReservoirSnapshot reservoir;
  final List<Region> regions;
  final DateTime generatedAt;

  static const supportedSchema = 1;

  factory TerritoryData.fromJson(Map<String, dynamic> j) {
    final schema = (j['schemaVersion'] as num?)?.toInt();
    if (schema != supportedSchema) {
      throw FormatException('Versão de dados não suportada: $schema');
    }
    final r = j['reservoir'] as Map<String, dynamic>;
    final series = (r['series'] as List<dynamic>)
        .map((e) => ReservoirPoint.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (series.isEmpty) throw const FormatException('Série vazia');

    final f = r['forecast'] as Map<String, dynamic>?;
    final m = r['metrics'] as Map<String, dynamic>?;

    return TerritoryData(
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      reservoir: ReservoirSnapshot(
        name: r['name'] as String,
        series: series,
        origin: r['origin'] == 'real' ? DataOrigin.real : DataOrigin.synthetic,
        sourceLabel: r['source'] as String,
        forecast: f == null
            ? null
            : Forecast(
                date: DateTime.parse(f['date'] as String),
                value: (f['value'] as num).toDouble(),
                sigma: (f['sigma'] as num).toDouble(),
                method: f['method'] as String,
              ),
        factors: [
          for (final e in (r['factors'] as List<dynamic>? ?? const []))
            ForecastFactor(
              (e as Map<String, dynamic>)['label'] as String,
              (e['contribution'] as num).toDouble(),
            ),
        ],
        metrics: m == null
            ? null
            : ModelMetrics(
                maeModel: (m['maeModel'] as num).toDouble(),
                maeBaseline: (m['maeBaseline'] as num).toDouble(),
                testPeriod: m['testPeriod'] as String,
              ),
      ),
      regions: [
        for (final e in (j['regions'] as List<dynamic>? ?? const []))
          Region.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}
