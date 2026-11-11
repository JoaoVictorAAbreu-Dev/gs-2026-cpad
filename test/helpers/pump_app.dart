import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/app.dart';
import 'package:pulso/app/providers.dart';
import 'package:pulso/features/reservoir/data/territory_repository.dart';
import 'package:pulso/features/weather/weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta o app com dados embutidos lidos de forma síncrona e sem rede.
/// (I/O real e timers do dio não completam no relógio simulado dos testes de widget.)
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Size? size,
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
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PulsoApp()));
  await tester.pumpAndSettle();
  return container;
}
