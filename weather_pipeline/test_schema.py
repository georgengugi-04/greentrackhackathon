"""
Tests for schema.py — canonical schema normalization for the short-form
CSV / Conduit API shape, rainfall event-total-to-increment conversion,
and format auto-detection.
"""
import pandas as pd
import pytest
from schema import (
    normalize,
    normalize_short_form,
    normalize_geocsv_long_form,
    detect_format,
    load_dataframe_from_records,
    load_dataframe_from_csv_text,
    SchemaError,
    CANONICAL_COLUMNS,
)


def test_detect_format_geocsv():
    assert detect_format(["Time", "SHT Temperature", "SHT Humidity"]) == "geocsv_long_form"


def test_detect_format_short_form():
    assert detect_format(["ts", "temp_sht", "humidity_sht"]) == "short_form"


def test_detect_format_unrecognized_raises():
    with pytest.raises(SchemaError):
        detect_format(["foo", "bar"])


def test_short_form_direct_fields_mapped():
    df = pd.DataFrame({
        "ts": ["2026-08-14T00:00:12Z", "2026-08-14T00:15:22Z"],
        "temp_sht": [12.4, 12.1],
        "humidity_sht": [77.4, 78.8],
        "press_bmx": [852.8, 852.8],
        "wind_spd": [0, 0],
        "wind_dir": [185, 185],
        "wind_gust": [0, 0],
        "wind_gust_dir": [0, 0],
        "heat_idx": [12.1, 11.8],
        "wet_bulb_temp": [10.0, 9.9],
        "wet_bulb_globe_temp": [7.8, 7.5],
    })
    out = normalize_short_form(df)
    assert list(out.columns) == CANONICAL_COLUMNS
    assert out.iloc[0]["SHT Temperature"] == 12.4
    assert out.iloc[0]["SHT Humidity"] == 77.4
    assert out.iloc[0]["BMX Pressure 1"] == 852.8


def test_short_form_missing_timestamp_raises():
    df = pd.DataFrame({"temp_sht": [12.0], "humidity_sht": [70.0]})
    with pytest.raises(SchemaError):
        normalize_short_form(df)


def test_rain_event_total_converted_to_increment_not_summed_raw():
    """This is the core rainfall-semantics fix: rg2tt is an event-total
    counter that climbs then resets, not a per-reading increment. Naively
    summing the raw counter would wildly overcount; this test locks in
    the diff-and-clip behaviour instead."""
    df = pd.DataFrame({
        "ts": pd.date_range("2026-08-14T00:00:00Z", periods=5, freq="15min"),
        "temp_sht": [15.0] * 5,
        "humidity_sht": [70.0] * 5,
        # climbs 0 -> 0.1 -> 0.3 -> then resets to 0 -> climbs to 0.2
        "rg2tt": [0.0, 0.1, 0.3, 0.0, 0.2],
    })
    out = normalize_short_form(df)
    # increments: 0, 0.1, 0.2, 0 (reset clipped, not -0.3), 0.2
    assert out["Rain Gauge 2"].tolist() == pytest.approx([0.0, 0.1, 0.2, 0.0, 0.2])
    assert out["Rain Gauge 2"].sum() == pytest.approx(0.5)


def test_rain_gauge_columns_default_to_zero_when_absent():
    df = pd.DataFrame({
        "ts": ["2026-08-14T00:00:00Z"],
        "temp_sht": [15.0],
        "humidity_sht": [70.0],
    })
    out = normalize_short_form(df)
    assert out["Rain Gauge 1"].iloc[0] == 0.0
    assert out["Rain Gauge 2"].iloc[0] == 0.0


def test_geocsv_long_form_passthrough_adds_missing_canonical_columns():
    df = pd.DataFrame({
        "Time": ["2026-08-14T00:00:00Z"],
        "SHT Temperature": [15.0],
        "SHT Humidity": [70.0],
    })
    out = normalize_geocsv_long_form(df)
    assert list(out.columns) == CANONICAL_COLUMNS
    assert pd.isna(out["Wind Speed"].iloc[0])


def test_normalize_dispatches_by_detected_format():
    short_df = pd.DataFrame({"ts": ["2026-08-14T00:00:00Z"], "temp_sht": [15.0], "humidity_sht": [70.0]})
    out = normalize(short_df)
    assert "SHT Temperature" in out.columns
    assert out.iloc[0]["SHT Temperature"] == 15.0


def test_load_dataframe_from_records_empty_raises():
    with pytest.raises(SchemaError):
        load_dataframe_from_records([])


def test_load_dataframe_from_records_short_form():
    records = [
        {"ts": "2026-08-14T00:00:00Z", "temp_sht": 15.0, "humidity_sht": 70.0, "rg2tt": 0.2},
        {"ts": "2026-08-14T00:15:00Z", "temp_sht": 15.2, "humidity_sht": 71.0, "rg2tt": 0.4},
    ]
    out = load_dataframe_from_records(records)
    assert len(out) == 2
    assert out.iloc[1]["Rain Gauge 2"] == pytest.approx(0.2)  # increment, not the raw 0.4


def test_load_dataframe_from_csv_text():
    csv_text = "ts,temp_sht,humidity_sht\n2026-08-14T00:00:00Z,15.0,70.0\n"
    out = load_dataframe_from_csv_text(csv_text)
    assert len(out) == 1
    assert out.iloc[0]["SHT Temperature"] == 15.0


def test_load_dataframe_from_records_unrecognized_columns_raises():
    with pytest.raises(SchemaError):
        load_dataframe_from_records([{"foo": 1, "bar": 2}])
