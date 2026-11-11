/// Tokens do design system PULSO (Figma › 05 · Handoff Flutter). Valores em dp.
abstract final class PulsoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md12 = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Margem lateral das telas.
  static const double screen = 16;
}

abstract final class PulsoRadius {
  static const double chip = 12;
  static const double button = 14;
  static const double card = 20;
  static const double sheet = 24;
  static const double full = 999;
}

abstract final class PulsoDurations {
  static const Duration state = Duration(milliseconds: 150);
  static const Duration tabs = Duration(milliseconds: 220);
  static const Duration expand = Duration(milliseconds: 250);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration chart = Duration(milliseconds: 700);
}

/// Largura máxima do conteúdo em tablets.
const double kMaxContentWidth = 600;

/// Alvo mínimo de toque (acessibilidade).
const double kMinTouchTarget = 48;
