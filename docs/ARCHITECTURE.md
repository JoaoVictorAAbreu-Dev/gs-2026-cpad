# Arquitetura

Flutter + Material 3, organizado por funcionalidade (`lib/features/<feature>/{domain,data,presentation}`).

- **Domínio em Dart puro** (`*/domain`): faixas de operação, previsão por tendência, confiança, motor de alertas,
  validações. Testado em unidade, sem Flutter.
- **Dados** (`reservoir/data`): `TerritoryRepository` lê `pulso_data.json` (esquema v1) com fallback
  fonte remota → cache (`shared_preferences`) → asset embutido. `DataResult` informa de onde veio o dado.
- **Estado** (Riverpod): `territoryProvider` (global, assíncrono), `alertsProvider` (derivado, usado por 4 telas),
  `thresholdsProvider`, `decisionsProvider`, `reportsProvider`, `settingsProvider`. Formulários e seletores
  de período usam estado local.
- **Rotas** (go_router): `StatefulShellRoute` com 4 abas; `/indicadores/:aba`, `/alertas/:id`,
  `/ocorrencias/nova?regiao=`, `/ocorrencias/:protocol/enviada`, `/configuracoes/limiares`.
- **Envio de registros**: API simulada (declarada), com fila offline e status real.
- **Decisão humana**: nenhuma regra executa ações; "Encaminhar para análise humana" só registra a decisão.
