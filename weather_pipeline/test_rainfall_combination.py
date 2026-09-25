"""
Tests for feature_engineering._combined_rainfall() — combining both rain
gauge channels (row-wise max, not sum) without double-counting, and
falling back cleanly when only one gauge column is present. This is what
fixed the real bug found against weatherdata.csv: Rain Gauge 1 is
essentially always 0 in that export while Rain Gauge 2 carries the real
signal, and the pipeline was previously reading Rain Gauge 1 only.
"""
import pandas as pd
import pytest
from feature_engineering import hourly_aggregates, rolling_window_features


def _rows_with_both_gauges(specs):
    """specs: list of (iso_time, rain_gauge_1, rain_gauge_2)"""
    n = len(specs)
    return pd.DataFrame({
        "Time": pd.to_datetime([s[0] for s in specs], utc=True),
        "SHT Temperature": [15.0] * n,
        "SHT Humidity": [70.0] * n,
        "Rain Gauge 1": [s[1] for s in specs],
        "Rain Gauge 2": [s[2] for s in specs],
        "Wind Speed": [1.0] * n,
        "Wind Gust": [1.0] * n,
        "Wind Direction": [180] * n,
        "Heat Index": [15.5] * n,
        "Wet Bulb Temperature": [14.0] * n,
        "Wet Bulb Globe Temperature": [12.0] * n,
        "_valid": [True] * n,
    })


def test_second_gauge_is_picked_up_when_first_is_inactive():
    """Mirrors the real weatherdata.csv situation: gauge 1 stays at 0
    while gauge 2 carries the actual rainfall."""
    df = _rows_with_both_gauges([
        ("2026-08-28T00:05:00Z", 0.0, 0.2),
        ("2026-08-28T00:15:00Z", 0.0, 0.3),
    ])
    hourly = hourly_aggregates(df)
    assert hourly.iloc[0]["rainfall_mm"] == pytest.approx(0.5)


def test_gauges_are_maxed_not_summed_to_avoid_double_counting():
    df = _rows_with_both_gauges([
        ("2026-08-28T00:05:00Z", 0.4, 0.4),  # same event, both sensors report it
    ])
    hourly = hourly_aggregates(df)
    assert hourly.iloc[0]["rainfall_mm"] == pytest.approx(0.4)  # not 0.8


def test_rolling_window_rain_sum_uses_combined_gauges():
    df = _rows_with_both_gauges([
        ("2026-08-28T00:05:00Z", 0.0, 1.0),
        ("2026-08-28T00:35:00Z", 0.0, 2.0),
    ])
    now = pd.Timestamp("2026-08-28T01:00:00Z")
    features = rolling_window_features(df, now)
    assert features["rainfall_mm_24h"] == pytest.approx(3.0)


def test_single_gauge_fixtures_unaffected_backward_compatible():
    """When only Rain Gauge 1 is present (older test fixtures / GeoCSV
    rows missing gauge 2 entirely), behaviour is unchanged."""
    df = pd.DataFrame({
        "Time": pd.to_datetime(["2026-08-28T00:05:00Z"], utc=True),
        "SHT Temperature": [15.0],
        "SHT Humidity": [70.0],
        "Rain Gauge 1": [0.6],
        "Wind Speed": [1.0],
        "Wind Gust": [1.0],
        "Wind Direction": [180],
        "Heat Index": [15.5],
        "Wet Bulb Temperature": [14.0],
        "Wet Bulb Globe Temperature": [12.0],
        "_valid": [True],
    })
    hourly = hourly_aggregates(df)
    assert hourly.iloc[0]["rainfall_mm"] == pytest.approx(0.6)
