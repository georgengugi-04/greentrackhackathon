"""
Tests for risk_engine.py — per spec section 35's "AI" test list (model
input validation, output shape, edge cases). "AI" here means the
rules-based risk engine (see README on why this isn't a fitted model).
"""
import pytest
from risk_engine import (
    CROP_PROFILES, assess_crop_risk, spray_window_status, irrigation_need,
)


def _features(**overrides):
    base = {
        "temp_current": 18.0,
        "humidity_avg_24h": 60.0,
        "humidity_persistent_high_minutes_24h": 0,
        "rainfall_mm_24h": 0.0,
        "rainfall_mm_6h": 0.0,
        "dry_period_hours": 6.0,
        "wind_current": 1.0,
        "wind_gust_max_24h": 1.5,
        "heat_index_current": 18.5,
    }
    base.update(overrides)
    return base


def test_unknown_crop_raises():
    with pytest.raises(ValueError):
        assess_crop_risk("durian", _features())


def test_all_six_required_crops_are_configured():
    required = {"spinach", "cabbage", "tomato", "coffee", "maize", "beans"}
    assert required.issubset(CROP_PROFILES.keys())


def test_calm_conditions_produce_low_risk():
    risk = assess_crop_risk("cabbage", _features())
    assert risk.level == "Low"
    assert risk.overall < 35
    assert len(risk.reasons) >= 1  # never a bare score with no explanation


def test_high_humidity_and_recent_rain_raises_disease_risk():
    calm = assess_crop_risk("cabbage", _features())
    humid = assess_crop_risk("cabbage", _features(
        humidity_avg_24h=90.0,
        humidity_persistent_high_minutes_24h=240,
        rainfall_mm_24h=5.0,
    ))
    assert humid.disease > calm.disease
    assert humid.level in ("Moderate", "High")
    assert any("humidity" in r.lower() for r in humid.reasons)


def test_heat_stress_triggers_above_crop_specific_threshold():
    # cabbage heat-stress threshold is 29C in the profile
    below = assess_crop_risk("cabbage", _features(temp_current=25.0))
    above = assess_crop_risk("cabbage", _features(temp_current=32.0, heat_index_current=34))
    assert above.heat > below.heat
    assert any("heat" in r.lower() or "temperature" in r.lower() for r in above.reasons)


def test_recent_rain_reduces_water_stress():
    dry = assess_crop_risk("tomato", _features(dry_period_hours=96))
    just_rained = assess_crop_risk("tomato", _features(dry_period_hours=96, rainfall_mm_24h=10))
    assert just_rained.water < dry.water


def test_extreme_wind_gust_produces_high_wind_risk():
    calm = assess_crop_risk("maize", _features())
    windy = assess_crop_risk("maize", _features(wind_gust_max_24h=20.0))
    assert windy.wind > calm.wind
    assert windy.wind >= 60


def test_heavy_rainfall_raises_rain_risk_distinct_from_disease():
    risk = assess_crop_risk("beans", _features(rainfall_mm_24h=25.0))
    assert risk.rain >= 60


def test_all_risk_scores_stay_within_0_100_bounds():
    # deliberately extreme/adversarial inputs
    risk = assess_crop_risk("spinach", _features(
        humidity_avg_24h=200, humidity_persistent_high_minutes_24h=999999,
        rainfall_mm_24h=999, temp_current=999, heat_index_current=999,
        dry_period_hours=99999, wind_gust_max_24h=999, wind_current=999,
    ))
    for value in (risk.overall, risk.disease, risk.heat, risk.water, risk.wind, risk.rain):
        assert 0 <= value <= 100


def test_missing_optional_features_do_not_crash():
    # a partially-populated features dict (e.g. before 24h of data exists)
    minimal = {"temp_current": 18.0}
    risk = assess_crop_risk("coffee", minimal)
    assert 0 <= risk.overall <= 100
    assert risk.reasons  # still explains something, doesn't crash


def test_recommendation_and_action_are_never_empty():
    for crop in CROP_PROFILES:
        risk = assess_crop_risk(crop, _features())
        assert risk.recommendation.strip()
        assert risk.action.strip()


def test_spray_window_not_recommended_in_high_wind():
    result = spray_window_status(_features(wind_current=10.0, wind_gust_max_24h=15.0), "cabbage")
    assert result["status"] == "Not recommended"


def test_spray_window_suitable_in_calm_dry_conditions():
    result = spray_window_status(_features(wind_current=0.5, wind_gust_max_24h=1.0, rainfall_mm_6h=0), "cabbage")
    assert result["status"] == "Suitable"


def test_spray_window_caution_after_recent_rain():
    result = spray_window_status(_features(wind_current=0.5, wind_gust_max_24h=1.0, rainfall_mm_6h=3.0), "cabbage")
    assert result["status"] == "Caution"


def test_irrigation_need_low_after_significant_rain():
    result = irrigation_need("spinach", _features(rainfall_mm_24h=10.0))
    assert result["need"] == "LOW"


def test_irrigation_need_high_when_dry_and_hot():
    result = irrigation_need("spinach", _features(dry_period_hours=72, temp_current=24, rainfall_mm_24h=0))
    assert result["need"] == "HIGH"


def test_irrigation_need_never_missing_a_reason():
    for crop in CROP_PROFILES:
        result = irrigation_need(crop, _features())
        assert result["reason"].strip()
