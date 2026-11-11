import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('sem consentimento, mostra a tela de consentimento com botão desabilitado', (tester) async {
    await pumpApp(tester);
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

  testWidgets('com consentimento, abre a visão geral com dados reais e aviso de decisão humana', (tester) async {
    await pumpApp(tester, prefs: {'consent.version': 1});
    expect(find.text('Cantareira · volume útil'), findsOneWidget);
    expect(find.text('52,9%'), findsOneWidget);
    expect(find.text('DADOS REAIS'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('decisão final é sempre de uma pessoa'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('decisão final é sempre de uma pessoa'), findsWidgets);
  });

  testWidgets('avisa quando a faixa mudou desde a última visita', (tester) async {
    await pumpApp(tester, prefs: {'consent.version': 1, 'band.lastSeen': 'restriction'});
    expect(find.text('A faixa mudou desde sua última visita'), findsOneWidget);
    expect(find.textContaining('Restrição → Atenção'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('A faixa mudou desde sua última visita'), findsNothing);
  });

  testWidgets('com a preferência ligada, a mudança de faixa gera uma notificação do sistema (uma vez)', (tester) async {
    final fake = FakeNotificationService();
    await pumpApp(
      tester,
      notifications: fake,
      prefs: {'consent.version': 1, 'band.lastSeen': 'restriction', 'settings.notifyBandChange': true},
    );
    expect(fake.shown, hasLength(1));
    expect(fake.shown.single.title, 'Cantareira melhorou de faixa: Restrição → Atenção');
    expect(fake.shown.single.body, startsWith('Volume útil em 52,9%'));
  });

  testWidgets('com a preferência desligada, não notifica', (tester) async {
    final fake = FakeNotificationService();
    await pumpApp(tester, notifications: fake, prefs: {'consent.version': 1, 'band.lastSeen': 'restriction'});
    expect(fake.shown, isEmpty);
  });
}
