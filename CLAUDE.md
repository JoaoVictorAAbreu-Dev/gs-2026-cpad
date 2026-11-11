# PULSO — notas para agentes

- Flutter app (GS 2026.2 · CPAD · FIAP). Design: Figma "PULSO — Radar Territorial" (fileKey RlLhOho9IEkuWJmTGAVYO6), página 05 · Handoff Flutter.
- Commits em nome de João Victor Alves de Abreu (config local do repositório). Conventional commits em inglês.
- Domínio puro em `lib/features/*/domain` (sem Flutter). Telas nunca usam hex: `context.pulso` e `Theme.of(context)`.
- Dados: `pulso_data.json` esquema v1. Placeholder sintético em `assets/data/` — não apresentar como real.

## Verificar

```bash
flutter analyze && flutter test
```

## Ver o app com mobile-mcp

Requer emulador Android aberto (ou aparelho com depuração USB) e `adb` no PATH.

```bash
claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest
flutter run -d emulator-5554
```

Fluxo de verificação: listar dispositivos → abrir o app → screenshot de cada aba → percorrer
consentimento, Visão geral, Indicadores (3 abas), Alertas → detalhe → encaminhar, Configurações → Limiares
(testar erro de validação) → repetir em tema escuro, alto contraste e texto 200%.
