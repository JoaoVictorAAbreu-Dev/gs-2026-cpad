"""Gera assets/data/pulso_data.json (esquema v1) com a série REAL do Sistema Cantareira.

Fonte: Sabesp — Portal dos Mananciais, extraída e validada no projeto de Data Science da GS
(repositório gs-2026-dsa, `data/cantareira_diario_2024_2026.csv`, SHA-256 abaixo).

Previsão de 7 dias: mesmo modelo do projeto DSA — Ridge (α = 100, atributos padronizados) sobre a
VARIAÇÃO do volume em 7 dias, com os atributos F_RIDGE. Treina com todos os exemplos rotulados e
prevê a partir do último dia. O erro típico (sigma) é o RMSE da validação walk-forward do DSA,
não o erro de treino.

As regiões do mapa continuam SINTÉTICAS (não há dado público de ocorrências por região) e são
geradas por generate_placeholder_data.py com origin = "synthetic".

Uso: python3 tool/build_pulso_data.py
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tool" / "source" / "cantareira_diario_2024_2026.csv"
OUT = ROOT / "assets" / "data" / "pulso_data.json"
EXPECTED_SHA256 = "26e757200fd89261a807db1afe79ce50a1c6bc893970ac20697eb800e93c600a"

HORIZON = 7
F_RIDGE = ["storage_pct", "trend_7d", "trend_30d", "rain_30d", "balance_30d", "doy_sin", "doy_cos"]
LABELS = {
    "storage_pct": "Nível atual",
    "trend_7d": "Tendência dos últimos 7 dias",
    "trend_30d": "Tendência dos últimos 30 dias",
    "rain_30d": "Chuva acumulada em 30 dias",
    "balance_30d": "Afluência menos produção (30 dias)",
    "doy_sin": "Época do ano",
    "doy_cos": "Época do ano",
}

# Métricas de teste do DSA (reports/results.json, walk-forward jan/2025–set/2026, n = 638).
RMSE_RIDGE_7D = 1.248
MAE_RIDGE_7D = 0.767
MAE_PERSISTENCE_7D = 1.097
TEST_PERIOD = "walk-forward jan/2025–set/2026, 638 previsões"


def load() -> pd.DataFrame:
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    if digest != EXPECTED_SHA256:
        raise SystemExit(f"SHA-256 inesperado para {SOURCE.name}: {digest}")
    frame = pd.read_csv(SOURCE, parse_dates=["date"]).sort_values("date").reset_index(drop=True)
    if (frame["date"].diff().dropna().dt.days != 1).any():
        raise SystemExit("Série com lacunas")
    return frame


def add_features(frame: pd.DataFrame) -> pd.DataFrame:
    d = frame.copy()
    vol = d["storage_pct"]
    d["trend_7d"] = vol - vol.shift(7)
    d["trend_30d"] = vol - vol.shift(30)
    d["rain_30d"] = d["rain_mm"].rolling(30).sum()
    inflow_30d = d["natural_inflow_m3s"].rolling(30).mean()
    produced_30d = d["produced_flow_m3s"].rolling(30).mean()
    d["balance_30d"] = inflow_30d - produced_30d
    doy = d["date"].dt.dayofyear
    d["doy_sin"] = np.sin(2 * np.pi * doy / 365.25)
    d["doy_cos"] = np.cos(2 * np.pi * doy / 365.25)
    d["target_delta"] = vol.shift(-HORIZON) - vol
    return d


def forecast(d: pd.DataFrame) -> tuple[dict, list[dict]]:
    train = d.dropna(subset=F_RIDGE + ["target_delta"])
    model = make_pipeline(StandardScaler(), Ridge(alpha=100))
    model.fit(train[F_RIDGE], train["target_delta"])

    last = d.dropna(subset=F_RIDGE).iloc[-1]
    x = last[F_RIDGE].to_frame().T.astype(float)
    delta = float(model.predict(x)[0])

    # Decomposição exata da previsão linear: intercepto + Σ coef · x_padronizado.
    scaler, ridge = model.named_steps["standardscaler"], model.named_steps["ridge"]
    z = (x.values[0] - scaler.mean_) / scaler.scale_
    parts: dict[str, float] = {}
    for name, coef, zi in zip(F_RIDGE, ridge.coef_, z):
        parts[LABELS[name]] = parts.get(LABELS[name], 0.0) + float(coef * zi)
    factors = [{"label": "Variação média aprendida (7 dias)", "contribution": round(float(ridge.intercept_), 3)}]
    factors += [
        {"label": label, "contribution": round(v, 3)}
        for label, v in sorted(parts.items(), key=lambda kv: -abs(kv[1]))
        if abs(v) >= 0.005
    ]
    assert abs(sum(f["contribution"] for f in factors) - delta) < 0.05

    target_date = (last["date"] + pd.Timedelta(days=HORIZON)).date().isoformat()
    return (
        {
            "date": target_date,
            "value": round(float(last["storage_pct"]) + delta, 2),
            "sigma": RMSE_RIDGE_7D,
            "method": "Ridge (projeto DSA)",
        },
        factors,
    )


def main() -> None:
    frame = load()
    d = add_features(frame)
    fc, factors = forecast(d)

    # Mantém as regiões sintéticas já presentes no asset (ou gera, se não houver).
    regions = []
    if OUT.exists():
        regions = json.loads(OUT.read_text(encoding="utf-8")).get("regions", [])
    if not regions:
        raise SystemExit("Rode antes tool/generate_placeholder_data.py para gerar as regiões sintéticas")

    last_date = frame["date"].iloc[-1].date()
    payload = {
        "schemaVersion": 1,
        "generatedAt": f"{last_date.isoformat()}T12:00:00-03:00",
        "reservoir": {
            "name": "Sistema Cantareira",
            "origin": "real",
            "source": f"Sabesp, Portal dos Mananciais (série até {last_date:%d/%m/%Y}, via projeto DSA)",
            "series": [
                {"date": r.date.date().isoformat(), "volume": round(r.storage_pct, 2), "rain": round(r.rain_mm, 1)}
                for r in frame.itertuples()
            ],
            "forecast": fc,
            "factors": factors,
            "metrics": {"maeModel": MAE_RIDGE_7D, "maeBaseline": MAE_PERSISTENCE_7D, "testPeriod": TEST_PERIOD},
        },
        "regions": regions,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(frame)} dias até {last_date}, último {frame['storage_pct'].iloc[-1]:.2f}%")
    print("previsão", fc)
    for f in factors:
        print(f"  {f['contribution']:+.3f}  {f['label']}")


if __name__ == "__main__":
    main()
