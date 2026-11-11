import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../settings/settings_controller.dart';
import 'band_notification_policy.dart';
import 'notification_service.dart';

/// Efeito observado pelo app: quando a faixa muda e a preferência está ligada,
/// envia uma notificação do sistema (uma vez por transição).
/// Dispara ao abrir o app e a cada atualização dos dados; não há verificação em segundo plano.
final bandNotificationEffectProvider = Provider<void>((ref) {
  final change = ref.watch(bandChangeProvider);
  final enabled = ref.watch(settingsProvider.select((s) => s.notifyBandChange));
  final latest = ref.watch(reservoirProvider).valueOrNull?.data.latest;
  final prefs = ref.read(sharedPreferencesProvider);
  const key = 'band.notifiedKey';

  if (!BandNotificationPolicy.shouldNotify(
    enabled: enabled,
    from: change?.from,
    to: change?.to,
    dataDate: latest?.date,
    lastNotifiedKey: prefs.getString(key),
  )) {
    return;
  }

  final notified = BandNotificationPolicy.key(change!.from, change.to, latest!.date);
  unawaited(prefs.setString(key, notified));
  unawaited(
    ref.read(notificationServiceProvider).show(
          id: 1,
          title: BandNotificationPolicy.title(change.from, change.to),
          body: BandNotificationPolicy.body(change.to, latest.volumePercent),
        ),
  );
});
