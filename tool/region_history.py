"""Histórico semanal SINTÉTICO de registros por região (8 semanas, da mais antiga à mais recente).

Determinístico por região (semente = id), termina exatamente em (semana anterior, última semana)
para continuar coerente com os campos `previousWeek` e `lastWeek` do esquema v1.
"""
from __future__ import annotations

import random

WEEKS = 8


def weekly_history(region_id: str, previous_week: int, last_week: int) -> list[int]:
    rng = random.Random(f"pulso-{region_id}")
    # Caminha para trás a partir da semana anterior, com deriva leve em direção a um nível base.
    base = max(1.0, (previous_week + last_week) / 2 - rng.uniform(0.5, 2.5))
    values = [previous_week]
    for _ in range(WEEKS - 2):
        prev = values[0]
        nxt = prev + (base - prev) * 0.35 + rng.gauss(0, 1.0)
        values.insert(0, max(0, round(nxt)))
    return values + [last_week]
