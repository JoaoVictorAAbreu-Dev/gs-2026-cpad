import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../core/theme/themes.dart';

/// Versão do texto de consentimento. Mudou o texto → pede consentimento de novo.
const kConsentVersion = 1;

class AppSettings {
  const AppSettings({
    this.themeMode = PulsoThemeMode.system,
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.simpleReading = false,
    this.notifyBandChange = false,
    this.consentVersion = 0,
    this.consentAt,
  });

  final PulsoThemeMode themeMode;

  /// Multiplicador aplicado sobre o tamanho do sistema (1.0–2.0).
  final double textScale;
  final bool reduceMotion;
  final bool simpleReading;
  final bool notifyBandChange;
  final int consentVersion;
  final DateTime? consentAt;

  bool get hasConsent => consentVersion >= kConsentVersion;

  AppSettings copyWith({
    PulsoThemeMode? themeMode,
    double? textScale,
    bool? reduceMotion,
    bool? simpleReading,
    bool? notifyBandChange,
    int? consentVersion,
    DateTime? consentAt,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        simpleReading: simpleReading ?? this.simpleReading,
        notifyBandChange: notifyBandChange ?? this.notifyBandChange,
        consentVersion: consentVersion ?? this.consentVersion,
        consentAt: consentAt ?? this.consentAt,
      );
}

class SettingsController extends Notifier<AppSettings> {
  static const _theme = 'settings.theme';
  static const _scale = 'settings.textScale';
  static const _motion = 'settings.reduceMotion';
  static const _simple = 'settings.simpleReading';
  static const _notify = 'settings.notifyBandChange';
  static const _consent = 'consent.version';
  static const _consentAt = 'consent.at';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    final themeName = p.getString(_theme);
    return AppSettings(
      themeMode: PulsoThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => PulsoThemeMode.system,
      ),
      textScale: (p.getDouble(_scale) ?? 1.0).clamp(1.0, 2.0),
      reduceMotion: p.getBool(_motion) ?? false,
      simpleReading: p.getBool(_simple) ?? false,
      notifyBandChange: p.getBool(_notify) ?? false,
      consentVersion: p.getInt(_consent) ?? 0,
      consentAt: DateTime.tryParse(p.getString(_consentAt) ?? ''),
    );
  }

  Future<void> setTheme(PulsoThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_theme, mode.name);
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale.clamp(1.0, 2.0));
    await _prefs.setDouble(_scale, state.textScale);
  }

  Future<void> setReduceMotion(bool v) async {
    state = state.copyWith(reduceMotion: v);
    await _prefs.setBool(_motion, v);
  }

  Future<void> setSimpleReading(bool v) async {
    state = state.copyWith(simpleReading: v);
    await _prefs.setBool(_simple, v);
  }

  Future<void> setNotifyBandChange(bool v) async {
    state = state.copyWith(notifyBandChange: v);
    await _prefs.setBool(_notify, v);
  }

  Future<void> giveConsent() async {
    final now = ref.read(clockProvider)();
    state = state.copyWith(consentVersion: kConsentVersion, consentAt: now);
    await _prefs.setInt(_consent, kConsentVersion);
    await _prefs.setString(_consentAt, now.toIso8601String());
  }

  /// "Apagar meus dados locais": remove preferências, registros, decisões e cache.
  Future<void> eraseLocalData() async {
    await _prefs.clear();
    ref
      ..invalidateSelf()
      ..invalidate(thresholdsProvider)
      ..invalidate(decisionsProvider)
      ..invalidate(territoryProvider);
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
