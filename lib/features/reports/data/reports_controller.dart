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

  @override
  List<Report> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
    final out = <Report>[];
    for (final item in raw) {
      try {
        out.add(Report.fromJson(jsonDecode(item) as Map<String, dynamic>));
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
  Future<int> flushQueue() async {
    var sent = 0;
    for (final r in state.where((r) => r.status == ReportStatus.queued || r.status == ReportStatus.savedLocally).toList()) {
      final result = await _trySend(r);
      if (result.status == ReportStatus.sent) sent++;
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
