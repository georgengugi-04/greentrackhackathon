"""
Tests for feature_engineering.py — aggregation and rolling-window math,
per spec section 35's "Analytics" list (rainfall/temperature aggregation,
humidity duration, wind calculations).
"""
import pandas as pd
import pytest
from feature_engineering import hourly_aggregates, daily_summary, rolling_window_features


def _rows(specs):
    """specs: list of (iso_time, temp, humidity, rain, wind, gust)"""
    return pd.DataFrame({
        "Time": pd.to_datetime([s[0] for s in specs], utc=True),
        "SHT Temperature": [s[1] for s in specs],
        "SHT Humidity": [s[2] for s in specs],
        "Rain Gauge 1": [s[3] for s in specs],
        "Wind Speed": [s[4] for s in specs],
        "Wind Gust": [s[5] for s in specs],
        "Wind Direction": [180] * len(specs),
        "Heat Index": [s[1] + 0.5 for s in specs],
        "Wet Bulb Temperature": [s[1] - 1 for s in specs],
        "Wet Bulb Globe Temperature": [s[1] - 3 for s in specs],
        "_valid": [True] * len(specs),
    })


def test_hourly_aggregates_averages_temperature_correctly():
    df = _rows([
        ("2026-08-28T00:10:00Z", 10.0, 70, 0, 1, 1),
        ("2026-08-28T00:30:00Z", 20.0, 70, 0, 1, 1),
        ("2026-08-28T00:50:00Z", 15.0, 70, 0, 1, 1),
    ])
    hourly = hourly_aggregates(df)
    assert len(hourly) == 1
    assert hourly.iloc[0]["temp_avg"] == 15.0
    assert hourly.iloc[0]["temp_min"] == 10.0
    assert hourly.iloc[0]["temp_max"] == 20.0
    assert hourly.iloc[0]["observation_count"] == 3


def test_hourly_aggregates_sums_rainfall_within_the_hour():
    df = _rows([
        ("2026-08-28T00:05:00Z", 15, 70, 0.2, 1, 1),
        ("2026-08-28T00:15:00Z", 15, 70, 0.2, 1, 1),
        ("2026-08-28T01:05:00Z", 15, 70, 0.2, 1, 1),  # different hour
    ])
    hourly = hourly_aggregates(df)
    assert len(hourly) == 2
    assert hourly.iloc[0]["rainfall_mm"] == pytest.approx(0.4)
    assert hourly.iloc[1]["rainfall_mm"] == pytest.approx(0.2)


def test_daily_summary_sums_hourly_rainfall_across_the_day():
    df = _rows([
        ("2026-08-28T00:05:00Z", 15, 70, 1.0, 1, 1),
        ("2026-08-28T12:05:00Z", 18, 70, 2.0, 1, 1),
        ("2026-08-29T00:05:00Z", 15, 70, 0.5, 1, 1),  # next day
    ])
    hourly = hourly_aggregates(df)
    daily = daily_summary(hourly)
    assert len(daily) == 2
    assert daily.iloc[0]["rainfall_mm"] == pytest.approx(3.0)
    assert daily.iloc[1]["rainfall_mm"] == pytest.approx(0.5)


def test_rolling_window_features_reflects_only_data_up_to_now():
    df = _rows([
        ("2026-08-28T00:00:00Z", 10.0, 70, 0, 1, 1),
        ("2026-08-28T12:00:00Z", 20.0, 70, 0, 1, 1),
        ("2026-08-29T00:00:00Z", 30.0, 70, 0, 1, 1),  # after "now" below
    ])
    now = pd.Timestamp("2026-08-28T13:00:00Z")
    features = rolling_window_features(df, now)
    # the 30.0 reading is after `now` and must not leak into the result
    assert features["temp_current"] == 20.0
    assert features["temp_max_24h"] == 20.0


def test_humidity_persistence_counts_longest_unbroken_high_run():
    specs = []
    # 3 readings at 10-min spacing, all >=80% (high), then one low, then 2 more high
    times = ["2026-08-28T00:00:00Z", "2026-08-28T00:10:00Z", "2026-08-28T00:20:00Z",
             "2026-08-28T00:30:00Z", "2026-08-28T00:40:00Z", "2026-08-28T00:50:00Z"]
    humidities = [85, 85, 85, 50, 85, 85]
    for t, h in zip(times, humidities):
        specs.append((t, 15, h, 0, 1, 1))
    df = _rows(specs)
    now = pd.Timestamp("2026-08-28T01:00:00Z")
    features = rolling_window_features(df, now)
    # longest run is 3 consecutive high readings (the first three), at
    # ~10 min spacing -> ~30 minutes, not the full 5x10=50min span
    assert features["humidity_persistent_high_minutes_24h"] == 30


def test_dry_period_hours_measures_time_since_last_rain():
    df = _rows([
        ("2026-08-27T00:00:00Z", 15, 70, 5.0, 1, 1),  # last rain
        ("2026-08-28T00:00:00Z", 15, 70, 0.0, 1, 1),
    ])
    now = pd.Timestamp("2026-08-28T06:00:00Z")
    features = rolling_window_features(df, now)
    # last rain was at 2026-08-27T00:00, now is 2026-08-28T06:00 -> 30h
    assert features["dry_period_hours"] == 30.0


def test_rolling_window_features_empty_frame_returns_empty_dict():
    df = _rows([])
    now = pd.Timestamp("2026-08-28T00:00:00Z")
    features = rolling_window_features(df, now)
    assert features == {}
