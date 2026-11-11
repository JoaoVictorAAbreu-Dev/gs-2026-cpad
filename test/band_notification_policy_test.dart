import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/notifications/band_notification_policy.dart';
import 'package:pulso/features/reservoir/domain/operating_band.dart';

void main() {
  final date = DateTime(2026, 11, 7);

  test('notifica uma vez por transição', () {
    final key = BandNotificationPolicy.key(OperatingBand.alert, OperatingBand.restriction, date);
    expect(
      BandNotificationPolicy.shouldNotify(
        enabled: true, from: OperatingBand.alert, to: OperatingBand.restriction, dataDate: date, lastNotifiedKey: null,
      ),
      isTrue,
    );
    expect(
      BandNotificationPolicy.shouldNotify(
        enabled: true, from: OperatingBand.alert, to: OperatingBand.restriction, dataDate: date, lastNotifiedKey: key,
      ),
      isFalse,
    );
  });

  test('não notifica com a preferência desligada ou sem mudança', () {
    expect(
      BandNotificationPolicy.shouldNotify(
        enabled: false, from: OperatingBand.alert, to: OperatingBand.restriction, dataDate: date, lastNotifiedKey: null,
      ),
      isFalse,
    );
    expect(
      BandNotificationPolicy.shouldNotify(
        enabled: true, from: OperatingBand.alert, to: OperatingBand.alert, dataDate: date, lastNotifiedKey: null,
      ),
      isFalse,
    );
  });

  test('texto diz se piorou ou melhorou', () {
    expect(BandNotificationPolicy.title(OperatingBand.attention, OperatingBand.alert), contains('piorou'));
    expect(BandNotificationPolicy.title(OperatingBand.restriction, OperatingBand.attention), contains('melhorou'));
    expect(BandNotificationPolicy.body(OperatingBand.attention, 52.94), startsWith('Volume útil em 52,9%'));
  });
}
