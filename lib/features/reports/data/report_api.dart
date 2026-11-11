import 'dart:async';

import '../domain/report.dart';

/// Envio de registros para a equipe de triagem.
abstract interface class ReportApi {
  Future<void> send(Report report);
}

/// API SIMULADA (declarado no README): não há backend real nesta entrega.
/// Simula latência e falha quando o aparelho está offline, para exercitar a fila.
class SimulatedReportApi implements ReportApi {
  SimulatedReportApi({required this.isOnline, this.latency = const Duration(milliseconds: 600)});

  final bool Function() isOnline;
  final Duration latency;

  @override
  Future<void> send(Report report) async {
    await Future<void>.delayed(latency);
    if (!isOnline()) throw const ReportSendException('Sem conexão.');
  }
}

class ReportSendException implements Exception {
  const ReportSendException(this.message);
  final String message;
  @override
  String toString() => message;
}
