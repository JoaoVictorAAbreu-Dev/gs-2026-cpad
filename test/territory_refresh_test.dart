import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/providers.dart';
import 'package:pulso/features/reservoir/data/territory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final asset = File('assets/data/pulso_data.json').readAsStringSync();

  test('atualizar com falha mantém na tela os dados que já estavam carregados', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var fail = false;
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      territoryRepositoryProvider.overrideWithValue(TerritoryRepository(
        prefs: prefs,
        remoteUrl: '',
        loadAsset: (_) async => fail ? throw Exception('asset ilegível') : asset,
      )),
    ]);
    addTearDown(container.dispose);

    final first = await container.read(territoryProvider.future);
    fail = true;
    await container.read(territoryProvider.notifier).refresh();

    final state = container.read(territoryProvider);
    expect(state.hasError, isFalse);
    expect(state.value, same(first));
  });
}
