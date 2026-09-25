"""
GreenTrack Weather Intelligence — Canonical Schema Normalization
==================================================================
Three different shapes of weather data have shown up for this project:

1. The original JKUAT GeoCSV 2.0 export (full_jkuat.csv / sample_jkuat.csv)
   — long-form column names: "Time", "SHT Temperature", "SHT Humidity",
   "BMX Pressure 1", "Wind Speed", "Wind Gust", "Rain Gauge 1", ...

2. The newer short-form CSV export (weatherdata.csv) — short field codes:
   "ts", "temp_sht", "humidity_sht", "press_bmx", "wind_spd", "rg1tt",
   "rg2tt", ...

3. The live JHUB Conduit API (https://conduit.jhubafrica.com/data.php)
   — shape not yet confirmed against a real authenticated response, so
   conduit_client.py normalizes whatever JSON/CSV it gets back through
   this same module rather than assuming a fourth column-naming scheme.

Rather than teach data_quality.py / feature_engineering.py / risk_engine.py
about three input shapes, everything is normalized here into ONE canonical
internal frame — the column names already used throughout the existing,
tested pipeline (chosen as canonical specifically so the 36 existing tests
and the risk engine keep working unmodified):

    Time, SHT Temperature, SHT Humidity, BMX Pressure 1, Wind Speed,
    Wind Direction, Wind Gust, Wind Gust Direction, Heat Index,
    Wet Bulb Temperature, Wet Bulb Globe Temperature,
    Rain Gauge 1, Rain Gauge 2

RAINFALL SEMANTICS (see also README.md "Rainfall semantics")
--------------------------------------------------------------
In weatherdata.csv, rg1/rg2 are flat 0 for the whole file (inactive/unused
channels on this export) and rg1tp/rg2tp (the columns that looked like
"per-reading tip" values) are also ~always 0. The columns that actually
move are rg1tt and rg2tt — and they are NOT per-reading increments: they
climb through a rain event and reset back toward 0 when the event ends
(616 resets across ~2,939 rows; max ~4.4mm between resets, never a
day-long monotonic climb to a "daily total"). That is an **event-total
counter**, not a per-reading increment and not a simple daily cumulative
total.

To get a per-reading increment usable by hourly_aggregates()'s existing
`.sum()` approach, this module diffs the *tt column and clips negative
values (the resets) to 0, rather than summing the raw counter (which
would double count already-accumulated rainfall) or naively summing
tp (which is empty in this export). This was verified against
weatherdata.csv: summing rg2tp gives 0mm for the whole month, which is
implausible for a period with confirmed rain events, while the
diff-and-clip approach yields a plausible ~281mm over 31 days.
"""
from __future__ import annotations
import io
import pandas as pd

# Canonical column set the rest of the pipeline (data_quality,
# feature_engineering, risk_engine) already expects.
CANONICAL_COLUMNS = [
    "Time", "SHT Temperature", "SHT Humidity", "BMX Pressure 1",
    "Wind Speed", "Wind Direction", "Wind Gust", "Wind Gust Direction",
    "Heat Index", "Wet Bulb Temperature", "Wet Bulb Globe Temperature",
    "Rain Gauge 1", "Rain Gauge 2",
]

# short-form (weatherdata.csv / likely Conduit API) -> canonical, for the
# fields that map one-to-one with no derived logic needed.
SHORT_FORM_DIRECT_MAP = {
    "ts": "Time",
    "temp_sht": "SHT Temperature",
    "humidity_sht": "SHT Humidity",
    "press_bmx": "BMX Pressure 1",
    "wind_spd": "Wind Speed",
    "wind_dir": "Wind Direction",
    "wind_gust": "Wind Gust",
    "wind_gust_dir": "Wind Gust Direction",
    "heat_idx": "Heat Index",
    "wet_bulb_temp": "Wet Bulb Temperature",
    "wet_bulb_globe_temp": "Wet Bulb Globe Temperature",
}

# Alternate/likely aliases the live Conduit API might use instead of the
# exact weatherdata.csv header spelling (JSON keys are often looser than
# CSV headers). Checked case-insensitively, in addition to the exact map
# above, before a field is treated as unrecognized.
SHORT_FORM_ALIASES = {
    "timestamp": "Time",
    "time": "Time",
    "date_time": "Time",
    "datetime": "Time",
    "temperature": "SHT Temperature",
    "temp": "SHT Temperature",
    "humidity": "SHT Humidity",
    "pressure": "BMX Pressure 1",
    "wind_speed": "Wind Speed",
    "wind_direction": "Wind Direction",
    "windgust": "Wind Gust",
    "wind_gust_direction": "Wind Gust Direction",
    "heat_index": "Heat Index",
    "heatindex": "Heat Index",
    "wetbulbtemp": "Wet Bulb Temperature",
    "wetbulbglobetemp": "Wet Bulb Globe Temperature",
}

RAIN_EVENT_TOTAL_COLUMNS = {"Rain Gauge 1": "rg1tt", "Rain Gauge 2": "rg2tt"}


class SchemaError(ValueError):
    """Raised when a weather source cannot be mapped to the canonical schema."""


def _event_total_to_increment(series: pd.Series) -> pd.Series:
    """Convert a rain-gauge *event total* counter (climbs during an event,
    resets toward 0 when it ends) into a per-reading increment, per the
    rainfall-semantics note above. Negative diffs (resets) become 0."""
    diffs = series.diff()
    diffs = diffs.clip(lower=0)
    diffs.iloc[0] = 0.0
    return diffs.fillna(0.0)


def detect_format(columns: list[str]) -> str:
    cols = set(c.strip() for c in columns)
    if "Time" in cols and "SHT Temperature" in cols:
        return "geocsv_long_form"
    lower_cols = {c.strip().lower() for c in columns}
    if "ts" in lower_cols or ("temp_sht" in lower_cols):
        return "short_form"
    raise SchemaError(
        f"Unrecognized weather schema — columns were: {sorted(cols)}. "
        "Expected either the GeoCSV long-form header (Time, SHT "
        "Temperature, ...) or the short-form header (ts, temp_sht, ...)."
    )


def normalize_short_form(df: pd.DataFrame) -> pd.DataFrame:
    """Normalize a short-form dataframe (weatherdata.csv shape, or a
    Conduit API response already loaded into a DataFrame) into the
    canonical schema."""
    df = df.copy()
    df.columns = [str(c).strip() for c in df.columns]
    rename = {}
    for col in df.columns:
        if col in SHORT_FORM_DIRECT_MAP:
            rename[col] = SHORT_FORM_DIRECT_MAP[col]
        elif col.lower() in SHORT_FORM_ALIASES:
            rename[col] = SHORT_FORM_ALIASES[col.lower()]
    df = df.rename(columns=rename)

    if "Time" not in df.columns:
        raise SchemaError("Short-form data has no recognizable timestamp column.")

    # Rainfall: derive per-reading increments from the event-total
    # counters rather than trusting a raw sum (see module docstring).
    for canonical_name, source_col in RAIN_EVENT_TOTAL_COLUMNS.items():
        if source_col in df.columns:
            df[canonical_name] = _event_total_to_increment(
                pd.to_numeric(df[source_col], errors="coerce").fillna(0.0)
            )
        elif canonical_name not in df.columns:
            df[canonical_name] = 0.0

    for col in CANONICAL_COLUMNS:
        if col not in df.columns:
            df[col] = pd.NA

    numeric_cols = [c for c in CANONICAL_COLUMNS if c != "Time"]
    for c in numeric_cols:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    return df[CANONICAL_COLUMNS]


def normalize_geocsv_long_form(df: pd.DataFrame) -> pd.DataFrame:
    """The original GeoCSV export already uses the canonical column
    names — just ensure every canonical column exists and is numeric."""
    df = df.copy()
    df.columns = [str(c).strip() for c in df.columns]
    for col in CANONICAL_COLUMNS:
        if col not in df.columns:
            df[col] = pd.NA
    numeric_cols = [c for c in CANONICAL_COLUMNS if c != "Time"]
    for c in numeric_cols:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    return df[CANONICAL_COLUMNS]


def normalize(df: pd.DataFrame) -> pd.DataFrame:
    """Detect the format of an already-loaded dataframe and normalize it
    into the canonical schema."""
    fmt = detect_format(list(df.columns))
    if fmt == "geocsv_long_form":
        return normalize_geocsv_long_form(df)
    return normalize_short_form(df)


def find_geocsv_header_row(path: str) -> int | None:
    """GeoCSV 2.0 files have free-text metadata lines before the actual
    column header. Returns the row index, or None if this isn't a GeoCSV
    file (no line starts with 'Time,')."""
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for i, line in enumerate(f):
            if line.startswith("Time,"):
                return i
    return None


def load_any(path: str) -> pd.DataFrame:
    """Load a CSV file of either known shape and return it normalized to
    the canonical schema. This is the one function ingest.py should call
    — it replaces guessing the format from the filename."""
    header_row = find_geocsv_header_row(path)
    if header_row is not None:
        raw = pd.read_csv(path, skiprows=header_row, low_memory=False)
        return normalize_geocsv_long_form(raw)
    raw = pd.read_csv(path, low_memory=False)
    return normalize_short_form(raw)


def load_dataframe_from_records(records: list[dict]) -> pd.DataFrame:
    """Build a canonical frame from a list of dict records (e.g. parsed
    JSON from the Conduit API)."""
    if not records:
        raise SchemaError("No records to normalize (empty response).")
    raw = pd.DataFrame.from_records(records)
    return normalize(raw)


def load_dataframe_from_csv_text(csv_text: str) -> pd.DataFrame:
    """Build a canonical frame from raw CSV text (e.g. if the Conduit API
    ever responds with CSV instead of JSON)."""
    raw = pd.read_csv(io.StringIO(csv_text), low_memory=False)
    return normalize(raw)
