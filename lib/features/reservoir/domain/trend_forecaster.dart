import 'dart:math' as math;

import 'reservoir_models.dart';

/// Previsão de reserva usada quando o pacote de dados não traz a previsão do modelo Ridge.
/// Regressão linear (mínimos quadrados) sobre os últimos [window] dias; o erro típico é o
/// desvio-padrão dos resíduos, ampliado pela raiz do horizonte (incerteza cresce com o tempo).
class TrendForecaster {
  const TrendForecaster({this.window = 14});

  final int window;

  Forecast? forecast(List<ReservoirPoint> series, {int horizonDays = 7}) {
    if (series.length < 5) return null;
    final pts = series.length > window ? series.sublist(series.length - window) : series;
    final t0 = pts.first.date;
    final xs = [for (final p in pts) p.date.difference(t0).inHours / 24.0];
    final ys = [for (final p in pts) p.volumePercent];

    final n = xs.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var sxy = 0.0, sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (xs[i] - meanX) * (ys[i] - meanY);
      sxx += (xs[i] - meanX) * (xs[i] - meanX);
    }
    if (sxx == 0) return null;
    final slope = sxy / sxx;
    final intercept = meanY - slope * meanX;

    var sse = 0.0;
    for (var i = 0; i < n; i++) {
      final r = ys[i] - (intercept + slope * xs[i]);
      sse += r * r;
    }
    final residualSd = math.sqrt(sse / math.max(1, n - 2));
    // Piso de 0,2 p.p. para não declarar certeza irreal em séries muito lisas.
    final sigma = math.max(0.2, residualSd * math.sqrt(horizonDays.toDouble()));

    final lastX = xs.last;
    final target = pts.last.date.add(Duration(days: horizonDays));
    return Forecast(
      date: target,
      value: intercept + slope * (lastX + horizonDays),
      sigma: sigma,
      method: 'Tendência linear de $window dias',
    );
  }
}
