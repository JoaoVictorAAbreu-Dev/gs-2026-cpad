# Roteiro do vídeo — PULSO (até 3 minutos)

Cerca de 380 palavras em ritmo calmo ≈ 2 min 45 s. Gravar a tela do celular (ou do navegador em modo celular, 390×844)
e a narração por cena. Cada cena cita o critério da rubrica que demonstra.

| # | Tempo | Na tela | Critério |
|---|---|---|---|
| 1 | 0:00–0:15 | Consentimento → aceitar | Problema, privacidade e consentimento |
| 2 | 0:15–0:40 | Visão geral: 52,9 %, faixa, "o que isso significa", gráfico com previsão, aviso de dados com mais de 3 dias | Dados reais, estados de interface |
| 3 | 0:40–1:05 | Dashboards: Água (tendência, histórico mensal) → Clima (chuva semanal e mensal, Open-Meteo) → Risco territorial (histórico, ranking, benefício social) | 3 dashboards, API externa, benefício social |
| 4 | 1:05–1:30 | Risco › Detalhe do indicador Registros → alerta Zona Leste 2 → janela, risco × confiança, evidências, limitações, "Como calculamos a confiança" → Encaminhar | Fluxo visão geral → indicador → alerta → justificativa, decisão humana |
| 5 | 1:30–1:50 | Configurações → Limiares: erro de validação → limiar 55 % → novo alerta aparece | Formulário com validação, estado compartilhado |
| 6 | 1:50–2:20 | Mapa → Zona Leste 2 → Registrar aqui → 4 etapas (telefone é removido) → sucesso → Simular sem internet → Meus registros "Aguardando internet" | Formulário, anonimização, persistência e offline |
| 7 | 2:20–2:40 | Alto contraste + texto 200 % + "Ver como tabela" | Acessibilidade |
| 8 | 2:40–2:55 | README no GitHub (prints, testes) | Documentação e fechamento |

## Narração

**1 — Abertura.** Metade da Grande São Paulo bebe água do Sistema Cantareira. Quando o reservatório muda de faixa,
a retirada de água diminui, e o morador costuma saber tarde. O PULSO é um radar territorial que antecipa essa mudança.
Antes de tudo, a pessoa vê o que guardamos e o que nunca pedimos.

**2 — Visão geral.** Os números são reais, da Sabesp: 52,9 % em 7 de novembro, faixa Atenção, quase trinta pontos acima de
um ano atrás. A frase explica o que isso significa para quem mora aqui. O gráfico mostra a previsão para 7 dias com a faixa
de erro. Como o último dado tem mais de três dias, o app avisa e reduz a confiança das previsões.

**3 — Dashboards.** Em Água, a previsão vem do mesmo modelo Ridge do nosso projeto de dados, e o app mostra quanto cada
fator pesou e quanto o modelo erra. Em Clima, chuva da bacia e a previsão do tempo da Open-Meteo, com cópia salva para usar
sem internet. Em Risco territorial, o histórico de registros por região e o benefício social: reexecutamos a regra de alerta em todo o histórico e ela teria avisado as seis
pioras de faixa, com 5,8 dias de antecedência em média.

**4 — Alertas.** Do detalhe do indicador chego ao alerta. Cada alerta mostra a janela de tempo, separa risco e confiança, explica como a confiança foi calculada e quando ela cai, e lista evidências e limitações. O app nunca age
sozinho: a pessoa encaminha para análise humana e a decisão fica registrada.

**5 — Limiares.** O gestor define quando o app deve avisar. Valor inválido é recusado com uma mensagem clara. Com um limiar de
55 %, um novo alerta aparece na hora, em todas as telas.

**6 — Registro.** No mapa, cada hexágono é uma região, com cor, ícone e texto. Daqui o cidadão registra uma ocorrência em quatro
etapas. Se ele digitar um telefone, o app avisa e remove antes de salvar. Sem internet, o registro fica salvo e aguarda na fila.

**7 — Acessibilidade.** Alto contraste, texto até 200 % sem quebrar a tela, e qualquer gráfico pode virar tabela para leitores de tela.

**8 — Encerramento.** Flutter, Riverpod e go_router, dados da Sabesp e da Open-Meteo e 63 testes automatizados. PULSO: tempo
para agir antes da água faltar.

## Dicas

- Antes de gravar: Configurações › Apagar meus dados locais (para começar pelo consentimento).
- Os dados de ocorrências por região são **sintéticos** e aparecem com a etiqueta "DADOS SINTÉTICOS"; não citar esses números como reais.
- Pode dividir a narração: cenas 1–4 e 5–8.
