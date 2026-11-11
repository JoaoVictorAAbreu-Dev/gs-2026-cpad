import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/app/providers.dart';
import 'package:pulso/core/theme/themes.dart';
import 'package:pulso/features/alerts/domain/alert_engine.dart';
import 'package:pulso/features/reports/data/report_api.dart';
import 'package:pulso/features/reports/data/reports_controller.dart';
import 'package:pulso/features/reports/domain/report.dart';
import 'package:pulso/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Fechar e reabrir o app": cada ProviderContainer é uma execução nova que só compartilha o
/// armazenamento local. Prova que ocorrências, limiares e preferências sobrevivem sem conexão.
void main() {
  late SharedPreferences prefs;
  var online = false;

  ProviderContainer openApp() => ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 10, 9)),
        reportApiProvider.overrideWithValue(SimulatedReportApi(isOnline: () => online, latency: Duration.zero)),
      ]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    online = false;
  });

  test('ocorrência feita sem conexão fica na fila, sobrevive ao reinício e é enviada depois', () async {
    final first = openApp();
    final report = await first.read(reportsProvider.notifier).create(
          type: ReportType.noWater,
          regionId: 'zn',
          regionName: 'Zona Norte',
          description: 'Sem água desde ontem à noite na minha rua, caixa vazia.',
        );
    expect(report.status, ReportStatus.queued);
    first.dispose();

    final second = openApp();
    final restored = second.read(reportsProvider);
    expect(restored, hasLength(1));
    expect(restored.single.protocol, report.protocol);
    expect(restored.single.status, ReportStatus.queued);
    expect(second.read(pendingReportsProvider), 1);

    online = true;
    expect(await second.read(reportsProvider.notifier).flushQueue(), 1);
    second.dispose();

    final third = openApp();
    expect(third.read(reportsProvider).single.status, ReportStatus.sent);
    expect(third.read(pendingReportsProvider), 0);
    third.dispose();
  });

  test('limiares personalizados sobrevivem ao reinício', () async {
    final first = openApp();
    await first.read(thresholdsProvider.notifier).save(
          const AlertThresholds(volumeFloor: 45, minProbability: 0.5, declineMonths: 2, surgeMinCount: 6, surgeRatio: 2),
        );
    first.dispose();

    final t = openApp().read(thresholdsProvider);
    expect(t.volumeFloor, 45);
    expect(t.minProbability, 0.5);
    expect(t.declineMonths, 2);
    expect(t.surgeMinCount, 6);
    expect(t.surgeRatio, 2);
  });

  test('preferências e consentimento sobrevivem ao reinício; "apagar dados" limpa tudo', () async {
    final first = openApp();
    final settings = first.read(settingsProvider.notifier);
    await settings.giveConsent();
    await settings.setTheme(PulsoThemeMode.highContrast);
    await settings.setTextScale(1.6);
    await settings.setSimpleReading(true);
    first.dispose();

    final second = openApp();
    final s = second.read(settingsProvider);
    expect(s.hasConsent, isTrue);
    expect(s.themeMode, PulsoThemeMode.highContrast);
    expect(s.textScale, 1.6);
    expect(s.simpleReading, isTrue);

    await second.read(settingsProvider.notifier).eraseLocalData();
    second.dispose();

    final third = openApp();
    expect(third.read(settingsProvider).hasConsent, isFalse);
    expect(third.read(reportsProvider), isEmpty);
    third.dispose();
  });
}
