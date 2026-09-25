"""
GreenTrack Weather Intelligence — Feature Engineering
======================================================
Turns validated raw observations into the aggregated features the risk
engine and dashboard actually need. Never ships raw per-minute rows
onward — everything here produces hourly/daily summaries.
"""
from __future__ import annotations
import pandas as pd
import numpy as np

COL_TEMP = "SHT Temperature"
COL_HUMIDITY = "SHT Humidity"
COL_WIND = "Wind Speed"
COL_GUST = "Wind Gust"
COL_GUST_DIR = "Wind Gust Direction"
COL_WIND_DIR = "Wind Direction"
COL_HEAT_INDEX = "Heat Index"
COL_WBT = "Wet Bulb Temperature"
COL_WBGT = "Wet Bulb Globe Temperature"
COL_RAIN1 = "Rain Gauge 1"
COL_RAIN2 = "Rain Gauge 2"

HIGH_HUMIDITY_THRESHOLD = 80.0  # % — above this counts toward "persistent humidity"


def _valid(df: pd.DataFrame) -> pd.DataFrame:
    if "_valid" not in df.columns:
        return df
    # Explicit bool cast: an empty (or all-NaN) "_valid" column can be
    # inferred as float64 rather than bool, and masking a DataFrame with
    # a non-bool empty Series silently drops every *column* (not just
    # rows) rather than raising — a genuinely dangerous silent-data-loss
    # failure mode, caught by test_rolling_window_features_empty_frame_
    # returns_empty_dict. Always coerce before using it as a mask.
    return df[df["_valid"].astype(bool)]


def detect_rainfall_mode(df: pd.DataFrame, col: str = COL_RAIN1) -> str:
    """Classifies whether `col` behaves like a per-reading tip increment
    (sum raw values directly) or a cumulative/accumulating signal — a
    running counter, or an accumulator that also drains down over time
    (e.g. via evaporation) rather than only resetting sharply at
    midnight (real JKUAT export data confirmed this second shape exists:
    "rg2tt" climbs over several hours then decays back toward zero
    within the same day, which a simple "non-decreasing all day" check
    misclassifies as "increment" and then badly overcounts by summing
    raw depth readings). Returns "increment", "cumulative", or "unknown"
    (too little non-zero data in this file to tell — callers should
    treat "unknown" as unverified and keep the increment/sum default,
    not silently trust it).

    Heuristic: look at run lengths of consecutive non-zero readings. An
    increment column is mostly zero with isolated single-reading
    "tips" — short runs. A cumulative column (whether a clean counter or
    a rise-then-decay accumulator) stays non-zero across many
    consecutive readings while a rain event plays out — long runs. We
    classify by the average run length rather than requiring the whole
    run to be monotonic, since real accumulator data isn't always purely
    non-decreasing (see above).
    """
    v = _valid(df)
    if col not in v.columns or v[col].dropna().empty:
        return "unknown"

    nonzero = v[v[col].fillna(0) > 0]
    if len(nonzero) < 5:
        return "unknown"  # not enough rain events in this sample to classify

    vals = v.sort_values("Time")[col].fillna(0).to_numpy()
    is_nonzero = vals > 0
    run_lengths: list[int] = []
    current = 0
    for flag in is_nonzero:
        if flag:
            current += 1
        elif current:
            run_lengths.append(current)
            current = 0
    if current:
        run_lengths.append(current)
    if not run_lengths:
        return "unknown"

    avg_run = sum(run_lengths) / len(run_lengths)
    return "cumulative" if avg_run > 2.0 else "increment"


def _rain_amount(series: pd.Series, mode: str) -> float:
    """Rainfall total for one window, respecting the detected column
    semantics: plain sum for per-reading increments; sum of positive
    deltas for a cumulative signal (correctly handles both a clean
    running counter and a rise-then-decay accumulator, since it only
    counts genuine increases and ignores drainage/reset decreases —
    unlike a naive max-min, which a mid-window reset or decay would
    throw off)."""
    if series.empty:
        return 0.0
    if mode == "cumulative":
        diffs = series.to_numpy()
        deltas = diffs[1:] - diffs[:-1]
        positive = deltas[deltas > 0]
        return round(float(positive.sum()), 4) if len(positive) else 0.0
    return float(series.sum())


def hourly_aggregates(df: pd.DataFrame, rainfall_mode: str | None = None) -> pd.DataFrame:
    """One row per hour: avg/min/max temp, avg humidity, rain total, wind avg/max.

    `rainfall_mode` is normally left as None to auto-detect via
    detect_rainfall_mode(); pass "increment" or "cumulative" explicitly once
    the full dataset has confirmed which one this station actually sends
    (see that function's docstring).
    """
    mode = rainfall_mode or detect_rainfall_mode(df)
    v = _valid(df).set_index("Time")

    agg = v.resample("1h").agg(**{
        "temp_avg": (COL_TEMP, "mean"),
        "temp_min": (COL_TEMP, "min"),
        "temp_max": (COL_TEMP, "max"),
        "humidity_avg": (COL_HUMIDITY, "mean"),
        "humidity_max": (COL_HUMIDITY, "max"),
        "wind_avg": (COL_WIND, "mean"),
        "wind_max_gust": (COL_GUST, "max"),
        "heat_index_max": (COL_HEAT_INDEX, "max"),
        "wet_bulb_max": (COL_WBT, "max"),
        "wbgt_max": (COL_WBGT, "max"),
        "observation_count": (COL_TEMP, "count"),
    })
    agg = agg.dropna(subset=["observation_count"])
    agg["observation_count"] = agg["observation_count"].astype(int)

    rain_hourly = v[COL_RAIN1].resample("1h").apply(lambda s: _rain_amount(s, mode))
    agg["rainfall_mm"] = rain_hourly.reindex(agg.index).fillna(0.0)
    agg.attrs["rainfall_mode"] = mode
    return agg.reset_index()


def daily_summary(hourly: pd.DataFrame) -> pd.DataFrame:
    h = hourly.set_index("Time")
    agg = h.resample("1D").agg(**{
        "temp_avg": ("temp_avg", "mean"),
        "temp_min": ("temp_min", "min"),
        "temp_max": ("temp_max", "max"),
        "humidity_avg": ("humidity_avg", "mean"),
        "rainfall_mm": ("rainfall_mm", "sum"),
        "wind_avg": ("wind_avg", "mean"),
        "wind_max_gust": ("wind_max_gust", "max"),
    })
    return agg.dropna(how="all").reset_index()


def rolling_window_features(df: pd.DataFrame, now: pd.Timestamp) -> dict:
    """The specific numbers the risk engine and dashboard card need,
    computed as of `now` from the raw valid observations — 1h/3h/6h/24h
    temp averages, rainfall over several windows, humidity persistence,
    dry-period duration. This is the "feature engineering" layer the
    hackathon brief asks for, kept as a flat dict of primitives so it
    serializes straight to a Firestore doc.
    """
    v = _valid(df)
    v = v[v["Time"] <= now]
    if v.empty:
        return {}

    rainfall_mode = detect_rainfall_mode(df)

    def window(hours):
        return v[v["Time"] >= now - pd.Timedelta(hours=hours)]

    latest = v.iloc[-1]

    def avg(w, col):
        return round(float(w[col].mean()), 2) if len(w) and col in w else None

    def rain_sum(w):
        return round(_rain_amount(w[COL_RAIN1], rainfall_mode), 2) if len(w) else 0.0

    w1, w3, w6, w24, w7d = (window(1), window(3), window(6), window(24), window(24 * 7))

    # Persistent high-humidity duration: longest unbroken run of
    # observations >= threshold within the last 24h, in minutes.
    w24_sorted = w24.sort_values("Time")
    above = (w24_sorted[COL_HUMIDITY] >= HIGH_HUMIDITY_THRESHOLD).astype(int)
    persistent_minutes = 0
    if len(w24_sorted) > 1:
        run = 0
        max_run_rows = 0
        for val in above:
            run = run + 1 if val else 0
            max_run_rows = max(max_run_rows, run)
        # approximate minutes/row from median spacing
        spacing_min = w24_sorted["Time"].diff().dt.total_seconds().median() / 60
        persistent_minutes = round(max_run_rows * (spacing_min or 1))

    # Dry-period duration: hours since rainfall was last > 0.
    rained = v[v[COL_RAIN1] > 0]
    if len(rained):
        dry_hours = round((now - rained["Time"].max()).total_seconds() / 3600, 1)
    else:
        dry_hours = round((now - v["Time"].min()).total_seconds() / 3600, 1)

    return {
        "observed_at": latest["Time"].isoformat(),
        "temp_current": round(float(latest[COL_TEMP]), 1),
        "temp_avg_1h": avg(w1, COL_TEMP),
        "temp_avg_3h": avg(w3, COL_TEMP),
        "temp_avg_6h": avg(w6, COL_TEMP),
        "temp_avg_24h": avg(w24, COL_TEMP),
        "temp_max_24h": round(float(w24[COL_TEMP].max()), 1) if len(w24) else None,
        "temp_min_24h": round(float(w24[COL_TEMP].min()), 1) if len(w24) else None,
        "humidity_current": round(float(latest[COL_HUMIDITY]), 1),
        "humidity_avg_24h": avg(w24, COL_HUMIDITY),
        "humidity_persistent_high_minutes_24h": persistent_minutes,
        "rainfall_mm_6h": rain_sum(w6),
        "rainfall_mm_24h": rain_sum(w24),
        "rainfall_mm_7d": rain_sum(w7d),
        "dry_period_hours": dry_hours,
        "wind_current": round(float(latest[COL_WIND]), 2),
        "wind_avg_24h": avg(w24, COL_WIND),
        "wind_gust_max_24h": round(float(w24[COL_GUST].max()), 2) if len(w24) else None,
        "wind_direction_deg": float(latest[COL_WIND_DIR]) if pd.notna(latest.get(COL_WIND_DIR)) else None,
        "heat_index_current": round(float(latest[COL_HEAT_INDEX]), 1) if pd.notna(latest.get(COL_HEAT_INDEX)) else None,
        "wet_bulb_current": round(float(latest[COL_WBT]), 1) if pd.notna(latest.get(COL_WBT)) else None,
        "wbgt_current": round(float(latest[COL_WBGT]), 1) if pd.notna(latest.get(COL_WBGT)) else None,
        "rainfall_mode": rainfall_mode,
        "rainfall_mode_verified": rainfall_mode != "unknown",
    }
