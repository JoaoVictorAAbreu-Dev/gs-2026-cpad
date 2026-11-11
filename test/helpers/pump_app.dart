import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/app.dart';
import 'package:pulso/app/providers.dart';
import 'package:pulso/features/map/osm_map.dart';
import 'package:pulso/features/notifications/notification_service.dart';
import 'package:pulso/features/reservoir/data/territory_repository.dart';
import 'package:pulso/features/weather/weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta o app com dados embutidos lidos de forma síncrona e sem rede.
/// (I/O real e timers do dio não completam no relógio simulado dos testes de widget.)
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Size? size,
  FakeNotificationService? notifications,
}) async {
  if (size != null) {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
  }
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 9)),
      territoryRepositoryProvider.overrideWithValue(
        TerritoryRepository(
          prefs: instance,
          remoteUrl: '',
          loadAsset: (_) => Future.value(File('assets/data/pulso_data.json').readAsStringSync()),
        ),
      ),
      weatherProvider.overrideWith((ref) async => null),
      // Sem tiles do OSM nem plugin nativo de notificação nos testes.
      osmTilesEnabledProvider.overrideWithValue(false),
      notificationServiceProvider.overrideWithValue(notifications ?? FakeNotificationService()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PulsoApp()));
  await tester.pumpAndSettle();
  return container;
}

/// Guarda as notificações em memória para os testes conferirem.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.grant = true});
  final bool grant;
  final shown = <({int id, String title, String body})>[];

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> show({required int id, required String title, required String body}) async =>
      shown.add((id: id, title: title, body: body));
}
