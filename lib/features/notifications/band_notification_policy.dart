import '../reservoir/domain/operating_band.dart';

/// Decide se uma mudança de faixa merece notificação do sistema. Função pura (testada em unidade).
///
/// Regras:
/// - só com a preferência ligada;
/// - uma notificação por transição: a mesma mudança (de → para, na mesma data do dado) não repete.
abstract final class BandNotificationPolicy {
  static String key(OperatingBand from, OperatingBand to, DateTime dataDate) =>
      '${from.name}->${to.name}@${dataDate.toIso8601String().substring(0, 10)}';

  static bool shouldNotify({
    required bool enabled,
    required OperatingBand? from,
    required OperatingBand? to,
    required DateTime? dataDate,
    required String? lastNotifiedKey,
  }) {
    if (!enabled || from == null || to == null || dataDate == null || from == to) return false;
    return key(from, to, dataDate) != lastNotifiedKey;
  }

  static String title(OperatingBand from, OperatingBand to) => to.level > from.level
      ? 'Cantareira piorou de faixa: ${from.label} → ${to.label}'
      : 'Cantareira melhorou de faixa: ${from.label} → ${to.label}';

  static String body(OperatingBand to, double volume) =>
      'Volume útil em ${volume.toStringAsFixed(1).replaceAll('.', ',')}%. ${to.citizenMeaning} '
      'Sinal exploratório, não é alerta oficial.';
}
