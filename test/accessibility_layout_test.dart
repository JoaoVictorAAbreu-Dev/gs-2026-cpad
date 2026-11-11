import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/providers.dart';
import 'package:pulso/app/router.dart';

import 'helpers/pump_app.dart';

/// Cada tela em 360 px de largura, texto em 200% e alto contraste, sem estouro de layout
/// (um overflow vira FlutterError e reprova o teste) e com rótulos acessíveis nos alvos de toque.
void main() {
  const routes = [
    '/',
    '/indicadores/agua',
    '/indicadores/clima',
    '/indicadores/risco',
    '/indicador/volume',
    '/indicador/chuva',
    '/indicador/registros',
    '/mapa',
    '/alertas',
    '/configuracoes',
    '/configuracoes/limiares',
    '/ocorrencias',
    '/ocorrencias/nova',
  ];

  for (final scenario in [
    (name: '360 px · texto 200% · alto contraste', size: const Size(360, 740), scale: 2.0, theme: 'highContrast'),
    (name: '390 px · texto 100% · escuro', size: const Size(390, 844), scale: 1.0, theme: 'dark'),
  ]) {
    for (final route in routes) {
      testWidgets('$route — ${scenario.name}', (tester) async {
        final container = await pumpApp(
          tester,
          size: scenario.size,
          prefs: {
            'consent.version': 1,
            'band.lastSeen': 'attention',
            'settings.textScale': scenario.scale,
            'settings.theme': scenario.theme,
          },
        );
        // A visão geral já foi validada no caso '/'; aqui só interessa a rota.
        if (route != '/') tester.takeException();
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'estouro de layout em $route');

        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }

    testWidgets('detalhe do alerta — ${scenario.name}', (tester) async {
      final container = await pumpApp(
        tester,
        size: scenario.size,
        prefs: {
          'consent.version': 1,
          'band.lastSeen': 'attention',
          'settings.textScale': scenario.scale,
          'settings.theme': scenario.theme,
        },
      );
      tester.takeException();
      final alerts = container.read(alertsProvider).value!;
      expect(alerts, isNotEmpty);
      container.read(routerProvider).go('/alertas/${alerts.first.id}');
      await tester.pumpAndSettle();
      expect(find.text('Como chegamos a este alerta?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('alvos de toque têm pelo menos 48 dp na visão geral', (tester) async {
    await pumpApp(tester, prefs: {'consent.version': 1, 'band.lastSeen': 'attention'});
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}

