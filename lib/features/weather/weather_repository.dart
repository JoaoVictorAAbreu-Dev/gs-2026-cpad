import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/result/data_result.dart';

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.maxTemp,
    required this.rainMm,
    required this.rainProbability,
  });

  final DateTime date;
  final double maxTemp;
  final double rainMm;

  /// 0–100 (%), quando a API informa.
  final int? rainProbability;
}

/// Previsão do tempo na bacia do Cantareira via Open-Meteo (API pública, sem chave).
/// Mesmo padrão de fallback do repositório principal: rede → cache local → sem dados.
class WeatherRepository {
  WeatherRepository({required this.prefs, Dio? dio, DateTime Function()? clock})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _clock = clock ?? DateTime.now;

  final SharedPreferences prefs;
  final Dio _dio;
  final DateTime Function() _clock;

  /// Represa Jaguari-Jacareí, principal reservatório do sistema.
  static const latitude = -22.93;
  static const longitude = -46.40;
  static const _cacheKey = 'cache.weather.json';
  static const _cacheAtKey = 'cache.weather.fetchedAt';

  static const url = 'https://api.open-meteo.com/v1/forecast';

  Future<DataResult<List<DailyWeather>>?> load() async {
    String? error;
    try {
      final res = await _dio.get<Map<String, dynamic>>(url, queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'daily': 'temperature_2m_max,precipitation_sum,precipitation_probability_max',
        'timezone': 'America/Sao_Paulo',
        'forecast_days': 5,
      });
      final body = res.data!;
      final days = parse(body);
      final now = _clock();
      await prefs.setString(_cacheKey, jsonEncode(body));
      await prefs.setString(_cacheAtKey, now.toIso8601String());
      return DataResult(data: days, freshness: Freshness.live, fetchedAt: now);
    } catch (e) {
      error = e is DioException ? 'Previsão do tempo indisponível agora.' : 'Resposta inesperada da previsão.';
    }
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return null;
    try {
      return DataResult(
        data: parse(jsonDecode(cached) as Map<String, dynamic>),
        freshness: Freshness.cached,
        fetchedAt: DateTime.tryParse(prefs.getString(_cacheAtKey) ?? '') ?? _clock(),
        remoteError: error,
      );
    } catch (_) {
      return null;
    }
  }

  static List<DailyWeather> parse(Map<String, dynamic> body) {
    final d = body['daily'] as Map<String, dynamic>;
    final times = (d['time'] as List<dynamic>).cast<String>();
    final tmax = d['temperature_2m_max'] as List<dynamic>;
    final rain = d['precipitation_sum'] as List<dynamic>;
    final prob = d['precipitation_probability_max'] as List<dynamic>?;
    return [
      for (var i = 0; i < times.length; i++)
        DailyWeather(
          date: DateTime.parse(times[i]),
          maxTemp: (tmax[i] as num?)?.toDouble() ?? double.nan,
          rainMm: (rain[i] as num?)?.toDouble() ?? 0,
          rainProbability: (prob?[i] as num?)?.round(),
        ),
    ];
  }
}

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => WeatherRepository(prefs: ref.watch(sharedPreferencesProvider)),
);

/// `null` = sem rede e sem cópia salva.
final weatherProvider = FutureProvider<DataResult<List<DailyWeather>>?>(
  (ref) => ref.watch(weatherRepositoryProvider).load(),
);
