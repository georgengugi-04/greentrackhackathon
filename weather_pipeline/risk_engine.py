"""
GreenTrack Weather Intelligence — Crop Weather Risk Engine
============================================================
Transparent, rules-based expert system — deliberately NOT a fitted ML
model. The raw JKUAT dataset has no labelled disease/outcome data to
train or validate a predictive model against, so a rules-based system
that a farmer (and a judge) can actually inspect is the honest choice
here, per the hackathon brief's own guidance: "a trustworthy model is
better than fake AI." This mirrors the existing IrrigationAdvisor
service already in the Flutter app (lib/core/services/irrigation_advisor.dart)
— same philosophy, same style of reasoning, extended to weather-driven
crop risk instead of just watering.

Every score here is explainable: each function returns not just a 0-100
number but the plain-language reasons behind it, because the brief is
explicit that "Risk = 82%" alone is not acceptable output.
"""
from __future__ import annotations
from dataclasses import dataclass, field

CROP_PROFILES = {
    "spinach": {
        "label": "Spinach",
        "temp_sensitivity": "high",       # bolts/stresses in heat
        "ideal_temp_range": (10, 24),
        "humidity_sensitivity": "high",   # prone to downy mildew
        "disease_humidity_threshold": 75,
        "heat_stress_temp": 28,
        "water_need": "high",             # shallow roots, dries out fast
        "spray_wind_limit_ms": 3.0,
    },
    "cabbage": {
        "label": "Cabbage",
        "temp_sensitivity": "medium",
        "ideal_temp_range": (15, 24),
        "humidity_sensitivity": "high",   # fungal issues (black rot, downy mildew)
        "disease_humidity_threshold": 78,
        "heat_stress_temp": 29,
        "water_need": "medium",
        "spray_wind_limit_ms": 3.5,
    },
    "tomato": {
        "label": "Tomato",
        "temp_sensitivity": "high",       # poor fruit set above ~32C
        "ideal_temp_range": (18, 27),
        "humidity_sensitivity": "high",   # blight risk
        "disease_humidity_threshold": 80,
        "heat_stress_temp": 32,
        "water_need": "medium",
        "spray_wind_limit_ms": 3.0,
    },
    "coffee": {
        "label": "Coffee",
        "temp_sensitivity": "medium",
        "ideal_temp_range": (15, 24),
        "humidity_sensitivity": "high",   # coffee leaf rust
        "disease_humidity_threshold": 80,
        "heat_stress_temp": 30,
        "water_need": "medium",
        "spray_wind_limit_ms": 3.5,
    },
    "maize": {
        "label": "Maize",
        "temp_sensitivity": "medium",
        "ideal_temp_range": (18, 30),
        "humidity_sensitivity": "medium",  # grey leaf spot, rust
        "disease_humidity_threshold": 82,
        "heat_stress_temp": 34,
        "water_need": "medium",
        "spray_wind_limit_ms": 4.0,
    },
    "beans": {
        "label": "Beans",
        "temp_sensitivity": "medium",
        "ideal_temp_range": (16, 27),
        "humidity_sensitivity": "high",   # rust, anthracnose, bean blight
        "disease_humidity_threshold": 78,
        "heat_stress_temp": 30,
        "water_need": "medium",
        "spray_wind_limit_ms": 3.5,
    },
}


@dataclass
class RiskResult:
    overall: int
    disease: int
    heat: int
    water: int
    wind: int
    rain: int
    level: str  # Low / Moderate / High
    recommendation: str
    action: str
    reasons: list[str] = field(default_factory=list)

    def to_dict(self):
        d = self.__dict__.copy()
        return d


def _clamp(x, lo=0, hi=100):
    return max(lo, min(hi, x))


def assess_crop_risk(crop_key: str, features: dict) -> RiskResult:
    profile = CROP_PROFILES.get(crop_key.lower())
    if profile is None:
        raise ValueError(f"Unknown crop profile: {crop_key}")

    reasons = []
    temp = features.get("temp_current")
    humidity_24h = features.get("humidity_avg_24h") or features.get("humidity_current") or 0
    persistent_high_humidity_min = features.get("humidity_persistent_high_minutes_24h", 0)
    rainfall_24h = features.get("rainfall_mm_24h", 0) or 0
    dry_hours = features.get("dry_period_hours", 0) or 0
    wind_current = features.get("wind_current", 0) or 0
    wind_gust = features.get("wind_gust_max_24h", 0) or 0
    heat_index = features.get("heat_index_current")

    # ── DISEASE RISK: humidity + recent rain + suitable temp for fungal growth
    disease = 0
    if humidity_24h >= profile["disease_humidity_threshold"]:
        disease += 45
        reasons.append(f"Humidity has averaged {humidity_24h:.0f}% over the last 24h, "
                        f"above the {profile['label'].lower()} disease-risk threshold "
                        f"({profile['disease_humidity_threshold']}%).")
    elif humidity_24h >= profile["disease_humidity_threshold"] - 10:
        disease += 20
        reasons.append(f"Humidity ({humidity_24h:.0f}%) is approaching levels that favour fungal disease.")
    if persistent_high_humidity_min >= 180:
        disease += 25
        reasons.append(f"High humidity has persisted for over {persistent_high_humidity_min // 60}h "
                        "in the last day, giving fungal spores time to develop.")
    if rainfall_24h > 2:
        disease += 20
        reasons.append(f"{rainfall_24h:.1f}mm of rain fell in the last 24h, leaving leaf surfaces wet.")
    lo, hi = profile["ideal_temp_range"]
    if temp is not None and lo <= temp <= hi:
        disease += 10
        reasons.append("Current temperature is within the range many fungal pathogens favour.")
    disease = _clamp(disease)

    # ── HEAT RISK
    heat = 0
    if temp is not None and temp >= profile["heat_stress_temp"]:
        heat = _clamp(40 + (temp - profile["heat_stress_temp"]) * 8)
        reasons.append(f"Temperature ({temp:.1f}°C) is at or above the heat-stress threshold "
                        f"for {profile['label'].lower()} ({profile['heat_stress_temp']}°C).")
    elif temp is not None and temp >= profile["heat_stress_temp"] - 3:
        heat = 25
        reasons.append(f"Temperature ({temp:.1f}°C) is approaching heat-stress levels.")
    if heat_index is not None and temp is not None and heat_index - temp >= 3:
        heat = _clamp(heat + 15)
        reasons.append(f"Heat index ({heat_index:.1f}°C) is notably higher than air temperature, "
                        "meaning it feels hotter to the plant's transpiration system.")

    # ── WATER STRESS: dry period + heat, offset by recent rain
    water = 0
    if dry_hours >= 72:
        water += 40
        reasons.append(f"No rainfall recorded for over {dry_hours / 24:.0f} day(s).")
    elif dry_hours >= 24:
        water += 20
        reasons.append(f"No rainfall recorded for {dry_hours:.0f}h.")
    if temp is not None and temp >= profile["ideal_temp_range"][1]:
        water = _clamp(water + 15)
        reasons.append("Elevated temperature increases plant water demand.")
    if rainfall_24h > 5:
        water = _clamp(water - 30)
        reasons.append(f"Recent rainfall ({rainfall_24h:.1f}mm in 24h) has reduced immediate water stress.")
    water = _clamp(water)

    # ── WIND RISK
    wind = 0
    if wind_gust >= 12:
        wind = _clamp(60 + (wind_gust - 12) * 5)
        reasons.append(f"Wind gusts up to {wind_gust:.1f} m/s recorded — risk of physical crop damage.")
    elif wind_gust >= 8:
        wind = 35
        reasons.append(f"Moderate wind gusts ({wind_gust:.1f} m/s) recorded.")
    elif wind_current >= 5:
        wind = 15

    # ── RAIN RISK (waterlogging / drainage concern, distinct from disease)
    rain = 0
    if rainfall_24h >= 20:
        rain = _clamp(60 + (rainfall_24h - 20))
        reasons.append(f"Heavy rainfall ({rainfall_24h:.1f}mm/24h) raises waterlogging/drainage concern.")
    elif rainfall_24h >= 8:
        rain = 35
        reasons.append(f"Notable rainfall ({rainfall_24h:.1f}mm/24h) recorded.")
    elif rainfall_24h > 0:
        rain = 10

    overall = round(
        disease * 0.35 + heat * 0.2 + water * 0.2 + wind * 0.1 + rain * 0.15
    )
    level = "Low" if overall < 35 else "Moderate" if overall < 65 else "High"

    # Pick the dominant risk to drive the headline recommendation —
    # matches the brief's Action Center categories.
    scores = {"disease": disease, "heat": heat, "water": water, "wind": wind, "rain": rain}
    dominant = max(scores, key=scores.get)
    recommendation, action = _recommendation_for(dominant, profile, features)

    if not reasons:
        reasons.append("Conditions are currently within normal ranges for this crop.")

    return RiskResult(
        overall=overall, disease=disease, heat=heat, water=water, wind=wind, rain=rain,
        level=level, recommendation=recommendation, action=action, reasons=reasons,
    )


def _recommendation_for(dominant: str, profile: dict, features: dict) -> tuple[str, str]:
    label = profile["label"].lower()
    if dominant == "disease":
        return (
            f"Recent conditions may increase fungal disease risk for {label}.",
            f"Monitor {label} leaves for early signs of fungal disease and avoid unnecessary overhead irrigation.",
        )
    if dominant == "heat":
        return (
            f"Elevated temperatures may increase heat stress for {label}.",
            "Monitor crops closely and consider shade or timing irrigation for cooler hours.",
        )
    if dominant == "water":
        return (
            f"Extended dry conditions may be increasing water stress for {label}.",
            "Consider irrigation, prioritising this plot in your watering schedule.",
        )
    if dominant == "wind":
        return (
            "Current wind conditions may risk physical crop damage.",
            "Check for lodging or damage; avoid spraying until wind calms.",
        )
    return (
        "Recent rainfall may increase waterlogging or drainage concern.",
        "Check drainage and avoid unnecessary irrigation.",
    )


def spray_window_status(features: dict, profile_key: str = "cabbage") -> dict:
    profile = CROP_PROFILES.get(profile_key.lower(), CROP_PROFILES["cabbage"])
    wind = features.get("wind_current", 0) or 0
    gust = features.get("wind_gust_max_24h", 0) or 0
    rainfall_recent = features.get("rainfall_mm_6h", 0) or 0
    limit = profile["spray_wind_limit_ms"]

    if wind > limit or gust > limit * 1.8:
        return {"status": "Not recommended", "reason": "Wind conditions are currently elevated.",
                "suggested_action": "Wait for calmer conditions."}
    if rainfall_recent > 1:
        return {"status": "Caution", "reason": "Rain has fallen recently — spray may wash off before absorption.",
                "suggested_action": "Wait until foliage dries."}
    if wind > limit * 0.6:
        return {"status": "Caution", "reason": "Wind is moderate — drift risk is elevated.",
                "suggested_action": "Consider waiting or spraying during calmer hours."}
    return {"status": "Suitable", "reason": "Wind and rainfall conditions are currently favourable.",
            "suggested_action": "Conditions are currently suitable for spraying."}


def irrigation_need(crop_key: str, features: dict) -> dict:
    profile = CROP_PROFILES.get(crop_key.lower())
    if profile is None:
        raise ValueError(f"Unknown crop profile: {crop_key}")
    rainfall_24h = features.get("rainfall_mm_24h", 0) or 0
    dry_hours = features.get("dry_period_hours", 0) or 0
    temp = features.get("temp_current")

    if rainfall_24h > 5:
        return {"need": "LOW", "reason": "Recent rainfall has reduced the estimated immediate watering requirement."}
    if dry_hours >= 48 and temp is not None and temp >= profile["ideal_temp_range"][1] - 2:
        return {"need": "HIGH", "reason": "No significant recent rainfall has been detected and "
                                           "temperatures have remained elevated."}
    if dry_hours >= 24:
        return {"need": "MEDIUM", "reason": f"No rainfall recorded for {dry_hours:.0f}h."}
    return {"need": "LOW", "reason": "Recent conditions do not indicate elevated water stress."}
