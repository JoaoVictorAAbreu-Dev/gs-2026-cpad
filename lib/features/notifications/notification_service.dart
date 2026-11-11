import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notificações do sistema (Android, iOS, web e Linux) via flutter_local_notifications.
/// Interface própria para os testes trocarem por uma implementação falsa.
abstract interface class NotificationService {
  /// Pede permissão quando a plataforma exige (Android 13+, iOS, navegador).
  Future<bool> requestPermission();

  Future<void> show({required int id, required String title, required String body});
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'band_change',
      'Mudança de faixa',
      channelDescription: 'Aviso quando o Sistema Cantareira muda de faixa de operação.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: 'Abrir o PULSO'),
        web: WebInitializationSettings(),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      if (kIsWeb) {
        return await _plugin
                .resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _plugin
                  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true) ??
              false;
        case TargetPlatform.linux:
          return true; // Linux não exige permissão.
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> show({required int id, required String title, required String body}) async {
    try {
      await _init();
      await _plugin.show(id: id, title: title, body: body, notificationDetails: _details);
    } catch (_) {
      // Notificação é complemento: falhar aqui não pode derrubar o app.
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => LocalNotificationService());
