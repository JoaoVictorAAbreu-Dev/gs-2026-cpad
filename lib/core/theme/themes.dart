import 'package:flutter/material.dart';

import 'pulso_colors.dart';
import 'tokens.dart';

enum PulsoThemeMode { system, light, dark, highContrast }

abstract final class PulsoThemes {
  static ThemeData light() => _build(
        scheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2453D6),
          surface: const Color(0xFFF5F7FB),
        ).copyWith(
          primary: const Color(0xFF2453D6),
          onSurface: const Color(0xFF1A2233),
          outlineVariant: const Color(0xFFDDE2EC),
        ),
        colors: PulsoColors.light,
        cardColor: Colors.white,
      );

  static ThemeData dark() => _build(
        scheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2453D6),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F1420),
        ).copyWith(
          primary: const Color(0xFF9DB8FF),
          onSurface: const Color(0xFFE8ECF4),
        ),
        colors: PulsoColors.dark,
        cardColor: const Color(0xFF182032),
      );

  static ThemeData highContrast() => _build(
        scheme: const ColorScheme.light(
          primary: Color(0xFF0033A8),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          outline: Colors.black,
          outlineVariant: Colors.black,
        ),
        colors: PulsoColors.highContrast,
        cardColor: Colors.white,
        borderWidth: 2,
      );

  static ThemeData _build({
    required ColorScheme scheme,
    required PulsoColors colors,
    required Color cardColor,
    double borderWidth = 1,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter');
    // Escala tipográfica do Figma (Inter). Sem alturas fixas: suporta fonte até 200%.
    final text = base.textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1),
      headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.35),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
      labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0.4),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PulsoRadius.card),
      side: BorderSide(color: scheme.outlineVariant, width: borderWidth),
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTouchTarget + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PulsoRadius.button)),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(kMinTouchTarget + 2),
          side: BorderSide(color: scheme.outlineVariant, width: borderWidth),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PulsoRadius.button)),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Mensagens de erro e ajuda nunca cortadas (inclusive com fonte ampliada).
        errorMaxLines: 3,
        helperMaxLines: 3,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(PulsoRadius.button)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PulsoRadius.button),
          borderSide: BorderSide(color: scheme.outlineVariant, width: borderWidth),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colors.infoContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PulsoRadius.chip)),
      ),
    );
  }
}
