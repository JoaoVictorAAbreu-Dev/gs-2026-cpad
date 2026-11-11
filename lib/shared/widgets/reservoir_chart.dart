import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../features/reservoir/domain/operating_band.dart';
import '../../features/reservoir/domain/reservoir_models.dart';

/// Série observada + previsão com faixa de erro, sobre as faixas de operação.
/// Toque/arraste mostra o valor do dia. "Ver como tabela" atende leitores de tela.
class ReservoirChart extends StatefulWidget {
  const ReservoirChart({
    super.key,
    required this.points,
    this.forecast,
    this.height = 200,
    this.animate = true,
  });

  final List<ReservoirPoint> points;
  final Forecast? forecast;
  final double height;
  final bool animate;

  @override
  State<ReservoirChart> createState() => _ReservoirChartState();
}

class _ReservoirChartState extends State<ReservoirChart> {
  int? _selected;
  bool _asTable = false;

  void _select(Offset local, double width) {
    final n = widget.points.length;
    if (n == 0) return;
    final plotW = width - _ChartPainter.leftPad;
    final x = ((local.dx - _ChartPainter.leftPad) / plotW).clamp(0.0, 1.0);
    final totalSlots = n - 1 + (widget.forecast != null ? 7 : 0);
    final idx = (x * totalSlots).round().clamp(0, n - 1);
    if (idx != _selected) setState(() => _selected = idx);
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    if (pts.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final reduce = MediaQuery.of(context).disableAnimations || !widget.animate;
    final last = pts.last;
    final f = widget.forecast;

    final summary = 'Gráfico do volume útil de ${Fmt.spokenDate(pts.first.date)} a '
        '${Fmt.spokenDate(last.date)}. Último valor ${Fmt.spokenPercent(last.volumePercent)}, '
        'faixa ${last.band.label}.'
        '${f == null ? '' : ' Previsão para ${Fmt.spokenDate(f.date)}: ${Fmt.spokenPercent(f.value)}, '
            'erro típico de ${Fmt.number(f.sigma, 2)} pontos.'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_asTable)
          _ChartTable(points: pts, forecast: f)
        else
          Semantics(
            label: summary,
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                onTapDown: (d) => _select(d.localPosition, c.maxWidth),
                onHorizontalDragUpdate: (d) => _select(d.localPosition, c.maxWidth),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduce ? 1 : 0, end: 1),
                  duration: reduce ? Duration.zero : PulsoDurations.chart,
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                    size: Size(c.maxWidth, widget.height),
                    painter: _ChartPainter(
                      points: pts,
                      forecast: f,
                      progress: progress,
                      selected: _selected,
                      colors: context.pulso,
                      scheme: Theme.of(context).colorScheme,
                      labelStyle: text.labelSmall!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: PulsoSpacing.sm),
        if (!_asTable && _selected != null)
          Text(
            '${Fmt.date(pts[_selected!].date)} · ${Fmt.percent(pts[_selected!].volumePercent)} · observado',
            style: text.labelLarge,
          ),
        Wrap(
          spacing: PulsoSpacing.md,
          runSpacing: PulsoSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Legend(color: Theme.of(context).colorScheme.primary, label: 'Observado'),
            if (f != null) _Legend(color: context.pulso.forecast, label: 'Previsão'),
            if (f != null) _Legend(color: context.pulso.forecastContainer, label: 'Erro típico', box: true),
            TextButton(
              onPressed: () => setState(() => _asTable = !_asTable),
              child: Text(_asTable ? 'Ver gráfico' : 'Ver como tabela'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.box = false});
  final Color color;
  final String label;
  final bool box;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: box ? 12 : 16, height: box ? 12 : 3, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}

class _ChartTable extends StatelessWidget {
  const _ChartTable({required this.points, this.forecast});
  final List<ReservoirPoint> points;
  final Forecast? forecast;

  @override
  Widget build(BuildContext context) {
    // Uma linha por semana para não virar uma lista enorme.
    final rows = <ReservoirPoint>[
      for (var i = points.length - 1; i >= 0; i -= 7) points[i],
    ];
    final style = Theme.of(context).textTheme.bodyMedium;
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth()},
      children: [
        TableRow(children: [
          Text('Data', style: Theme.of(context).textTheme.labelLarge),
          Text('Volume', style: Theme.of(context).textTheme.labelLarge),
          Padding(
            padding: const EdgeInsets.only(left: PulsoSpacing.md),
            child: Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
          ),
        ]),
        if (forecast != null)
          TableRow(children: [
            Text(Fmt.date(forecast!.date), style: style),
            Text(Fmt.percent(forecast!.value), style: style),
            Padding(
              padding: const EdgeInsets.only(left: PulsoSpacing.md),
              child: Text('previsão ±${Fmt.number(forecast!.sigma, 2)}', style: style),
            ),
          ]),
        for (final p in rows)
          TableRow(children: [
            Text(Fmt.date(p.date), style: style),
            Text(Fmt.percent(p.volumePercent), style: style),
            Padding(
              padding: const EdgeInsets.only(left: PulsoSpacing.md),
              child: Text('observado', style: style),
            ),
          ]),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.forecast,
    required this.progress,
    required this.selected,
    required this.colors,
    required this.scheme,
    required this.labelStyle,
  });

  static const double leftPad = 34;
  static const double bottomPad = 20;

  final List<ReservoirPoint> points;
  final Forecast? forecast;
  final double progress;
  final int? selected;
  final PulsoColors colors;
  final ColorScheme scheme;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(leftPad, 4, size.width - leftPad, size.height - bottomPad - 4);
    final f = forecast;
    final values = [
      ...points.map((p) => p.volumePercent),
      if (f != null) ...[f.lower, f.upper],
    ];
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    final pad = math.max(1.0, (maxY - minY) * 0.15);
    minY = (minY - pad).floorToDouble();
    maxY = (maxY + pad).ceilToDouble();

    final slots = points.length - 1 + (f != null ? 7 : 0);
    double xOf(num i) => plot.left + plot.width * (slots == 0 ? 0 : i / slots);
    double yOf(double v) => plot.bottom - plot.height * (v - minY) / (maxY - minY);

    // Faixas de operação visíveis (fundo) e linhas-limite.
    for (final band in OperatingBand.values) {
      final top = math.min(band.upper, maxY);
      final bottom = math.max(band.lower, minY);
      if (top <= bottom) continue;
      final c = switch (band) {
        OperatingBand.normal => colors.successContainer,
        OperatingBand.attention || OperatingBand.alert => colors.warningContainer,
        _ => colors.dangerContainer,
      };
      canvas.drawRect(
        Rect.fromLTRB(plot.left, yOf(top), plot.right, yOf(bottom)),
        Paint()..color = c.withValues(alpha: 0.55),
      );
      // Só rotula a faixa se houver altura para o texto (evita colidir com o eixo X).
      if (yOf(bottom) - yOf(top) >= 18) {
        _text(canvas, band.label, Offset(plot.left + 4, yOf(top) + 2), colors.muted);
      }
      if (band.lower.isFinite && band.lower > minY && band.lower < maxY) {
        canvas.drawLine(
          Offset(plot.left, yOf(band.lower)),
          Offset(plot.right, yOf(band.lower)),
          Paint()
            ..color = colors.danger.withValues(alpha: 0.6)
            ..strokeWidth = 1,
        );
      }
    }

    // Eixo Y (3 marcas).
    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      _text(canvas, '${v.round()}%', Offset(0, yOf(v) - 7), colors.muted);
    }
    // Eixo X: primeira e última data observadas (+ data da previsão).
    _text(canvas, Fmt.dayMonth(points.first.date), Offset(plot.left, plot.bottom + 4), colors.muted);
    // Só desenha a data do último ponto observado se não colidir com a data da previsão.
    final lastX = xOf(points.length - 1);
    if (f == null || xOf(slots) - lastX > 44) {
      _text(canvas, Fmt.dayMonth(points.last.date), Offset(lastX - 30, plot.bottom + 4), colors.muted);
    }

    // Previsão: faixa de erro + linha tracejada.
    if (f != null && progress > 0.6) {
      final t = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      final x0 = xOf(points.length - 1);
      final x1 = x0 + (xOf(slots) - x0) * t;
      final y0 = yOf(points.last.volumePercent);
      final vEnd = points.last.volumePercent + (f.value - points.last.volumePercent) * t;
      final band = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, yOf(vEnd + f.sigma * t))
        ..lineTo(x1, yOf(vEnd - f.sigma * t))
        ..close();
      canvas.drawPath(band, Paint()..color = colors.forecastContainer.withValues(alpha: 0.9));
      _dashed(canvas, Offset(x0, y0), Offset(x1, yOf(vEnd)), colors.forecast);
      if (t == 1) {
        _text(canvas, Fmt.dayMonth(f.date), Offset(xOf(slots) - 30, plot.bottom + 4), colors.forecast);
      }
    }

    // Série observada, desenhada até `progress`.
    final path = Path();
    final upto = ((points.length - 1) * math.min(1.0, progress / 0.6)).round();
    for (var i = 0; i <= upto; i++) {
      final o = Offset(xOf(i), yOf(points[i].volumePercent));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = scheme.primary
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final s = selected;
    if (s != null && s < points.length) {
      final x = xOf(s);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), Paint()..color = scheme.outline);
      canvas.drawCircle(Offset(x, yOf(points[s].volumePercent)), 5, Paint()..color = scheme.primary);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2;
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    const dash = 5.0, gap = 4.0;
    for (var p = 0.0; p < len; p += dash + gap) {
      final s = a + d * (p / len);
      final e = a + d * (math.min(p + dash, len) / len);
      canvas.drawLine(s, e, paint);
    }
  }

  void _text(Canvas canvas, String s, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle.copyWith(color: color, fontSize: 11)),
      textDirection: TextDirection.ltr,
      // Rótulos do gráfico não escalam com a fonte do sistema (o texto ao redor escala).
      textScaler: TextScaler.noScaling,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.points != points ||
      old.forecast != forecast ||
      old.colors != colors;
}
