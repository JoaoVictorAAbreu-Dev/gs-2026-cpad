import 'package:flutter/material.dart';

/// Símbolo da marca PULSO — "B2 · P em movimento" (Figma, página 01 · Design System, nó 11:602).
///
/// Um P cujo miolo foge do centro: o território não está parado. A geometria vem do vetor do
/// Figma (caixa de 120 × 120) normalizada para 0–1, então o símbolo escala sem perder a forma
/// e funciona de 16 px a 120 px em uma cor.
class PulsoMark extends StatelessWidget {
  const PulsoMark({super.key, this.size = 32, this.color});

  final double size;

  /// Cor única do símbolo. Padrão: `colorScheme.primary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: PulsoMarkPainter(color ?? Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class PulsoMarkPainter extends CustomPainter {
  const PulsoMarkPainter(this.color);

  final Color color;

  /// Caminho do símbolo numa caixa [s] × [s] (proporções do Figma, base 120).
  static Path markPath(double s) {
    double u(double v) => v / 120 * s;
    // Haste com ponta arredondada (x 26,25–43,125; y 52,5–101,25; raio 8,4375).
    final stem = Path()
      ..moveTo(u(26.25), u(52.5))
      ..lineTo(u(43.125), u(52.5))
      ..lineTo(u(43.125), u(101.25))
      ..arcToPoint(Offset(u(26.25), u(101.25)), radius: Radius.circular(u(8.4375)))
      ..close();
    // Bojo (centro 60; 52,5 — raio 33,75) com o miolo deslocado (centro 66,5625; 45 — raio 14,0625).
    final bowl = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: Offset(u(60), u(52.5)), radius: u(33.75)))
      ..addOval(Rect.fromCircle(center: Offset(u(66.5625), u(45)), radius: u(14.0625)));
    return Path.combine(PathOperation.union, stem, bowl);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(markPath(size.shortestSide), Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(PulsoMarkPainter oldDelegate) => oldDelegate.color != color;
}

/// Símbolo + palavra "PULSO" (Inter ExtraBold, espaçamento 4%), como no lockup do Figma.
class PulsoLogo extends StatelessWidget {
  const PulsoLogo({super.key, this.markSize = 40, this.color, this.wordColor});

  final double markSize;
  final Color? color;
  final Color? wordColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fontSize = markSize * 0.75;
    return Semantics(
      label: 'PULSO',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsoMark(size: markSize, color: color),
          SizedBox(width: markSize * 0.2),
          Text(
            'PULSO',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: fontSize * 0.04,
              height: 1,
              color: wordColor ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
