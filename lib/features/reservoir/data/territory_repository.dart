import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/result/data_result.dart';
import 'territory_data.dart';

/// Lê o pacote de dados com fallback em três camadas:
/// 1. fonte remota (GitHub Pages do pipeline DSA) → salva em cache;
/// 2. última cópia em cache (SharedPreferences);
/// 3. asset embutido no app.
/// O app continua útil sem conexão e a tela sempre sabe de onde veio o dado.
class TerritoryRepository {
  TerritoryRepository({
    required this.prefs,
    Dio? dio,
    this.remoteUrl = const String.fromEnvironment('PULSO_DATA_URL'),
    this.assetPath = 'assets/data/pulso_data.json',
    Future<String> Function(String path)? loadAsset,
    DateTime Function()? clock,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              responseType: ResponseType.plain,
            )),
        _loadAsset = loadAsset ?? rootBundle.loadString,
        _clock = clock ?? DateTime.now;

  final SharedPreferences prefs;
  final String remoteUrl;
  final String assetPath;
  final Dio _dio;
  final Future<String> Function(String path) _loadAsset;
  final DateTime Function() _clock;

  static const _cacheKey = 'cache.territory.json';
  static const _cacheAtKey = 'cache.territory.fetchedAt';

  Future<DataResult<TerritoryData>> load() async {
    String? remoteError;

    if (remoteUrl.isNotEmpty) {
      try {
        final res = await _dio.get<String>(remoteUrl);
        final body = res.data ?? '';
        final data = TerritoryData.fromJson(jsonDecode(body) as Map<String, dynamic>);
        final now = _clock();
        await prefs.setString(_cacheKey, body);
        await prefs.setString(_cacheAtKey, now.toIso8601String());
        return DataResult(data: data, freshness: Freshness.live, fetchedAt: now);
      } on DioException catch (e) {
        remoteError = _describe(e);
      } catch (_) {
        // JSON malformado ou fora do esquema: trata como falha remota e segue para o cache.
        remoteError = 'A fonte devolveu dados em formato inválido.';
      }
    } else {
      remoteError = 'Fonte remota não configurada (PULSO_DATA_URL).';
    }

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final data = TerritoryData.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        final at = DateTime.tryParse(prefs.getString(_cacheAtKey) ?? '') ?? data.generatedAt;
        return DataResult(data: data, freshness: Freshness.cached, fetchedAt: at, remoteError: remoteError);
      } catch (_) {
        // Cache corrompido (ou de versão antiga do esquema): descarta e usa o asset.
        await prefs.remove(_cacheKey);
      }
    }

    final raw = await _loadAsset(assetPath);
    final data = TerritoryData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return DataResult(
      data: data,
      freshness: Freshness.bundled,
      fetchedAt: data.generatedAt,
      remoteError: remoteError,
    );
  }

  Future<void> clearCache() async {
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheAtKey);
  }

  static String _describe(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'A fonte demorou demais para responder.',
        DioExceptionType.connectionError => 'Sem conexão com a internet.',
        DioExceptionType.badResponse => 'A fonte respondeu com erro ${e.response?.statusCode}.',
        _ => 'Falha ao buscar dados atualizados.',
      };
}
