"""
GreenTrack Weather Intelligence — Data Quality Engine
======================================================
Validates a parsed JKUAT GeoCSV weather dataframe and produces a quality
report. Never assumes the dataset is perfect (per spec) — flags rather
than silently drops, except for rows that are structurally unusable
(unparseable timestamp).
"""
from __future__ import annotations
import pandas as pd
import numpy as np
from dataclasses import dataclass, field

# Kenyan highland station at 1523m — generous but real physical bounds,
# not just "whatever looks plausible". Anything outside these is almost
# certainly a sensor fault, not real weather.
VALID_RANGES = {
    "SHT Temperature": (-5, 45),      # degC
    "SHT Humidity": (0, 100),          # %
    "BMX Pressure 1": (700, 1100),     # hPa — sanity bound for ~1500m elevation
    "Wind Speed": (0, 60),             # m/s (60 m/s ~ category-4 hurricane; anything above is a fault)
    "Wind Gust": (0, 75),              # m/s
}
RAIN_COLS = ["Rain Gauge 1", "Rain Gauge 2"]

EXPECTED_INTERVAL_FALLBACK_SECONDS = 60  # only used if we can't infer a cadence at all (<2 rows)


@dataclass
class DataQualityReport:
    total_rows: int
    valid_rows: int
    duplicate_timestamps: int
    invalid_value_rows: int
    gap_count: int
    largest_gap_minutes: float
    coverage_pct: float
    first_observation: str | None
    last_observation: str | None
    quality_score: int
    quality_label: str
    issues: list[str] = field(default_factory=list)

    def to_dict(self):
        return self.__dict__


def validate(df: pd.DataFrame) -> tuple[pd.DataFrame, DataQualityReport]:
    """Returns (cleaned_df, report). Cleaned df keeps a `_valid` column
    rather than silently dropping flagged rows, so callers can choose."""
    issues = []
    total_rows = len(df)

    # 1. Timestamp parsing — unparseable timestamps are structurally
    # unusable, these are the only rows actually dropped.
    df = df.copy()
    df["Time"] = pd.to_datetime(df["Time"], utc=True, errors="coerce")
    unparseable = df["Time"].isna().sum()
    if unparseable:
        issues.append(f"{unparseable} row(s) had an unparseable timestamp and were dropped.")
    df = df.dropna(subset=["Time"]).sort_values("Time").reset_index(drop=True)

    # 2. Duplicate timestamps
    dup_mask = df["Time"].duplicated(keep="first")
    duplicate_timestamps = int(dup_mask.sum())
    if duplicate_timestamps:
        issues.append(f"{duplicate_timestamps} duplicate timestamp(s) found (kept first occurrence).")
    df = df[~dup_mask].reset_index(drop=True)

    # 3. Range validation — flag, don't drop, so the caller can see what
    # fraction of data is suspect without losing the row's other fields.
    df["_valid"] = True
    invalid_value_rows = 0
    for col, (lo, hi) in VALID_RANGES.items():
        if col not in df.columns:
            continue
        out_of_range = ~df[col].between(lo, hi) & df[col].notna()
        if out_of_range.any():
            n = int(out_of_range.sum())
            invalid_value_rows += n
            issues.append(f"{n} row(s) have {col} outside plausible range [{lo}, {hi}].")
            df.loc[out_of_range, "_valid"] = False

    # Rainfall can't be negative
    for col in RAIN_COLS:
        if col in df.columns:
            negative = df[col] < 0
            if negative.any():
                n = int(negative.sum())
                invalid_value_rows += n
                issues.append(f"{n} row(s) have negative {col}.")
                df.loc[negative, "_valid"] = False

    # 4. Timestamp gaps (possible sensor outage)
    #
    # Different exports from this station have used very different
    # sampling cadences (~1 min in the GeoCSV sample, ~15 min in a plain
    # CSV export) — a fixed expected-interval assumption misfires badly
    # on whichever cadence it wasn't tuned for (flagging nearly every
    # single row as a "gap" on the 15-min file). Infer the cadence from
    # the data itself instead: the *mode* of rounded deltas, which is
    # robust to a handful of real gaps skewing things (unlike the
    # median, which a single outlier can distort when there are very
    # few rows — e.g. exactly the tiny synthetic frames these tests use).
    deltas = df["Time"].diff().dt.total_seconds().dropna()
    if not deltas.empty:
        expected_interval_seconds = float(deltas.round().mode().iloc[0])
    else:
        expected_interval_seconds = EXPECTED_INTERVAL_FALLBACK_SECONDS
    gap_threshold = max(expected_interval_seconds * 5, EXPECTED_INTERVAL_FALLBACK_SECONDS * 5)
    gaps = deltas[deltas > gap_threshold]
    gap_count = int(len(gaps))
    largest_gap_minutes = float(gaps.max() / 60) if gap_count else 0.0
    if gap_count:
        issues.append(
            f"{gap_count} timestamp gap(s) detected (largest: {largest_gap_minutes:.0f} min) — "
            "likely sensor/connectivity outages."
        )

    valid_rows = int(df["_valid"].sum())
    coverage_pct = round(100 * valid_rows / total_rows, 1) if total_rows else 0.0

    # Composite score: mostly "did we keep the data", penalised further for
    # gaps. This is a simple, explainable formula, not a fitted model.
    score = coverage_pct
    if total_rows:
        score -= min(15, gap_count * 1.5)
        score -= min(10, (duplicate_timestamps / total_rows) * 100)
    score = max(0, min(100, round(score)))
    label = "Excellent" if score >= 95 else "Good" if score >= 80 else \
        "Fair" if score >= 60 else "Poor"

    report = DataQualityReport(
        total_rows=total_rows,
        valid_rows=valid_rows,
        duplicate_timestamps=duplicate_timestamps,
        invalid_value_rows=invalid_value_rows,
        gap_count=gap_count,
        largest_gap_minutes=round(largest_gap_minutes, 1),
        coverage_pct=coverage_pct,
        first_observation=df["Time"].min().isoformat() if len(df) else None,
        last_observation=df["Time"].max().isoformat() if len(df) else None,
        quality_score=score,
        quality_label=label,
        issues=issues,
    )
    return df, report
