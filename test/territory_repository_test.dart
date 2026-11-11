import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/result/data_result.dart';
import 'package:pulso/features/reservoir/data/territory_repository.dart';
import 'package:pulso/features/reservoir/domain/reservoir_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final asset = File('assets/data/pulso_data.json').readAsStringSync();

  Future<TerritoryRepository> repo(Map<String, Object> prefsValues) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    return TerritoryRepository(
      prefs: await SharedPreferences.getInstance(),
      remoteUrl: '', // sem rede nos testes
      loadAsset: (_) async => asset,
    );
  }

  test('sem fonte remota e sem cache, usa o asset embutido', () async {
    final result = await (await repo({})).load();
    expect(result.freshness, Freshness.bundled);
    expect(result.remoteError, isNotNull);
    expect(result.data.reservoir.series, isNotEmpty);
    expect(result.data.reservoir.origin, DataOrigin.synthetic);
    expect(result.data.regions, hasLength(14));
  });

  test('com cache válido, usa o cache e informa quando foi salvo', () async {
    final r = await repo({
      'cache.territory.json': asset,
      'cache.territory.fetchedAt': '2026-11-09T18:40:00.000',
    });
    final result = await r.load();
    expect(result.freshness, Freshness.cached);
    expect(result.fetchedAt, DateTime(2026, 11, 9, 18, 40));
  });

  test('cache corrompido é descartado e cai no asset', () async {
    final r = await repo({'cache.territory.json': '{quebrado'});
    final result = await r.load();
    expect(result.freshness, Freshness.bundled);
    expect(r.prefs.getString('cache.territory.json'), isNull);
  });
}
