Integrantes: João Victor Alves de Abreu (RM 564946) e Rodrigo Kenshin Viana Matayoshi (RM 564026).

# PULSO — Radar Territorial

> Painel de inteligência territorial que antecipa a queda do Sistema Cantareira e mostra, para cada alerta, a evidência, a confiança e os limites — a decisão final é sempre humana.

## Problema e público

A Região Metropolitana de São Paulo depende do Sistema Cantareira, que opera em faixas definidas pela Resolução Conjunta ANA/DAEE nº 925/2017. Quando o volume cai de faixa, a retirada de água é reduzida — e moradores e gestores costumam saber disso tarde.

- **Gestores públicos**: acompanham indicadores, previsões e alertas, ajustam limiares e encaminham alertas para análise humana.
- **Cidadãos**: entendem a situação em linguagem simples e registram ocorrências sem se identificar.
- **Impacto esperado**: dias de antecedência para avisar a população e priorizar regiões.

## Integrantes

| Nome | RM |
|---|---|
| João Victor Alves de Abreu | 564946 |
| Rodrigo Kenshin Viana Matayoshi | 564026 |

## Demonstração visual

_Prints pendentes — serão salvos em `assets/screenshots/`._

## Funcionalidades

- [x] Consentimento explícito antes do uso, com lista do que é guardado e do que não é pedido
- [x] Visão geral: volume, faixa de operação, variação em 1 ano, "o que isso significa", gráfico 30 dias + previsão
- [x] Indicadores em 3 painéis (Recursos, Clima, Serviços) com rota parametrizada `/indicadores/:aba`
- [x] Alertas por regras transparentes, com risco, confiança, evidências, limitações e regra usada
- [x] Detalhe do alerta (`/alertas/:id`) e encaminhamento para análise humana (registrado, sem ação automática)
- [x] Limiares de alerta configuráveis (formulário com validação)
- [x] Estados de carregamento, erro, vazio, cópia salva (offline) e dados desatualizados
- [x] Uso sem conexão: fonte remota → cache local → pacote embutido
- [x] Temas claro, escuro e alto contraste; texto até 200%; reduzir animações; leitura simples
- [x] "Ver como tabela" nos gráficos para leitores de tela
- [x] Detector de dados pessoais (CPF, telefone, e-mail, CEP, endereço) para os registros
- [ ] Registro de ocorrência (4 etapas) e "Meus registros" com fila offline
- [ ] Cartograma hexagonal com previsão +7 dias
- [ ] Previsão do tempo (Open-Meteo)
- [ ] Notificação local na mudança de faixa

## Dados e alertas

- **Fonte**: pacote `pulso_data.json` (esquema v1) publicado pelo pipeline do projeto de Data Science, com fallback para cache e para o pacote embutido em `assets/data/`.
- **Situação atual**: o pacote embutido é **sintético** (gerado por `tool/generate_placeholder_data.py`) e o app exibe "DADOS SINTÉTICOS" em todos os cards enquanto `origin != "real"`.
- **Previsão**: usa a previsão do modelo treinado quando o pacote a traz; senão, tendência linear dos últimos 14 dias, com erro típico = desvio dos resíduos × √horizonte (piso de 0,2 p.p.).
- **Regras**:
  1. *Previsão abaixo do limiar*: chance de ficar abaixo do limite da faixa atual (ou do limiar do gestor) ≥ 30%. Chance = Φ((limiar − previsão) / erro típico).
  2. *Queda contínua*: N janelas de 30 dias seguidas com média menor que a anterior.
  3. *Alta de ocorrências*: ≥ 5 registros na semana e ≥ 1,5× a semana anterior.
- **Confiança**: < 60% baixa · 60–85% média · > 85% alta.
- **Quando não confiar**: dados com mais de 3 dias reduzem a confiança em um nível; com mais de 30 dias o alerta vira apenas informativo. A chance supõe erro aproximadamente normal; não considera chuvas extremas nem mudanças de operação.
- **Vieses**: registros dependem de acesso ao app (regiões com menos acesso aparecem menos); por isso os registros são normalizados por 10 mil habitantes.

## Privacidade e inclusão

- Nada sai do aparelho sem consentimento; sem nome, telefone, CPF, e-mail ou endereço.
- Descrições passam por um detector de dados pessoais, que avisa e mascara antes de salvar.
- "Apagar meus dados locais" remove preferências, decisões, limiares e cache.
- Gravidade sempre com ícone + texto (nunca só cor); `Semantics` nos números e gráficos; alvos de toque ≥ 48 dp.

## Tecnologias e decisões técnicas

| Escolha | Por quê |
|---|---|
| Flutter + Material 3 | Requisito da disciplina; `ThemeExtension` para cores semânticas nos 3 temas |
| flutter_riverpod | Estado global separado do local; `AsyncValue` dá carregando/erro/dados; testável sem `BuildContext` |
| go_router (`StatefulShellRoute`) | Rotas nomeadas com parâmetros e 4 abas que preservam o estado |
| dio | Timeout e erros tipados na fonte remota |
| shared_preferences | Preferências, consentimento, limiares, decisões e cache da última série |
| Domínio em Dart puro | Motor de alertas e validações testados em unidade, sem Flutter |

Estrutura: `lib/core` (tema, utilitários, resultado de dados), `lib/shared/widgets` (componentes), `lib/features/<feature>/{domain,data,presentation}`.

## Como executar

```bash
git clone <repo> && cd pulso
flutter create . --project-name pulso --platforms=android,ios   # gera as pastas de plataforma, mantém lib/
flutter pub get
flutter test
flutter run                                                      # usa o pacote embutido
flutter run --dart-define=PULSO_DATA_URL=https://<usuario>.github.io/pulso-data/pulso_data.json
```

Nenhuma chave de API é necessária. Variáveis vão por `--dart-define` (ver `.env.example`).

## Vídeo

_Link pendente._

## Documentação do planejamento

Requisitos da rubrica, checklist de entrega e progresso em [`docs/`](docs/REQUIREMENTS.md).

## Licença

Projeto acadêmico — FIAP, Global Solution 2026.2.
