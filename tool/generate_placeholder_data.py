"""Gera assets/data/pulso_data.json com série SINTÉTICA (placeholder).

Substituir pela saída do pipeline do projeto DSA (série real Sabesp/ANA + previsão Ridge),
mantendo o mesmo esquema. O app exibe "DADOS SINTÉTICOS" enquanto origin == "synthetic".
"""
import json
import math
import random
import sys
from datetime import date, timedelta

random.seed(2026)
END = date(2026, 11, 9)
DAYS = 365

series = []
for i in range(DAYS):
    d = END - timedelta(days=DAYS - 1 - i)
    # Ciclo anual: pico em abril, mínimo em novembro; tendência leve de queda.
    phase = 2 * math.pi * (d.timetuple().tm_yday - 105) / 365
    vol = 36 + 9 * math.cos(phase) - 0.004 * i + random.gauss(0, 0.15)
    wet = d.month in (11, 12, 1, 2, 3)
    rain = max(0.0, random.gauss(6 if wet else 1, 7 if wet else 2)) if random.random() < (0.5 if wet else 0.15) else 0.0
    series.append({"date": d.isoformat(), "volume": round(vol, 2), "rain": round(rain, 1)})

regions = [
    # id, nome, sigla, coluna, linha (cartograma hexagonal), última semana, semana anterior
    ("mai", "Mairiporã", "MAI", 2, 0, 6, 5), ("gru", "Guarulhos", "GRU", 3, 0, 7, 4),
    ("fro", "Franco da Rocha", "FRO", 1, 1, 5, 4), ("zn", "Zona Norte", "ZN", 2, 1, 8, 6),
    ("zl1", "Zona Leste 1", "ZL1", 3, 1, 4, 4), ("mog", "Mogi das Cruzes", "MOG", 4, 1, 1, 2),
    ("osa", "Osasco", "OSA", 0, 2, 3, 3), ("zo", "Zona Oeste", "ZO", 1, 2, 2, 2),
    ("cen", "Centro", "CEN", 2, 2, 3, 1), ("zl2", "Zona Leste 2", "ZL2", 3, 2, 9, 4),
    ("emb", "Embu", "EMB", 1, 3, 3, 3), ("zs1", "Zona Sul 1", "ZS1", 2, 3, 1, 1),
    ("abc", "ABC", "ABC", 3, 3, 4, 3), ("zs2", "Zona Sul 2", "ZS2", 2, 4, 1, 2),
]

payload = {
    "schemaVersion": 1,
    "generatedAt": END.isoformat() + "T12:00:00-03:00",
    "reservoir": {
        "name": "Sistema Cantareira",
        "origin": "synthetic",
        "source": "Série sintética de demonstração (substituir pelo pipeline DSA)",
        "series": series,
        "forecast": None,
        "factors": [],
        "metrics": None,
    },
    "regions": [
        {"id": a, "name": b, "short": c, "col": e, "row": f, "lastWeek": g, "previousWeek": h,
         "population10k": round(random.uniform(20, 120), 1), "origin": "synthetic"}
        for a, b, c, e, f, g, h in regions
    ],
}

out = sys.argv[1] if len(sys.argv) > 1 else "assets/data/pulso_data.json"
with open(out, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, separators=(",", ":"))
print(out, series[0], series[-1])
