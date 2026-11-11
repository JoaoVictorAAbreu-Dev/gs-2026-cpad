import '../alerts/domain/alert.dart';
import '../alerts/domain/alert_engine.dart';
import '../reservoir/data/territory_data.dart';

/// Risco de abastecimento por região a partir dos registros (dados sintéticos).
/// Regra simples e declarada na tela: ≥ 8 registros/semana = alto; ≥ 4 = moderado.
abstract final class RegionRisk {
  static const highFrom = kRegionHighFrom;
  static const moderateFrom = kRegionModerateFrom;

  static Severity fromCount(int count) {
    if (count >= highFrom) return Severity.high;
    if (count >= moderateFrom) return Severity.moderate;
    return Severity.low;
  }

  /// Projeção ingênua para +7 dias: repete a variação da última semana (sem ficar negativa).
  static int projectedCount(Region r) {
    final next = r.lastWeek + (r.lastWeek - r.previousWeek);
    return next < 0 ? 0 : next;
  }

  static Severity today(Region r) => fromCount(r.lastWeek);
  static Severity in7Days(Region r) => fromCount(projectedCount(r));
}
