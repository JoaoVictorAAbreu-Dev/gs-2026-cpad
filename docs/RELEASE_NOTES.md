# PULSO — Radar Territorial

APK de release do app da Global Solution 2026.2 (Cross-Platform Application Development, FIAP).

**Integrantes:** João Victor Alves de Abreu (RM 564946) e Rodrigo Kenshin Viana Matayoshi (RM 564026).

## Como instalar

1. Baixe o arquivo `PULSO-v1.0.1.apk` abaixo, no próprio celular Android (Android 7.0 ou superior).
2. Abra o arquivo e permita a instalação de fontes desconhecidas quando o Android pedir.
3. Abra o PULSO e aceite o consentimento.

O arquivo `.sha256` permite conferir a integridade do APK (`sha256sum -c PULSO-v1.0.1.apk.sha256`).

## O que está incluído

- Três dashboards (Água, Clima, Risco territorial) com histórico, tendência e unidades.
- Alertas com evidência, confiança, janela temporal, limitações e aviso de decisão humana.
- Detalhe do indicador, mapa OpenStreetMap, registro de ocorrências com fila offline e limiares de alerta.
- Dados reais do Sistema Cantareira (Sabesp) embutidos até 07/11/2026; ocorrências por região sintéticas e etiquetadas.

## Novidades da v1.0.1

- Alertas de previsão com data já vencida passam a "apenas informativo"; alertas são reavaliados ao voltar para o app.
- Modo de leitura simples funcionando: explicação "Em palavras simples" em cada alerta.
- Formulário de ocorrência e fila offline mais robustos (envio automático ao religar, sem duplicar).
- Puxar para atualizar não apaga os dados da tela se a atualização falhar.
- Botão "Copiar protocolo" na confirmação e em Meus registros.

O vídeo de demonstração foi gravado numa versão anterior; as diferenças estão no README, seção 10.1.

## Observações

- Projeto acadêmico. O APK é assinado com a chave de depuração gerada na compilação: para instalar uma versão nova, desinstale a anterior.
- Gerado automaticamente pelo workflow `.github/workflows/release-apk.yml`, que roda `flutter analyze` e `flutter test` antes de compilar.
