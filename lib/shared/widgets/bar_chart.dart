import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/pulso_colors.dart';
import '../../core/theme/tokens.dart';
import '../../features/indicators/domain/series_stats.dart';

class BarDatum {
  const BarDatum({required this.label, required this.value, this.compare, this.highlight = false});

  /// Rótulo curto do eixo X ("nov", "S-3").
  final String label;
  final double value;

  /// Valor de comparação (ex.: mesmo mês do ano anterior). Desenhado como marcador.
  final double? compare;

  /// Destaca a barra (ex.: mês incompleto ou semana atual).
  final bool highlight;
}

/// Gráfico de barras com eixo Y em unidade explícita, comparação opcional e linha de tendência.
/// Toque numa barra mostra o valor; "Ver como tabela" entrega os mesmos números ao leitor de tela.
class PulsoBarChart extends StatefulWidget {
  const PulsoBarChart({
    super.key,
    required this.data,
    required this.unit,
    required this.format,
    required this.semanticsSummary,
    this.compareLabel,
    this.valueLabel = 'Valor',
    this.showTrend = false,
    this.height = 180,
    this.color,
    this.minY,
  });

  final List<BarDatum> data;

  /// Unidade mostrada no eixo ("mm", "%", "registros").
  final String unit;
  final String Function(double v) format;
  final String semanticsSummary;
  final String valueLabel;
  final String? compareLabel;
  final bool showTrend;
  final double height;
  final Color? color;

  /// Base do eixo Y (padrão 0). Útil para volume, que nunca chega a 0 na janela mostrada.
  final double? minY;

  @override
  State<PulsoBarChart> createState() => _PulsoBarChartState();
}

class _PulsoBarChartState extends State<PulsoBarChart> {
  int? _selected;
  bool _asTable = false;

  void _select(Offset p, double width) {
    final n = widget.data.length;
    if (n == 0) return;
    final plotW = width - _BarPainter.leftPad;
    final i = ((p.dx - _BarPainter.leftPad) / plotW * n).floor().clamp(0, n - 1);
    if (i != _selected) setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.pulso;
    final data = widget.data;
    if (data.isEmpty) return const SizedBox.shrink();
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final sel = _selected == null ? null : data[_selected!];
    final trend = widget.showTrend ? LinearTrend.fit([for (final d in data) d.value]) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_asTable)
          _BarTable(widget: widget)
        else ...[
          SizedBox(
            height: 22,
            child: Text(
              sel == null
                  ? 'Toque numa barra para ver o valor'
                  : '${sel.label}: ${widget.format(sel.value)}'
                      '${sel.compare == null || widget.compareLabel == null ? '' : ' · ${widget.compareLabel}: ${widget.format(sel.compare!)}'}',
              style: text.labelLarge?.copyWith(color: sel == null ? c.muted : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            label: widget.semanticsSummary,
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                onTapDown: (d) => _select(d.localPosition, box.maxWidth),
                onHorizontalDragUpdate: (d) => _select(d.localPosition, box.maxWidth),
                child: CustomPaint(
                  size: Size(box.maxWidth, widget.height),
                  painter: _BarPainter(
                    data: data,
                    unit: widget.unit,
                    format: widget.format,
                    color: color,
                    compareColor: c.muted,
                    gridColor: Theme.of(context).dividerColor,
                    labelStyle: text.labelSmall!.copyWith(color: c.muted),
                    trend: trend,
                    trendColor: c.forecast,
                    selected: _selected,
                    minY: widget.minY ?? 0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: PulsoSpacing.sm),
          Wrap(
            spacing: PulsoSpacing.md,
            runSpacing: PulsoSpacing.xs,
            children: [
              _Legend(color: color, label: widget.valueLabel),
              if (widget.compareLabel != null && data.any((d) => d.compare != null))
                _Legend(color: c.muted, label: widget.compareLabel!, line: true),
              if (trend != null) _Legend(color: c.forecast, label: 'Tendência linear', line: true),
            ],
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _asTable = !_asTable),
            icon: Icon(_asTable ? Icons.bar_chart : Icons.table_rows_outlined, size: 18),
            label: Text(_asTable ? 'Ver como gráfico' : 'Ver como tabela'),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.line = false});
  final Color color;
  final String label;
  final bool line;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: line ? 16 : 12,
            height: line ? 3 : 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
        ],
      );
}

class _BarTable extends StatelessWidget {
  const _BarTable({required this.widget});
  final PulsoBarChart widget;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasCompare = widget.compareLabel != null && widget.data.any((d) => d.compare != null);
    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2)},
      children: [
        TableRow(children: [
          Text('Período', style: text.labelLarge),
          Text('${widget.valueLabel} (${widget.unit})', style: text.labelLarge),
          if (hasCompare) Text(widget.compareLabel!, style: text.labelLarge) else const SizedBox.shrink(),
        ]),
        for (final d in widget.data)
          TableRow(children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(d.label, style: text.bodyMedium)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(widget.format(d.value), style: text.bodyMedium),
            ),
            if (hasCompare)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(d.compare == null ? '—' : widget.format(d.compare!), style: text.bodyMedium),
              )
            else
              const SizedBox.shrink(),
          ]),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.unit,
    required this.format,
    required this.color,
    required this.compareColor,
    required this.gridColor,
    required this.labelStyle,
    required this.trend,
    required this.trendColor,
    required this.selected,
    required this.minY,
  });

  static const leftPad = 40.0;
  static const bottomPad = 18.0;
  static const topPad = 28.0;

  final List<BarDatum> data;
  final String unit;
  final String Function(double v) format;
  final Color color;
  final Color compareColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final LinearTrend? trend;
  final Color trendColor;
  final int? selected;
  final double minY;

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, double maxW = 60}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: maxW);
    final dx = switch (align) {
      TextAlign.center => at.dx - tp.width / 2,
      TextAlign.right => at.dx - tp.width,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final d in data) ...[d.value, if (d.compare != null) d.compare!],
      if (trend != null) ...[trend!.at(0), trend!.at(data.length - 1)],
    ];
    var maxV = values.reduce(math.max);
    if (maxV <= minY) maxV = minY + 1;
    // Teto "redondo" para as linhas de grade.
    final span = maxV - minY;
    final step = _niceStep(span / 4);
    final top = minY + (span / step).ceil() * step;

    final plot = Rect.fromLTRB(leftPad, topPad, size.width, size.height - bottomPad);
    double y(double v) => plot.bottom - (v - minY) / (top - minY) * plot.height;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var v = minY; v <= top + 1e-9; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      _text(canvas, _axis(v), Offset(plot.left - 6, y(v) - 7), align: TextAlign.right, maxW: leftPad - 6);
    }
    _text(canvas, unit, Offset.zero, maxW: size.width);

    final n = data.length;
    final slot = plot.width / n;
    final barW = math.max(3.0, slot * 0.62);
    final labelEvery = (n / math.max(1, (plot.width / 34).floor())).ceil();

    for (var i = 0; i < n; i++) {
      final d = data[i];
      final cx = plot.left + slot * (i + 0.5);
      final isSel = selected == i;
      final paint = Paint()
        ..color = isSel
            ? color
            : (d.highlight ? color.withValues(alpha: 0.45) : color.withValues(alpha: selected == null ? 1 : 0.7));
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(cx - barW / 2, y(math.max(d.value, minY)), cx + barW / 2, plot.bottom),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
      if (d.compare != null) {
        final cy = y(d.compare!);
        canvas.drawLine(
          Offset(cx - barW / 2 - 2, cy),
          Offset(cx + barW / 2 + 2, cy),
          Paint()
            ..color = compareColor
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
      // Rótulos ancorados na barra mais recente, pulando o necessário para não sobrepor.
      if ((n - 1 - i) % labelEvery == 0) {
        _text(canvas, d.label, Offset(cx, plot.bottom + 3), align: TextAlign.center, maxW: math.max(slot * labelEvery, 30));
      }
    }

    final t = trend;
    if (t != null) {
      final p = Paint()
        ..color = trendColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final a = Offset(plot.left + slot * 0.5, y(t.at(0)));
      final b = Offset(plot.left + slot * (n - 0.5), y(t.at(n - 1)));
      // Tracejado.
      final total = (b - a).distance;
      const dash = 6.0, gap = 4.0;
      for (var s = 0.0; s < total; s += dash + gap) {
        final e = math.min(s + dash, total);
        canvas.drawLine(Offset.lerp(a, b, s / total)!, Offset.lerp(a, b, e / total)!, p);
      }
    }
  }

  String _axis(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / mag;
    final nice = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 2.5 ? 2.5 : (f <= 5 ? 5 : 10)));
    return nice * mag;
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.data != data || old.selected != selected || old.color != color || old.trend != trend;
}
