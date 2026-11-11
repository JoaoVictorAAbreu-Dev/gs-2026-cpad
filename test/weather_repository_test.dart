import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/weather/weather_repository.dart';

void main() {
  test('lê a resposta diária da Open-Meteo', () {
    final days = WeatherRepository.parse({
      'daily': {
        'time': ['2026-11-11', '2026-11-12'],
        'temperature_2m_max': [27.4, 29.1],
        'precipitation_sum': [12.3, 0.0],
        'precipitation_probability_max': [80, null],
      },
    });
    expect(days, hasLength(2));
    expect(days.first.date, DateTime(2026, 11, 11));
    expect(days.first.rainMm, 12.3);
    expect(days.first.rainProbability, 80);
    expect(days.last.rainProbability, isNull);
  });
}
