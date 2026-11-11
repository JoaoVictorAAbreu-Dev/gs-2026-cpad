import 'dart:math' as math;

/// Tipos de ocorrência que o cidadão pode registrar.
enum ReportType {
  noWater('Falta de água', 'no_water'),
  lowPressure('Baixa pressão', 'low_pressure'),
  streetLeak('Vazamento na rua', 'street_leak'),
  dirtyWater('Água turva ou com cheiro', 'dirty_water');

  const ReportType(this.label, this.code);
  final String label;
  final String code;

  static ReportType fromCode(String code) => values.firstWhere((t) => t.code == code);
}

/// Ciclo de vida do registro. A interface mostra só estados reais — nada de "enviado" antes do envio.
enum ReportStatus {
  savedLocally('Salvo no aparelho'),
  queued('Aguardando internet'),
  sent('Enviado'),
  triaged('Triado pela equipe');

  const ReportStatus(this.label);
  final String label;
}

class Report {
  const Report({
    required this.protocol,
    required this.type,
    required this.regionId,
    required this.regionName,
    required this.description,
    required this.createdAt,
    required this.status,
    this.sentAt,
  });

  /// Aleatório, sem relação com o aparelho ou a pessoa.
  final String protocol;
  final ReportType type;
  final String regionId;
  final String regionName;

  /// Já mascarada pelo detector de dados pessoais.
  final String description;
  final DateTime createdAt;
  final ReportStatus status;
  final DateTime? sentAt;

  Report copyWith({ReportStatus? status, DateTime? sentAt}) => Report(
        protocol: protocol,
        type: type,
        regionId: regionId,
        regionName: regionName,
        description: description,
        createdAt: createdAt,
        status: status ?? this.status,
        sentAt: sentAt ?? this.sentAt,
      );

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'type': type.code,
        'regionId': regionId,
        'regionName': regionName,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
      };

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        protocol: j['protocol'] as String,
        type: ReportType.fromCode(j['type'] as String),
        regionId: j['regionId'] as String,
        regionName: j['regionName'] as String,
        description: j['description'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: ReportStatus.values.byName(j['status'] as String),
        sentAt: DateTime.tryParse(j['sentAt'] as String? ?? ''),
      );

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// PUL-2026-7K3QX: ano + 5 caracteres aleatórios sem ambiguidade (sem 0/O, 1/I).
  static String newProtocol(DateTime now, [math.Random? random]) {
    final r = random ?? math.Random.secure();
    final code = List.generate(5, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
    return 'PUL-${now.year}-$code';
  }
}

/// Regras do formulário de registro (puras, testadas em unidade).
abstract final class ReportValidator {
  static const minDescription = 20;
  static const maxDescription = 500;

  static String? description(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Descreva o que está acontecendo.';
    if (v.length < minDescription) {
      return 'Descreva com pelo menos $minDescription caracteres (faltam ${minDescription - v.length}).';
    }
    if (v.length > maxDescription) return 'Use no máximo $maxDescription caracteres.';
    return null;
  }

  static String? type(ReportType? t) => t == null ? 'Escolha o tipo de ocorrência.' : null;

  static String? region(String? id) => (id == null || id.isEmpty) ? 'Escolha a região.' : null;
}
