import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/pii_detector.dart';
import '../domain/report.dart';
import 'report_api.dart';

/// Conectividade simulada (alternável em Configurações para demonstrar a fila offline).
/// Em produção, viria de `connectivity_plus`.
final simulatedOnlineProvider = StateProvider<bool>((ref) => true);

final reportApiProvider = Provider<ReportApi>(
  (ref) => SimulatedReportApi(isOnline: () => ref.read(simulatedOnlineProvider)),
);

/// Registros do cidadão, persistidos no aparelho. Compartilhado por:
/// formulário, sucesso, Meus registros e Configurações.
class ReportsController extends Notifier<List<Report>> {
  static const _key = 'reports.v1';

  bool _flushing = false;

  @override
  List<Report> build() {
    // Ao voltar a conexão, envia o que ficou na fila.
    ref.listen<bool>(simulatedOnlineProvider, (previous, online) {
      if (online && previous == false) unawaited(flushQueue());
    });
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
    final out = <Report>[];
    for (final item in raw) {
      try {
        final r = Report.fromJson(jsonDecode(item) as Map<String, dynamic>);
        // "Salvo no aparelho" é transitório; se o app fechou antes do envio, volta para a fila.
        out.add(r.status == ReportStatus.savedLocally ? r.copyWith(status: ReportStatus.queued) : r);
      } catch (_) {
        // Entrada corrompida não derruba a lista.
      }
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  /// Salva primeiro (nunca perde o registro) e depois tenta enviar.
  Future<Report> create({
    required ReportType type,
    required String regionId,
    required String regionName,
    required String description,
  }) async {
    final now = ref.read(clockProvider)();
    final report = Report(
      protocol: Report.newProtocol(now),
      type: type,
      regionId: regionId,
      regionName: regionName,
      description: PiiDetector.mask(description.trim()),
      createdAt: now,
      status: ReportStatus.savedLocally,
    );
    state = [report, ...state];
    await _persist();
    return _trySend(report);
  }

  /// Reenvia tudo que ficou na fila (botão "Enviar agora" e ao voltar a conexão).
  /// Ignora chamadas enquanto um envio da fila já está em andamento (evita envio duplicado).
  Future<int> flushQueue() async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      for (final r in state.where((r) => r.status == ReportStatus.queued).toList()) {
        final result = await _trySend(r);
        if (result.status == ReportStatus.sent) sent++;
      }
    } finally {
      _flushing = false;
    }
    return sent;
  }

  Future<Report> _trySend(Report report) async {
    Report updated;
    try {
      await ref.read(reportApiProvider).send(report);
      updated = report.copyWith(status: ReportStatus.sent, sentAt: ref.read(clockProvider)());
    } on ReportSendException {
      updated = report.copyWith(status: ReportStatus.queued);
    }
    state = [for (final r in state) r.protocol == report.protocol ? updated : r];
    await _persist();
    return updated;
  }

  Report? byProtocol(String protocol) => state.where((r) => r.protocol == protocol).firstOrNull;

  Future<void> _persist() => ref
      .read(sharedPreferencesProvider)
      .setStringList(_key, [for (final r in state) jsonEncode(r.toJson())]);
}

final reportsProvider = NotifierProvider<ReportsController, List<Report>>(ReportsController.new);

final pendingReportsProvider = Provider<int>(
  (ref) => ref.watch(reportsProvider).where((r) => r.status == ReportStatus.queued).length,
);
