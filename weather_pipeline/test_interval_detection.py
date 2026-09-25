"""
Tests for data_quality.detect_interval_seconds() — the station's actual
reporting interval must be detected from the data, not assumed, since
different exports/APIs have different cadences (see schema.py docstring
and section 9 of the project spec).
"""
import pandas as pd
from data_quality import detect_interval_seconds, validate


def _times(strs):
    return pd.to_datetime(pd.Series(strs), utc=True)


def test_detects_one_minute_cadence():
    times = pd.date_range("2026-08-28T00:00:00Z", periods=30, freq="1min", tz="UTC")
    assert detect_interval_seconds(pd.Series(times)) == 60.0


def test_detects_fifteen_minute_cadence():
    times = pd.date_range("2026-08-28T00:00:00Z", periods=30, freq="15min", tz="UTC")
    assert detect_interval_seconds(pd.Series(times)) == 900.0


def test_occasional_gap_does_not_skew_detected_interval():
    times = list(pd.date_range("2026-08-28T00:00:00Z", periods=20, freq="15min", tz="UTC"))
    times.append(times[-1] + pd.Timedelta(hours=3))  # one big outage
    assert detect_interval_seconds(pd.Series(times)) == 900.0


def test_too_little_data_falls_back_to_default():
    assert detect_interval_seconds(pd.Series(_times(["2026-08-28T00:00:00Z"]))) == 60


def test_data_quality_report_includes_detected_interval():
    df = pd.DataFrame({
        "Time": pd.date_range("2026-08-28T00:00:00Z", periods=10, freq="15min", tz="UTC").strftime("%Y-%m-%dT%H:%M:%SZ"),
        "SHT Temperature": [15.0] * 10,
        "SHT Humidity": [70.0] * 10,
    })
    _, report = validate(df)
    assert report.detected_interval_seconds == 900.0


def test_gap_threshold_scales_with_detected_interval_not_hardcoded_value():
    """A 20-minute jump is a real gap for a 1-minute station but normal
    noise for a 15-minute station — the threshold must scale with the
    detected interval, not a fixed constant."""
    fifteen_min_times = list(pd.date_range("2026-08-28T00:00:00Z", periods=10, freq="15min", tz="UTC"))
    fifteen_min_times[5] = fifteen_min_times[4] + pd.Timedelta(minutes=20)  # only ~1.3x interval
    df = pd.DataFrame({
        "Time": pd.Series(fifteen_min_times).dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "SHT Temperature": [15.0] * 10,
        "SHT Humidity": [70.0] * 10,
    })
    _, report = validate(df)
    assert report.gap_count == 0
