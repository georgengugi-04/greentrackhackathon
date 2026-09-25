"""
GreenTrack Weather Intelligence — Ingestion Entry Point
=========================================================
Usage:
    python ingest.py path/to/full_jkuat_dataset.csv --out ./output

Reads the GeoCSV 2.0 file (skips the metadata header lines above the
actual column header row), validates it, computes aggregates and
rolling-window features, runs the crop risk engine for every configured
crop, and writes everything Firestore needs as JSON files under --out.

This project has no backend server (Flutter talks to Firestore
directly), so this script is meant to be run **offline, once** (or on a
schedule via cron/GitHub Actions) rather than as a live API — see
upload_to_firestore.py for actually pushing the output into Firestore.

NOTE on rainfall columns: feature_engineering.detect_rainfall_mode() now
auto-classifies a rain column as a per-reading tip increment vs. a
cumulative signal (a running counter, or an accumulator that also drains
down within the day — confirmed present in a real JKUAT short-column-name
export where "rg2tt" climbs over several hours then decays back down,
which is NOT a simple midnight-reset counter), and
hourly_aggregates()/rolling_window_features() switch their calculation
accordingly (sum vs. sum-of-positive-deltas). Every GeoCSV sample
available while building this had too few non-zero rain readings on
"Rain Gauge 1" specifically to classify with confidence — check
current_features.json's `rainfall_mode`/`rainfall_mode_verified` fields
per station/column before trusting the rainfall numbers, and see
load_any_format() below for picking the actual best rain column per file.
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path
import pandas as pd

from data_quality import validate
from feature_engineering import hourly_aggregates, daily_summary, rolling_window_features, COL_RAIN1
from risk_engine import CROP_PROFILES, assess_crop_risk, spray_window_status, irrigation_need

STATION_META = {
    "station_id": "61",
    "name": "Kenya Kiambu JKUAT IoT AWS",
    "site": "JKUAT",
    "latitude": -1.099736,
    "longitude": 37.014528,
    "elevation_m": 1523.0,
    "attribution": "3d-fewsnet.icdp.ucar.edu",
    "doi": "https://doi.org/10.5065/d6v1236q",
}

# Some exports use the verbose GeoCSV 2.0 column names directly (see
# find_header_row below); others — like a plain CSV pull from the same
# station — use short snake_case names instead. Map the short names to
# the verbose ones so the rest of the pipeline (which is written against
# COL_TEMP/COL_HUMIDITY/etc. in feature_engineering.py) doesn't care
# which format it was given.
SHORT_TO_VERBOSE_COLUMNS = {
    "ts": "Time",
    "rg1": "Rain Gauge 1",
    "rg2": "Rain Gauge 2",
    "rg1tt": "Rain Gauge 1 Total Today",
    "rg2tt": "Rain Gauge 2 Total Today",
    "rg1tp": "Rain Gauge 1 Total Prior",
    "rg2tp": "Rain Gauge 2 Total Prior",
    "temp_bmx": "BMX Temperature 1",
    "press_bmx": "BMX Pressure 1",
    "temp_mcp": "MCP Temperature 1",
    "temp_sht": "SHT Temperature",
    "humidity_sht": "SHT Humidity",
    "si1145_vis": "SI1145 Visible 1",
    "si1145_ir": "SI1145 Infrared 1",
    "si1145_uv": "SI1145 Ultraviolet 1",
    "wind_spd": "Wind Speed",
    "wind_dir": "Wind Direction",
    "wind_gust": "Wind Gust",
    "wind_gust_dir": "Wind Gust Direction",
    "heat_idx": "Heat Index",
    "wet_bulb_temp": "Wet Bulb Temperature",
    "wet_bulb_globe_temp": "Wet Bulb Globe Temperature",
}

# Rain columns to consider, in priority order, when picking which one
# actually carries signal for this export (see _pick_rain_column below).
# Both raw per-tip gauges have been entirely zero in every real export
# seen so far, while the "Total Today" running/accumulating columns
# carry the actual rain signal — so those are checked too, not assumed
# unusable just because they're not the nominal "Rain Gauge 1" column.
RAIN_COLUMN_CANDIDATES = [
    "Rain Gauge 1",
    "Rain Gauge 2",
    "Rain Gauge 1 Total Today",
    "Rain Gauge 2 Total Today",
]


def find_header_row(path: str) -> int:
    """GeoCSV 2.0 files have free-text metadata lines before the actual
    column header — find the row that starts with 'Time,' rather than
    assuming a fixed line count. Plain short-column-name CSVs (header
    starts with 'ts,') have no such preamble, so this returns 0 for
    those without raising."""
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for i, line in enumerate(f):
            if line.startswith("Time,") or line.startswith("ts,"):
                return i
    raise ValueError("Could not find a 'Time,...' or 'ts,...' header row in this file — "
                      "is this really a JKUAT/JHUB station export?")


def _pick_rain_column(df: pd.DataFrame) -> str | None:
    """Of the known rain-related columns present, return whichever one
    actually has non-zero readings — defaults to "Rain Gauge 1" if none
    of them do (nothing to prefer instead), or None if none exist at
    all in this file."""
    present = [c for c in RAIN_COLUMN_CANDIDATES if c in df.columns]
    if not present:
        return None
    with_signal = [c for c in present if (df[c].fillna(0) != 0).any()]
    return with_signal[0] if with_signal else present[0]


def load(path: str) -> pd.DataFrame:
    header_row = find_header_row(path)
    df = pd.read_csv(path, skiprows=header_row, low_memory=False)

    if "Time" not in df.columns and "ts" in df.columns:
        df = df.rename(columns=SHORT_TO_VERBOSE_COLUMNS)

    numeric_cols = [c for c in df.columns if c != "Time"]
    for c in numeric_cols:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    # Point COL_RAIN1 ("Rain Gauge 1") at whichever rain column in this
    # file actually has signal, so the rest of the pipeline — written
    # against that one constant — doesn't need per-format branching.
    # Only rewrites the column when a *different* one has the real data;
    # leaves "Rain Gauge 1" alone otherwise (including when it's already
    # the best/only option).
    best_rain_col = _pick_rain_column(df)
    if best_rain_col and best_rain_col != COL_RAIN1:
        df[COL_RAIN1] = df[best_rain_col]

    return df


def run(csv_path: str, out_dir: str):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)

    print(f"Loading {csv_path} ...")
    raw = load(csv_path)
    print(f"  {len(raw)} rows loaded")

    print("Validating ...")
    cleaned, report = validate(raw)
    print(f"  Quality score: {report.quality_score} ({report.quality_label})")
    for issue in report.issues:
        print(f"  - {issue}")

    print("Computing hourly aggregates ...")
    hourly = hourly_aggregates(cleaned)
    print(f"  {len(hourly)} hourly records")

    print("Computing daily summary ...")
    daily = daily_summary(hourly)
    print(f"  {len(daily)} daily records")

    now = cleaned["Time"].max()
    print(f"Computing rolling-window features as of {now} ...")
    features = rolling_window_features(cleaned, now)
    mode_note = "" if features.get("rainfall_mode_verified") else " (unverified — see NOTE above)"
    print(f"  Rainfall column mode: {features.get('rainfall_mode', 'unknown')}{mode_note}")

    print("Running crop risk engine for all configured crops ...")
    crop_risks = {}
    for crop_key in CROP_PROFILES:
        risk = assess_crop_risk(crop_key, features)
        crop_risks[crop_key] = {
            **risk.to_dict(),
            "spray_window": spray_window_status(features, crop_key),
            "irrigation": irrigation_need(crop_key, features),
        }

    # ── write output ──────────────────────────────────────────────────
    (out / "station_meta.json").write_text(json.dumps(STATION_META, indent=2))
    (out / "data_quality.json").write_text(json.dumps(report.to_dict(), indent=2))
    (out / "current_features.json").write_text(json.dumps(features, indent=2, default=str))
    (out / "crop_risks.json").write_text(json.dumps(crop_risks, indent=2, default=str))
    hourly.to_json(out / "hourly_aggregates.json", orient="records", date_format="iso", indent=2)
    daily.to_json(out / "daily_summary.json", orient="records", date_format="iso", indent=2)

    print(f"\nDone. Output written to {out.resolve()}")
    print("Files: station_meta.json, data_quality.json, current_features.json, "
          "crop_risks.json, hourly_aggregates.json, daily_summary.json")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", help="Path to the full JKUAT GeoCSV export")
    parser.add_argument("--out", default="./output", help="Output directory for JSON files")
    args = parser.parse_args()
    run(args.csv_path, args.out)
