import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/themes.dart';
import '../features/notifications/band_notification_effect.dart';
import '../features/settings/settings_controller.dart';
import 'router.dart';

class PulsoApp extends ConsumerWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    // Mantém o efeito de notificação ativo enquanto o app está aberto.
    ref.watch(bandNotificationEffectProvider);
    final manualHighContrast = settings.themeMode == PulsoThemeMode.highContrast;

    return MaterialApp.router(
      title: 'PULSO',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: manualHighContrast ? PulsoThemes.highContrast() : PulsoThemes.light(),
      darkTheme: manualHighContrast ? PulsoThemes.highContrast() : PulsoThemes.dark(),
      // Alto contraste do sistema também é respeitado.
      highContrastTheme: PulsoThemes.highContrast(),
      highContrastDarkTheme: PulsoThemes.highContrast(),
      themeMode: switch (settings.themeMode) {
        PulsoThemeMode.system => ThemeMode.system,
        PulsoThemeMode.light || PulsoThemeMode.highContrast => ThemeMode.light,
        PulsoThemeMode.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Escala do app multiplica a do sistema (até 200% no total).
        final systemScale = mq.textScaler.scale(1);
        final scale = (systemScale * settings.textScale).clamp(1.0, 2.0);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: mq.disableAnimations || settings.reduceMotion,
          ),
          child: child!,
        );
      },
    );
  }
}
