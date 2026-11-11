import '../../reservoir/domain/operating_band.dart';
import '../../reservoir/domain/reservoir_models.dart';
import 'alert.dart';
import 'confidence.dart';

/// Limiares configuráveis pelo gestor (tela Configurações › Limiares).
class AlertThresholds {
  const AlertThresholds({
    this.volumeFloor,
    this.minProbability = 0.30,
    this.declineMonths = 3,
    this.surgeMinCount = 5,
    this.surgeRatio = 1.5,
  });

  /// Volume (%) abaixo do qual avisar. `null` = limite inferior da faixa atual.
  final double? volumeFloor;

  /// Probabilidade mínima para emitir alerta de previsão.
  final double minProbability;

  /// Meses seguidos de queda para emitir "queda contínua".
  final int declineMonths;

  /// Mínimo de ocorrências na última semana para avaliar alta.
  final int surgeMinCount;

  /// Razão semana atual / semana anterior que caracteriza alta.
  final double surgeRatio;

  Map<String, dynamic> toJson() => {
        'volumeFloor': volumeFloor,
        'minProbability': minProbability,
        'declineMonths': declineMonths,
        'surgeMinCount': surgeMinCount,
        'surgeRatio': surgeRatio,
      };

  factory AlertThresholds.fromJson(Map<String, dynamic> j) => AlertThresholds(
        volumeFloor: (j['volumeFloor'] as num?)?.toDouble(),
        minProbability: (j['minProbability'] as num?)?.toDouble() ?? 0.30,
        declineMonths: (j['declineMonths'] as num?)?.toInt() ?? 3,
        surgeMinCount: (j['surgeMinCount'] as num?)?.toInt() ?? 5,
        surgeRatio: (j['surgeRatio'] as num?)?.toDouble() ?? 1.5,
      );
}

/// Contagem de ocorrências por região em duas janelas de 7 dias.
class RegionActivity {
  const RegionActivity({
    required this.regionId,
    required this.regionName,
    required this.lastWeek,
    required this.previousWeek,
    required this.synthetic,
  });

  final String regionId;
  final String regionName;
  final int lastWeek;
  final int previousWeek;
  final bool synthetic;
}

/// Gera alertas a partir de regras transparentes. Nunca executa ações: só descreve
/// evidência, confiança e limites para que uma pessoa decida.
class AlertEngine {
  const AlertEngine({this.staleAfterDays = 3, this.unreliableAfterDays = 30});

  final int staleAfterDays;
  final int unreliableAfterDays;

  List<Alert> evaluate({
    required ReservoirSnapshot reservoir,
    required DateTime now,
    AlertThresholds thresholds = const AlertThresholds(),
    List<RegionActivity> regions = const [],
  }) {
    final ageDays = now.difference(reservoir.latest.date).inDays;
    final alerts = <Alert?>[
      _forecastBelowFloor(reservoir, thresholds),
      _continuousDecline(reservoir, thresholds),
      for (final r in regions) _occurrenceSurge(r, thresholds),
    ].whereType<Alert>().map((a) => a.regionId == null ? _applyStaleness(a, ageDays) : a).toList();

    alerts.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      if (bySeverity != 0) return bySeverity;
      return a.horizon.index.compareTo(b.horizon.index);
    });
    return alerts;
  }

  // ── Regra 1: previsão abaixo do limiar ──────────────────────────────────────
  Alert? _forecastBelowFloor(ReservoirSnapshot r, AlertThresholds t) {
    final f = r.forecast;
    if (f == null) return null;
    final current = r.latest.band;
    final floor = t.volumeFloor ?? (current.lower.isFinite ? current.lower : null);
    if (floor == null) return null;

    final p = probabilityBelow(predicted: f.value, sigma: f.sigma, threshold: floor);
    if (p < t.minProbability) return null;

    final targetBand = OperatingBand.of(floor - 0.01);
    final severity = targetBand.level >= OperatingBand.restriction.level ? Severity.high : Severity.moderate;
    final rain7 = _rainLastDays(r.series, 7);

    return Alert(
      id: 'forecast-floor-${_d(f.date)}',
      ruleId: 'forecast_below_floor',
      title: 'Volume pode ficar abaixo de ${_pct(floor, 0)} até ${_dm(f.date)}',
      summary: 'A previsão para ${_dm(f.date)} é ${_pct(f.value)}, '
          'com erro típico de ±${_pp(f.sigma)}.',
      severity: severity,
      confidence: confidenceFromProbability(p),
      probability: p,
      horizon: AlertHorizon.shortTerm,
      validUntil: f.date,
      basedOnRealData: r.origin == DataOrigin.real,
      evidence: [
        Evidence(label: 'Último dado', value: _pct(r.latest.volumePercent), date: r.latest.date),
        Evidence(label: 'Previsão (${f.method})', value: _pct(f.value), date: f.date),
        Evidence(label: 'Faixa de erro típico', value: '${_pct(f.lower)} a ${_pct(f.upper)}'),
        Evidence(label: 'Chance estimada de ficar abaixo de ${_pct(floor, 0)}', value: '${(p * 100).round()}%'),
        if (rain7 != null) Evidence(label: 'Chuva nos últimos 7 dias', value: '${rain7.round()} mm'),
      ],
      limitations: [
        'A chance supõe erro de previsão com distribuição aproximadamente normal.',
        'Chuvas fortes fora do padrão recente podem mudar o cenário em poucos dias.',
        'Não considera mudanças de operação (transferências, obras ou rodízio).',
        'É um sinal exploratório; o enquadramento oficial é da ANA/SP Águas.',
      ],
      ruleDescription: 'Alerta quando a chance de o volume previsto ficar abaixo de '
          '${_pct(floor, 0)} é de pelo menos ${(t.minProbability * 100).round()}%. '
          'Gravidade alta se o limiar levar às faixas Restrição ou Especial.',
    );
  }

  // ── Regra 2: queda contínua mês a mês ───────────────────────────────────────
  Alert? _continuousDecline(ReservoirSnapshot r, AlertThresholds t) {
    final months = consecutiveMonthlyDeclines(r.series);
    if (months < t.declineMonths) return null;
    final change = r.changeOver(30 * months);
    return Alert(
      id: 'decline-$months',
      ruleId: 'continuous_decline',
      title: 'Queda contínua há $months meses',
      summary: 'A média de cada mês ficou abaixo da do mês anterior por $months meses seguidos.',
      severity: Severity.moderate,
      confidence: ConfidenceLevel.high,
      horizon: AlertHorizon.monitor,
      basedOnRealData: r.origin == DataOrigin.real,
      evidence: [
        Evidence(label: 'Meses seguidos de queda', value: '$months'),
        if (change != null) Evidence(label: 'Variação no período', value: _signedPp(change)),
        Evidence(label: 'Nível atual', value: _pct(r.latest.volumePercent), date: r.latest.date),
      ],
      limitations: const [
        'Queda no período seco (abril a setembro) é esperada; compare com anos anteriores.',
        'Observa o passado: não diz quando a queda vai parar.',
      ],
      ruleDescription: 'Compara médias de janelas de 30 dias. Alerta a partir de '
          '${t.declineMonths} quedas seguidas.',
    );
  }

  // ── Regra 3: alta de ocorrências por região ─────────────────────────────────
  Alert? _occurrenceSurge(RegionActivity a, AlertThresholds t) {
    if (a.lastWeek < t.surgeMinCount) return null;
    final ratio = a.previousWeek == 0 ? double.infinity : a.lastWeek / a.previousWeek;
    if (ratio < t.surgeRatio) return null;
    return Alert(
      id: 'surge-${a.regionId}',
      ruleId: 'occurrence_surge',
      regionId: a.regionId,
      title: 'Mais registros de falta de água em ${a.regionName}',
      summary: '${a.lastWeek} registros nos últimos 7 dias, contra ${a.previousWeek} na semana anterior.',
      severity: Severity.moderate,
      // Poucos registros = evidência fraca.
      confidence: a.lastWeek >= 3 * t.surgeMinCount ? ConfidenceLevel.medium : ConfidenceLevel.low,
      horizon: AlertHorizon.monitor,
      basedOnRealData: !a.synthetic,
      evidence: [
        Evidence(label: 'Últimos 7 dias', value: '${a.lastWeek}'),
        Evidence(label: '7 dias anteriores', value: '${a.previousWeek}'),
      ],
      limitations: [
        if (a.synthetic) 'Valores sintéticos de demonstração.',
        'Registros dependem de quem tem acesso ao app: regiões com menos acesso aparecem menos.',
        'Uma pessoa pode registrar o mesmo problema mais de uma vez.',
      ],
      ruleDescription: 'Alerta quando há pelo menos ${t.surgeMinCount} registros na semana e '
          '${t.surgeRatio.toStringAsFixed(1).replaceAll('.', ',')}× os da semana anterior.',
    );
  }

  Alert _applyStaleness(Alert a, int ageDays) {
    if (ageDays <= staleAfterDays) return a;
    final unreliable = ageDays > unreliableAfterDays;
    return Alert(
      id: a.id,
      ruleId: a.ruleId,
      title: a.title,
      summary: a.summary,
      severity: a.severity,
      confidence: unreliable ? ConfidenceLevel.low : a.confidence.downgraded,
      horizon: a.horizon,
      evidence: a.evidence,
      limitations: [
        unreliable
            ? 'Dados com $ageDays dias: alerta apenas informativo, não confiável para decisão.'
            : 'Dados com $ageDays dias: a confiança foi reduzida em um nível.',
        ...a.limitations,
      ],
      ruleDescription: a.ruleDescription,
      basedOnRealData: a.basedOnRealData,
      probability: a.probability,
      validUntil: a.validUntil,
      regionId: a.regionId,
      reliable: !unreliable,
    );
  }
}

/// Quantas janelas de 30 dias seguidas (da mais recente para trás) têm média menor que a anterior.
int consecutiveMonthlyDeclines(List<ReservoirPoint> series) {
  if (series.isEmpty) return 0;
  final end = series.last.date;
  final means = <double>[];
  for (var k = 0; k < 13; k++) {
    final to = end.subtract(Duration(days: 30 * k));
    final from = to.subtract(const Duration(days: 30));
    final window = series.where((p) => p.date.isAfter(from) && !p.date.isAfter(to)).toList();
    if (window.isEmpty) break;
    means.add(window.map((p) => p.volumePercent).reduce((a, b) => a + b) / window.length);
  }
  var count = 0;
  for (var i = 0; i + 1 < means.length; i++) {
    if (means[i] < means[i + 1]) {
      count++;
    } else {
      break;
    }
  }
  return count;
}

double? _rainLastDays(List<ReservoirPoint> s, int days) {
  final from = s.last.date.subtract(Duration(days: days));
  final rains = s.where((p) => p.date.isAfter(from) && p.rainMm != null).map((p) => p.rainMm!);
  if (rains.isEmpty) return null;
  return rains.reduce((a, b) => a + b);
}

String _num(double v, int digits) => v.toStringAsFixed(digits).replaceAll('.', ',');
String _pct(double v, [int digits = 1]) => '${_num(v, digits)}%';
String _pp(double v) => '${_num(v, 2)} p.p.';
String _signedPp(double v) => '${v >= 0 ? '+' : '−'}${_num(v.abs(), 1)} p.p.';
String _d(DateTime d) => d.toIso8601String().substring(0, 10);
String _dm(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

