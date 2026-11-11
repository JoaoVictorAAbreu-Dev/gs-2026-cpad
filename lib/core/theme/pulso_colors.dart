import 'package:flutter/material.dart';

/// Cores semânticas que o ColorScheme do Material não cobre.
/// Telas nunca usam hex direto: leem `context.pulso`.
@immutable
class PulsoColors extends ThemeExtension<PulsoColors> {
  const PulsoColors({
    required this.danger,
    required this.dangerContainer,
    required this.warning,
    required this.warningContainer,
    required this.success,
    required this.successContainer,
    required this.forecast,
    required this.forecastContainer,
    required this.info,
    required this.infoContainer,
    required this.muted,
  });

  final Color danger;
  final Color dangerContainer;
  final Color warning;
  final Color warningContainer;
  final Color success;
  final Color successContainer;
  final Color forecast;
  final Color forecastContainer;
  final Color info;
  final Color infoContainer;
  final Color muted;

  static const light = PulsoColors(
    danger: Color(0xFFB4233A),
    dangerContainer: Color(0xFFFBE7EA),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFFF0D4),
    success: Color(0xFF0B6E5A),
    successContainer: Color(0xFFDDF3EC),
    forecast: Color(0xFF5B3FD0),
    forecastContainer: Color(0xFFEDE8FF),
    info: Color(0xFF2453D6),
    infoContainer: Color(0xFFE6EDFD),
    muted: Color(0xFF5A6478),
  );

  static const dark = PulsoColors(
    danger: Color(0xFFFF8A9A),
    dangerContainer: Color(0xFF4A1620),
    warning: Color(0xFFF5C26B),
    warningContainer: Color(0xFF3D2C08),
    success: Color(0xFF6FD9BD),
    successContainer: Color(0xFF0F3A30),
    forecast: Color(0xFFB9A8FF),
    forecastContainer: Color(0xFF2C2350),
    info: Color(0xFF9DB8FF),
    infoContainer: Color(0xFF1B2A55),
    muted: Color(0xFFAAB3C5),
  );

  /// Alto contraste: texto preto puro sobre fundos claros, bordas fortes.
  static const highContrast = PulsoColors(
    danger: Color(0xFF8C0016),
    dangerContainer: Color(0xFFFFFFFF),
    warning: Color(0xFF5C3B00),
    warningContainer: Color(0xFFFFFFFF),
    success: Color(0xFF004D3D),
    successContainer: Color(0xFFFFFFFF),
    forecast: Color(0xFF3A1FA8),
    forecastContainer: Color(0xFFFFFFFF),
    info: Color(0xFF0033A8),
    infoContainer: Color(0xFFFFFFFF),
    muted: Color(0xFF1A1A1A),
  );

  @override
  PulsoColors copyWith({
    Color? danger,
    Color? dangerContainer,
    Color? warning,
    Color? warningContainer,
    Color? success,
    Color? successContainer,
    Color? forecast,
    Color? forecastContainer,
    Color? info,
    Color? infoContainer,
    Color? muted,
  }) {
    return PulsoColors(
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      forecast: forecast ?? this.forecast,
      forecastContainer: forecastContainer ?? this.forecastContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      muted: muted ?? this.muted,
    );
  }

  @override
  PulsoColors lerp(ThemeExtension<PulsoColors>? other, double t) {
    if (other is! PulsoColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PulsoColors(
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      forecast: l(forecast, other.forecast),
      forecastContainer: l(forecastContainer, other.forecastContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      muted: l(muted, other.muted),
    );
  }
}

extension PulsoColorsX on BuildContext {
  PulsoColors get pulso => Theme.of(this).extension<PulsoColors>()!;
}
