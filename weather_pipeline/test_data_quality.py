"""
Tests for data_quality.py — timestamp parsing, duplicate detection,
range validation, gap detection. Uses small synthetic frames (not the
real CSV) so each test isolates exactly one failure mode, per spec
section 35's "Data" test list.
"""
import pandas as pd
import pytest
from data_quality import validate, VALID_RANGES


def _base_rows(n=5, start="2026-08-28T00:00:00Z", freq="1min", **overrides):
    times = pd.date_range(start, periods=n, freq=freq, tz="UTC")
    df = pd.DataFrame({
        "Time": times.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "SHT Temperature": [15.0] * n,
        "SHT Humidity": [70.0] * n,
        "BMX Pressure 1": [852.0] * n,
        "Wind Speed": [1.0] * n,
        "Wind Gust": [1.0] * n,
        "Rain Gauge 1": [0.0] * n,
        "Rain Gauge 2": [0.0] * n,
    })
    for col, values in overrides.items():
        df[col] = values
    return df


def test_clean_data_scores_high():
    df = _base_rows(20)
    cleaned, report = validate(df)
    assert report.quality_score >= 95
    assert report.duplicate_timestamps == 0
    assert report.gap_count == 0
    assert report.total_rows == 20
    assert report.valid_rows == 20


def test_unparseable_timestamp_is_dropped_not_flagged():
    df = _base_rows(5)
    df.loc[2, "Time"] = "not-a-timestamp"
    cleaned, report = validate(df)
    # Structurally unusable rows are dropped outright, not just flagged —
    # there is no valid Time to key anything else off of.
    assert len(cleaned) == 4
    assert any("unparseable" in issue for issue in report.issues)


def test_duplicate_timestamps_detected_and_first_kept():
    df = _base_rows(5)
    df.loc[1, "Time"] = df.loc[0, "Time"]  # exact duplicate
    df.loc[1, "SHT Temperature"] = 99.0  # distinguishable if kept
    cleaned, report = validate(df)
    assert report.duplicate_timestamps == 1
    # first occurrence (temp=15.0) kept, duplicate (temp=99.0) dropped
    assert 99.0 not in cleaned["SHT Temperature"].values


def test_out_of_range_humidity_flagged_not_dropped():
    df = _base_rows(5)
    df.loc[3, "SHT Humidity"] = 250.0  # impossible
    cleaned, report = validate(df)
    assert report.invalid_value_rows >= 1
    assert len(cleaned) == 5  # flagged, row still present
    assert cleaned.loc[cleaned["SHT Humidity"] == 250.0, "_valid"].iloc[0] == False  # noqa: E712


def test_out_of_range_temperature_flagged():
    df = _base_rows(5)
    df.loc[0, "SHT Temperature"] = 80.0  # impossible for this climate
    _, report = validate(df)
    assert report.invalid_value_rows >= 1
    assert any("SHT Temperature" in issue for issue in report.issues)


def test_negative_rainfall_flagged():
    df = _base_rows(5)
    df.loc[0, "Rain Gauge 1"] = -1.0
    _, report = validate(df)
    assert any("negative" in issue.lower() for issue in report.issues)


def test_timestamp_gap_detected():
    df = _base_rows(3)
    # push the 3rd reading far into the future to create a gap
    df.loc[2, "Time"] = "2026-08-28T05:00:00Z"
    _, report = validate(df)
    assert report.gap_count == 1
    assert report.largest_gap_minutes > 100


def test_empty_dataframe_does_not_crash():
    df = _base_rows(0)
    cleaned, report = validate(df)
    assert report.total_rows == 0
    assert report.coverage_pct == 0.0
    assert report.quality_score == 0


def test_quality_label_matches_score_bands():
    df = _base_rows(20)
    _, report = validate(df)
    assert report.quality_score >= 95
    assert report.quality_label == "Excellent"


@pytest.mark.parametrize("col,lo,hi", [
    ("SHT Temperature", -5, 45),
    ("SHT Humidity", 0, 100),
    ("Wind Speed", 0, 60),
])
def test_valid_ranges_are_the_documented_ones(col, lo, hi):
    assert VALID_RANGES[col] == (lo, hi)
