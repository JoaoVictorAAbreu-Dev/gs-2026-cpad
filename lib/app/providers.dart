import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/result/data_result.dart';
import '../features/alerts/domain/alert.dart';
import '../features/alerts/domain/alert_engine.dart';
import '../features/alerts/domain/lead_time_backtest.dart';
import '../features/reservoir/data/territory_data.dart';
import '../features/reservoir/data/territory_repository.dart';
import '../features/reservoir/domain/operating_band.dart';
import '../features/reservoir/domain/reservoir_models.dart';
import '../features/reservoir/domain/trend_forecaster.dart';

/// Sobrescrito em `main()` com a instância já carregada (evita `await` em cada leitura).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider precisa ser sobrescrito no bootstrap'),
);

/// Relógio injetável: testes e a demonstração podem fixar "agora".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final territoryRepositoryProvider = Provider<TerritoryRepository>(
  (ref) => TerritoryRepository(prefs: ref.watch(sharedPreferencesProvider)),
);

/// Estado global principal: pacote de dados do território + de onde veio.
/// `AsyncValue` dá carregando/erro/dados para todas as telas que o observam.
class TerritoryController extends AsyncNotifier<DataResult<TerritoryData>> {
  @override
  Future<DataResult<TerritoryData>> build() => ref.watch(territoryRepositoryProvider).load();

  /// Puxar para atualizar: mantém os dados atuais visíveis enquanto busca.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(territoryRepositoryProvider).load());
  }
}

final territoryProvider =
    AsyncNotifierProvider<TerritoryController, DataResult<TerritoryData>>(TerritoryController.new);

/// Snapshot do reservatório com previsão garantida: usa a do modelo (pacote) ou,
/// na falta dela, a tendência linear local (método declarado na interface).
final reservoirProvider = Provider<AsyncValue<DataResult<ReservoirSnapshot>>>((ref) {
  return ref.watch(territoryProvider).whenData((result) => result.map((data) {
        final r = data.reservoir;
        if (r.forecast != null) return r;
        return ReservoirSnapshot(
          name: r.name,
          series: r.series,
          origin: r.origin,
          sourceLabel: r.sourceLabel,
          forecast: const TrendForecaster().forecast(r.series),
          factors: r.factors,
          metrics: r.metrics,
        );
      }));
});

// ── Limiares do gestor ───────────────────────────────────────────────────────
class ThresholdsController extends Notifier<AlertThresholds> {
  static const _key = 'settings.thresholds';

  @override
  AlertThresholds build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const AlertThresholds();
    try {
      return AlertThresholds.fromJson(_decode(raw));
    } catch (_) {
      return const AlertThresholds();
    }
  }

  Future<void> save(AlertThresholds t) async {
    state = t;
    await ref.read(sharedPreferencesProvider).setString(_key, _encode(t.toJson()));
  }

  Future<void> reset() async {
    state = const AlertThresholds();
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final thresholdsProvider = NotifierProvider<ThresholdsController, AlertThresholds>(ThresholdsController.new);

/// Alertas derivados: recalculados sempre que dados, limiares ou relógio mudam.
/// Compartilhado por Visão geral, Alertas, Detalhe e Mapa.
final alertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final territory = ref.watch(territoryProvider);
  final reservoir = ref.watch(reservoirProvider);
  final thresholds = ref.watch(thresholdsProvider);
  final now = ref.watch(clockProvider)();
  return reservoir.whenData((r) {
    final regions = territory.valueOrNull?.data.regions ?? const <Region>[];
    return const AlertEngine().evaluate(
      reservoir: r.data,
      now: now,
      thresholds: thresholds,
      regions: [for (final region in regions) region.toActivity()],
    );
  });
});

final alertByIdProvider = Provider.family<Alert?, String>((ref, id) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? const <Alert>[];
  for (final a in alerts) {
    if (a.id == id) return a;
  }
  return null;
});

// ── Decisões humanas (registro de encaminhamentos) ──────────────────────────
class HumanDecision {
  const HumanDecision({required this.alertId, required this.alertTitle, required this.at});
  final String alertId;
  final String alertTitle;
  final DateTime at;

  Map<String, dynamic> toJson() => {'alertId': alertId, 'alertTitle': alertTitle, 'at': at.toIso8601String()};
  factory HumanDecision.fromJson(Map<String, dynamic> j) => HumanDecision(
        alertId: j['alertId'] as String,
        alertTitle: j['alertTitle'] as String,
        at: DateTime.parse(j['at'] as String),
      );
}

class DecisionsController extends Notifier<List<HumanDecision>> {
  static const _key = 'decisions.v1';

  @override
  List<HumanDecision> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
    final out = <HumanDecision>[];
    for (final item in raw) {
      try {
        out.add(HumanDecision.fromJson(_decode(item)));
      } catch (_) {
        // Ignora entradas inválidas sem derrubar a lista.
      }
    }
    return out;
  }

  /// Apenas registra que uma pessoa encaminhou o alerta. Nenhuma ação automática é tomada.
  Future<void> forward(Alert alert) async {
    if (isForwarded(alert.id)) return;
    final d = HumanDecision(alertId: alert.id, alertTitle: alert.title, at: ref.read(clockProvider)());
    state = [d, ...state];
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_key, [for (final x in state) _encode(x.toJson())]);
  }

  bool isForwarded(String alertId) => state.any((d) => d.alertId == alertId);
}

final decisionsProvider = NotifierProvider<DecisionsController, List<HumanDecision>>(DecisionsController.new);

Map<String, dynamic> _decode(String raw) => jsonDecode(raw) as Map<String, dynamic>;
String _encode(Map<String, dynamic> v) => jsonEncode(v);

// ── Benefício social (backtest da regra de alerta sobre a série) ──────────────
final socialImpactProvider = Provider<LeadTimeResult?>((ref) {
  final r = ref.watch(reservoirProvider).valueOrNull?.data;
  if (r == null) return null;
  return const LeadTimeBacktest().run(r.series);
});

// ── Mudança de faixa desde a última visita ──────────────────────────────────
class BandChange {
  const BandChange({required this.from, required this.to});
  final OperatingBand from;
  final OperatingBand to;
  bool get improved => to.level < from.level;
}

/// Compara a faixa atual com a última faixa vista neste aparelho.
/// A tela chama `markSeen()` depois de mostrar o aviso.
class BandChangeController extends Notifier<BandChange?> {
  static const _key = 'band.lastSeen';

  @override
  BandChange? build() {
    final current = ref.watch(reservoirProvider).valueOrNull?.data.latest.band;
    if (current == null) return null;
    final prefs = ref.watch(sharedPreferencesProvider);
    final last = prefs.getString(_key);
    if (last == null) {
      // Primeira visita: registra sem avisar.
      unawaited(prefs.setString(_key, current.name));
      return null;
    }
    final previous = OperatingBand.values.where((b) => b.name == last).firstOrNull;
    if (previous == null || previous == current) return null;
    return BandChange(from: previous, to: current);
  }

  Future<void> markSeen() async {
    final current = ref.read(reservoirProvider).valueOrNull?.data.latest.band;
    if (current == null) return;
    await ref.read(sharedPreferencesProvider).setString(_key, current.name);
    state = null;
  }
}

final bandChangeProvider = NotifierProvider<BandChangeController, BandChange?>(BandChangeController.new);
