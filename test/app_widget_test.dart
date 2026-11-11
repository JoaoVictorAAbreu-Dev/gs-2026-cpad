import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/app.dart';
import 'package:pulso/app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(instance),
        // Dia seguinte ao último dado do pacote: dados "frescos".
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 9)),
      ],
      child: const PulsoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem consentimento, mostra a tela de consentimento com botão desabilitado', (tester) async {
    await pumpApp(tester, {});
    expect(find.text('Seus dados, suas regras'), findsOneWidget);
    // A lista é preguiçosa: rola até o fim para o botão ser montado.
    await tester.scrollUntilVisible(find.text('Aceitar e continuar'), 200, scrollable: find.byType(Scrollable).first);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Aceitar e continuar'));
    expect(button.onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Aceitar e continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Cantareira · volume útil'), findsOneWidget);
  });

  testWidgets('com consentimento, abre a visão geral com aviso de decisão humana', (tester) async {
    await pumpApp(tester, {'consent.version': 1});
    expect(find.text('Cantareira · volume útil'), findsOneWidget);
    expect(find.text('DADOS SINTÉTICOS'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('decisão final é sempre de uma pessoa'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('decisão final é sempre de uma pessoa'), findsWidgets);
  });
}
