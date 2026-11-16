# Roteiro de apresentação guiado pela tela

Para apresentar o PULSO ao vivo (ou gravar a tela com a sua voz) com o app aberto na sua frente. Cada bloco diz **o que abrir**, **o que apontar** e **o que falar**. Duração: cerca de 7 minutos em ritmo calmo. O corte de 3 minutos para o vídeo está no fim e usa o mesmo caminho.

Antes de começar: app instalado (APK da release v1.0.0 ou `flutter run`), tema claro, texto em 100 %, "Simular sem internet" desligado, consentimento ainda não aceito.

---

## 1. Abertura (0:00 · 20 s)

**Abrir:** tela de consentimento. **Apontar:** a marca PULSO.

> Este é o PULSO, um radar territorial para antecipar a crise hídrica do Sistema Cantareira. Ele pega o volume dos reservatórios, a chuva e os registros dos moradores, e transforma isso em alertas que uma pessoa consegue entender, questionar e decidir. Vou mostrar o app do começo ao fim, na ordem em que alguém o usaria.

## 2. Consentimento (0:20 · 30 s)

**Apontar:** a lista "o que guardamos" e "o que nunca pedimos"; o botão de aceite.

> A primeira tela é o consentimento. O app diz o que guarda no aparelho e o que nunca pede: nome, CPF, telefone, e-mail ou endereço. Só a região. Nada sai do aparelho sem eu aceitar, e depois posso apagar tudo nas configurações. Vou aceitar.

**Fazer:** tocar em aceitar.

## 3. Visão geral (0:50 · 60 s)

**Apontar, de cima para baixo:** etiqueta DADOS REAIS; número do volume; faixa; "o que isso significa"; gráfico com a previsão e a faixa de erro; alerta em destaque; indicador de benefício social.

> Na visão geral, o número principal é o volume útil do Cantareira: cinquenta e dois vírgula nove por cento, dados reais da Sabesp. Ao lado, a faixa de operação da ANA, que hoje é Atenção, escrita em texto e com ícone, não só com cor.
>
> Logo abaixo, uma frase em português simples explica o que isso significa na prática. O gráfico mostra o histórico e a previsão de sete dias, com a faixa de erro do modelo. O erro médio é de zero vírgula oito ponto percentual, contra um vírgula um de quem só repete o valor de hoje.
>
> Aqui embaixo está o alerta mais importante e o indicador de benefício social: no histórico real, o PULSO avisou as seis pioras de faixa, com quase seis dias de antecedência.

## 4. Dashboard Água (1:50 · 40 s)

**Abrir:** aba Indicadores → Água. **Fazer:** trocar entre 7, 30 e 90 dias; tocar numa barra do histórico mensal; abrir "Ver como tabela".

> O primeiro dashboard é o da água. O volume aparece em sete, trinta ou noventa dias, sobre as faixas de referência, com a tendência em ponto percentual por dia, o mínimo, o máximo e a previsão. Embaixo, o histórico de doze meses, cada mês comparado com o mesmo mês do ano anterior. E o gráfico mostra o erro do modelo e quanto cada fator contribui para a previsão. Todo gráfico tem o botão "ver como tabela", para quem usa leitor de tela.

## 5. Dashboard Clima (2:30 · 35 s)

**Abrir:** aba Clima. **Apontar:** chuva acumulada contra o ano anterior; chuva por semana; chuva por mês; previsão de cinco dias.

> No clima, a chuva da bacia: acumulada contra o ano anterior, por semana, com tendência, e por mês. A previsão de cinco dias vem da Open-Meteo, uma API real, consultada quando abro esta aba. Se eu estiver sem internet, o app mostra a última cópia salva, com data e hora, e o resto do painel continua funcionando.

## 6. Dashboard Risco territorial (3:05 · 35 s)

**Abrir:** aba Risco. **Apontar:** etiqueta DADOS SINTÉTICOS; regiões por nível hoje e em sete dias; registros por semana; ranking por cem mil habitantes.

> O terceiro painel é o risco por região: quantas regiões estão em cada nível hoje e daqui a sete dias, os registros de falta de água por semana com a tendência, e o ranking por cem mil habitantes, para não punir só as regiões mais populosas. Atenção a esta etiqueta: os registros por região são dados sintéticos, porque não existe base pública. O app avisa isso na tela.

## 7. Detalhe do indicador (3:40 · 25 s)

**Fazer:** tocar no indicador Volume (ou Registros). **Apontar:** o que mede, unidade, fonte, limitações, histórico longo, lista de alertas gerados.

> Tocando num indicador, vejo o que ele mede, a unidade, a fonte, as limitações e o histórico longo. E, no fim, a lista dos alertas que esse indicador gerou, que é o caminho para a justificativa.

## 8. Mapa territorial (4:05 · 20 s)

**Abrir:** aba Mapa. **Fazer:** alternar Hoje e +7 dias; tocar numa região.

> No mapa, as represas e as regiões sobre o OpenStreetMap, com o nível de risco hoje ou em sete dias. Sem internet, o mapa vira um cartograma e uma lista, que continuam funcionando.

## 9. Alertas e justificativa (4:25 · 55 s)

**Abrir:** aba Alertas → um alerta de previsão. **Apontar, rolando:** janela; risco × confiança; evidências; limitações; "Como calculamos a confiança"; regra usada; aviso de decisão humana; botão de encaminhar.

> Os alertas vêm ordenados por gravidade e prazo, cada um com a sua janela de tempo. Abrindo um, o app separa duas coisas: o risco e a confiança. Depois mostra as evidências, as limitações e a regra que disparou o alerta.
>
> Esta seção explica como a confiança é calculada: pela chance de o volume ficar abaixo do limiar, e diz quando ela cai, por exemplo quando o último dado tem mais de três dias, ou quando o dado é sintético. O alerta apoia a decisão, mas não decide. Uma pessoa encaminha para análise, o app registra data e hora, e nada acontece automaticamente.

**Fazer:** tocar em encaminhar e mostrar o registro com data e hora.

## 10. Registro de ocorrência (5:20 · 40 s)

**Abrir:** botão de registrar ocorrência. **Fazer:** deixar um campo vazio e mostrar o erro; digitar um telefone na descrição; avançar até enviar; mostrar o protocolo.

> O cidadão registra uma ocorrência em quatro etapas, com validação em cada uma. Se eu esquecer um campo, o app diz qual. Se eu digitar um telefone na descrição, ele avisa e remove o dado antes de salvar. Ao enviar, recebo um protocolo aleatório, sem nenhum identificador do aparelho.

## 11. Meus registros e modo offline (6:00 · 30 s)

**Abrir:** Configurações → ligar "Simular sem internet" → registrar outra ocorrência → Meus registros → desligar a simulação → "Enviar agora".

> Sem internet, o registro é salvo primeiro no aparelho e fica como "aguardando internet". Quando a conexão volta, ele é reenviado pelo botão enviar agora. Tudo isso sobrevive ao fechamento do app, e existe um teste automatizado que reabre o app três vezes para provar.

## 12. Configurações e limiares do gestor (6:30 · 45 s)

**Abrir:** Configurações → Limiares de alerta. **Fazer:** digitar um valor inválido (por exemplo 150) e mostrar a mensagem; digitar 55 e salvar; voltar para Alertas.

> Nas configurações ficam tema claro, escuro e alto contraste, tamanho do texto, notificação de mudança de faixa, reduzir animações, modo de leitura simples e apagar meus dados.
>
> Aqui o gestor define os limiares de alerta. Um valor inválido é recusado com uma mensagem clara. Com cinquenta e cinco por cento, os alertas são recalculados na hora, e aparece um novo: previsão de cinquenta e quatro e meio por cento, com sessenta e cinco por cento de chance de ficar abaixo do limiar, e os fatores do modelo.

## 13. Acessibilidade (7:15 · 15 s)

**Fazer:** ligar alto contraste e texto em 200 %; percorrer Visão geral e Alertas.

> Em alto contraste e com o texto em duzentos por cento, nenhuma tela quebra. Isso é testado em tela de trezentos e sessenta pixels.

## 14. Encerramento (7:30 · 25 s)

**Voltar para:** Visão geral.

> Resumindo: dados reais do Cantareira, um modelo que erra menos que o ingênuo, alertas que mostram evidência, confiança e limitação, e uma decisão que continua sendo humana. Os limites também estão claros: um único sistema, previsão de sete dias, envio de ocorrências simulado e registros por região sintéticos. O código, o APK e a documentação estão no repositório. Obrigado.

---

## Corte de 3 minutos (para o vídeo)

O vídeo `PULSO-demo.mp4` já segue este mesmo caminho em 2:41. Use `docs/NARRACAO.md` como fala, com estas equivalências:

| Vídeo | Bloco deste roteiro |
|---|---|
| Abertura, Consentimento | 1, 2 |
| Visão geral | 3 |
| Água, Clima, Risco | 4, 5, 6 |
| Detalhe do indicador | 7 |
| Justificativa do alerta | 9 |
| Mapa | 8 |
| Registro | 10 e 11 |
| Limiares, novo alerta | 12 |
| Acessibilidade, Encerramento | 13, 14 |

## Dicas

- Se alguém perguntar "isso é real?": o volume, a chuva e o modelo são reais; o mapa e a previsão do tempo são serviços externos reais; os registros por região e o envio são simulados, e a tela diz isso.
- Se perguntarem "o app decide?": não. Ele mostra a justificativa e uma pessoa encaminha.
- Se algo falhar ao vivo, ligue "Simular sem internet": é o plano B e ainda mostra um recurso.
