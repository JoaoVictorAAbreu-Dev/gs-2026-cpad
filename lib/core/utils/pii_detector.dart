/// Detecta dados pessoais em texto livre (descrição da ocorrência) para avisar o cidadão
/// e mascarar antes de salvar. Heurística: prefere falso positivo a vazar dado.
enum PiiKind {
  cpf('CPF'),
  phone('telefone'),
  email('e-mail'),
  cep('CEP'),
  streetNumber('endereço com número');

  const PiiKind(this.label);
  final String label;
}

class PiiMatch {
  const PiiMatch(this.kind, this.start, this.end);
  final PiiKind kind;
  final int start;
  final int end;
}

abstract final class PiiDetector {
  static final _patterns = <PiiKind, RegExp>{
    PiiKind.email: RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
    PiiKind.cpf: RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b'),
    PiiKind.cep: RegExp(r'\b\d{5}-\d{3}\b'),
    // (11) 91234-5678 · 11 912345678 · 91234-5678 · +55 11 ...
    PiiKind.phone: RegExp(r'(\+?55\s?)?(\(?\d{2}\)?\s?)?\b9?\d{4}[-\s]?\d{4}\b'),
    PiiKind.streetNumber: RegExp(
      r'\b(rua|r\.|avenida|av\.?|travessa|tv\.|alameda|al\.|estrada|rodovia)\s+[^\d,\n]{2,40},?\s*(n[ºo°.]?\s*)?\d{1,5}\b',
      caseSensitive: false,
    ),
  };

  static List<PiiMatch> find(String text) {
    final found = <PiiMatch>[];
    for (final entry in _patterns.entries) {
      for (final m in entry.value.allMatches(text)) {
        final overlaps = found.any((f) => m.start < f.end && f.start < m.end);
        if (!overlaps) found.add(PiiMatch(entry.key, m.start, m.end));
      }
    }
    found.sort((a, b) => a.start.compareTo(b.start));
    return found;
  }

  static Set<PiiKind> kinds(String text) => find(text).map((m) => m.kind).toSet();

  /// Substitui cada trecho por "[CPF removido]", "[telefone removido]" etc.
  static String mask(String text) {
    final matches = find(text);
    if (matches.isEmpty) return text;
    final b = StringBuffer();
    var cursor = 0;
    for (final m in matches) {
      b
        ..write(text.substring(cursor, m.start))
        ..write('[${m.kind.label} removido]');
      cursor = m.end;
    }
    b.write(text.substring(cursor));
    return b.toString();
  }
}
