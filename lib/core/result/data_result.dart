/// De onde veio o dado que está na tela. Alimenta DataSourceTag, OfflineBanner e StaleDataBanner
/// sem espalhar lógica de conectividade pelas telas.
enum Freshness {
  /// Acabou de chegar da fonte remota.
  live,

  /// Fonte remota falhou; usando a última cópia salva no aparelho.
  cached,

  /// Sem rede e sem cache; usando o pacote embutido no app.
  bundled,
}

class DataResult<T> {
  const DataResult({
    required this.data,
    required this.freshness,
    required this.fetchedAt,
    this.remoteError,
  });

  final T data;
  final Freshness freshness;

  /// Quando esta cópia foi obtida da fonte (para "última cópia salva ontem, 18:40").
  final DateTime fetchedAt;

  /// Motivo da falha remota, quando houve (exibido em "Parte dos dados não carregou").
  final String? remoteError;

  bool get isFallback => freshness != Freshness.live;

  DataResult<R> map<R>(R Function(T) f) => DataResult<R>(
        data: f(data),
        freshness: freshness,
        fetchedAt: fetchedAt,
        remoteError: remoteError,
      );
}
