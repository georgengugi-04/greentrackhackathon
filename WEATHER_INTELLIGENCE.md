# GreenTrack Weather Intelligence — Hack The Weather 2026

*JHUB Africa · submission deadline 18 September 2026 · finale 6 October 2026, JKUAT*

This document covers the Weather Intelligence feature built into GreenTrack for
this hackathon. For the rest of the app (crop tracking, marketplace, harvest
logging, etc.), see the main [README.md](./README.md) — this feature was built
as an extension of that existing product, not a new app.

**Data source update:** the pipeline now supports fetching live from the
official JHUB Conduit API (`conduit_client.py`) in addition to the offline
CSV exports it started with, and labels every Firestore write `live` /
`historical` / `demo` so the app can be honest about what it's showing
rather than presenting cached data as current. See "Running it" and
"LIVE / HISTORICAL / DEMO data-state labeling" in
[`weather_pipeline/README.md`](./weather_pipeline/README.md) for details.

---

## Problem

Farmers often receive weather information without crop-specific interpretation.
A humidity reading or a rainfall total on its own doesn't tell a farmer whether
their cabbage is at fungal-disease risk today, or whether their spinach needs
water. Generic weather apps report numbers; they don't translate those numbers
into what a specific crop, on a specific day, actually needs.

## Solution

GreenTrack Weather Intelligence turns real environmental observations from a
JKUAT weather station into crop-specific, explainable agricultural
recommendations — never a bare risk percentage, always the reasons behind it
and a concrete action to consider.

```
REAL WEATHER DATA → VALIDATION → FEATURE ENGINEERING → CROP-SPECIFIC RISK
                                                              ↓
                                        FARMER ACTION ← EXPLAINABLE RECOMMENDATION
```

## Data

| | |
|---|---|
| Station | Kenya Kiambu JKUAT IoT AWS |
| Site | JKUAT |
| Sensor ID | 61 |
| Location | -1.099736, 37.014528 |
| Elevation | 1523 m |
| Format | GeoCSV 2.0, ~169,440 observations, ~1/minute |
| Attribution | 3d-fewsnet.icdp.ucar.edu |
| DOI | https://doi.org/10.5065/d6v1236q |

Measurements used: temperature, humidity, pressure, rainfall (2 gauges), wind
speed/direction/gusts, heat index, wet bulb temperature, wet bulb globe
temperature. No measurements are invented or estimated beyond what the
station actually reports.

## Architecture

This app has **no backend server** — the Flutter client talks to Firestore
directly. That shaped a deliberate architectural choice: rather than force a
live "ingestion API" that doesn't fit the existing stack, weather ingestion is
an **offline pipeline** (`weather_pipeline/`, Python) run once (or on a
schedule via cron/CI) that processes the full CSV and writes compact,
pre-aggregated documents to Firestore. The app never touches the raw 169k-row
file — only hourly/daily aggregates and a handful of "current state" documents.

```
GeoCSV file
  → ingest.py           (finds the real header row past GeoCSV's metadata block)
  → data_quality.py      validates: duplicate timestamps, out-of-range values,
                          timestamp gaps, produces a 0-100 quality score
  → feature_engineering.py
                          hourly/daily aggregates + rolling 1h/3h/6h/24h/7d
                          windows, humidity-persistence duration, dry-period length
  → risk_engine.py       per-crop disease/heat/water/wind/rain risk (rules-based,
                          see "AI / Analytics" below), spray-window status,
                          irrigation need
  → upload_to_firestore.py
                          writes weather_stations/{id}/{quality,features,
                          crop_risks,hourly,daily}/...
  → Flutter app           reads only the aggregates via
                          lib/core/services/weather_station_service.dart
```

Flutter-side pieces added:
- `lib/data/models/models.dart` — `WeatherStationInfo`, `WeatherDataQuality`,
  `WeatherFeatures`, `CropWeatherRisk`, `SprayWindow`, `IrrigationNeed` (field
  names mirror the Python JSON output 1:1 — no translation layer to keep in sync)
- `lib/core/services/weather_station_service.dart` + matching providers
- `TodaysFarmIntelligenceCard` on the farmer dashboard (the hero feature)
- `WeatherExplorerScreen` — advanced multi-tab view for judges/researchers
- `SprayAndIrrigationScreen`, `HowGreenTrackWorksScreen`
- Weather-driven entries in the existing live-notification system

This is kept entirely separate from the app's existing `WeatherService`
(Open-Meteo, used for the farmer's own location on the original weather
card) — the two are never silently merged. The JKUAT station is a real,
fixed-location sensor; conflating it with "weather at any given farm" would
misrepresent the data (see section 20 of the build brief). Every screen that
shows station data labels it as coming from that specific station, and shows
the farm-vs-station distance where relevant.

## AI / Analytics

**This is a rules-based expert system, not a fitted machine-learning model —
and that is a deliberate choice, not a limitation being apologized for.**

The raw JKUAT dataset is environmental observations only. There is no
labelled disease-outcome data (no records of "and then this crop actually
got blight") to train or validate a predictive model against. Building a
model without that would mean either faking accuracy claims or shipping an
unvalidated black box — both worse than the honest alternative.

Instead, `risk_engine.py` implements the same pattern GreenTrack's existing
`IrrigationAdvisor` already uses elsewhere in the app: transparent,
inspectable rules, tuned per crop, with every score returning the specific
reasons behind it.

**Inputs:** current + rolling-window temperature, humidity, rainfall, wind,
heat index, per-crop sensitivity profile (6 crops: spinach, cabbage, tomato,
coffee, maize, beans — temperature range, disease-humidity threshold,
heat-stress threshold, water need, spray wind limit).

**Outputs:** disease/heat/water/wind/rain risk (0-100 each) + overall
weighted score, a risk level (Low/Moderate/High), a specific recommendation
and action, a spray-window verdict, an irrigation-need level — every one
paired with plain-language reasons naming the actual observed values that
produced it.

**Validation approach:** none in the ML sense — there is nothing to validate
predictive accuracy against. What *was* validated: the pipeline was run
end-to-end against real sample rows from the dataset (see
`weather_pipeline/README.md`) and produced a correctly-reasoned disease-risk
signal for cabbage at 87% humidity, citing the actual threshold crossed. The
thresholds themselves (e.g. "80% humidity for 3+ hours raises cabbage disease
risk") come from general agronomic knowledge about these crops, not from
fitting a curve to this specific station's history — they are configuration,
not a model, and should be reviewed by an agricultural extension officer
before being treated as authoritative.

**Limitations, stated plainly:**
- Not a forecast. Every number is a past/current observation, labelled
  "current observed conditions" everywhere it appears.
- One station. A single JKUAT sensor doesn't represent every farm's exact
  microclimate — the app shows the station's location and never claims
  otherwise.
- Thresholds are general agronomic defaults, not statistically fitted to
  this station's specific history or validated against real disease outcomes
  at this site.
- Rainfall-column semantics were uncertain from the small sample available
  early in this build — **since resolved, and corrected once checked
  against the full 31-day `weatherdata.csv` export**: "Rain Gauge 1" is
  essentially inactive in this export, "Rain Gauge 2" carries the real
  signal, and both are event-total counters that reset (not per-reading
  increments as first assumed). The pipeline now converts them to
  increments and combines both gauges. See "Rainfall semantics —
  corrected" in `weather_pipeline/README.md` for the full investigation.

**Adaption Labs — evaluated against their actual platform materials, not
speculatively.** They offer two products: **Adaptive Data** (turns raw/messy
data into training-ready datasets, including expansion into 242+ languages)
and **AutoScientist** (automated end-to-end model training from a stated
objective, down to "Tiny AutoScientist" models small enough for phones).

Two concrete, honestly-justified fits found — and one deliberately *not*
recommended:

- ❌ **Not recommended: training a weather-risk model with AutoScientist.**
  Their own pitch is training toward a stated behavioral objective — but that
  still needs some ground truth to converge on. This dataset has none (no
  "and then this crop actually got blight" records), so a trained model here
  would either just re-learn my own rules from nowhere, or need fabricated
  labels — exactly the "fake AI" the brief warns against. The honest
  rules-based engine stays as-is for weather risk.
- ✅ **Adaptive Data for explanation-text localization.** This session's
  Swahili localization pass (`AppLocalizations`, `app_sw.arb`) was done by
  hand, string by string. Adaptive Data's language-expansion capability
  (242+ languages, graded before/after for quality) is a genuine fit for
  scaling the risk engine's plain-language `reasons`/`recommendation`
  templates into more languages than one person can hand-translate
  correctly — this is about the *output text*, not the risk logic itself.
- ✅ **AutoScientist for the existing pest/disease scanner.** GreenTrack
  already has a pest/disease diagnosis screen
  (`lib/features/farmer/screens/farmer_pest_diagnosis_screen.dart`), but its
  vision service (`lib/core/services/ai_vision_service.dart`) currently falls
  back to a non-ML `HeuristicVisionService` unless a remote vision API key is
  configured — there's no custom-trained model in the app today. Unlike
  weather risk, labeled plant-disease image datasets genuinely exist (e.g.
  PlantVillage-style datasets), making this a scientifically sound
  supervised-learning problem AutoScientist's stated use case ("build an AI
  plant doctor," literally listed in their own materials) fits well. This
  would replace/augment the vision service, not the weather feature.

**None of this is implemented** — it's a genuine "where would this actually
help" assessment as the brief asks for, not an integration built for its own
sake. Both would need real work (a labeled plant-disease dataset for the
second one; Adaption Labs platform access and credits for either) beyond
what this session had in hand.

## What's honestly not done yet

- A real ~7,060-row export (5 days, 28 Aug – 1 Sep 2026) has been run
  through the full pipeline successfully (98% data quality, sane rainfall
  numbers, correctly-reasoned risk output) — see `weather_pipeline/output/`.
  **Not yet pushed to Firestore** — that needs a Firebase service-account
  key, which wasn't available in this session. Run
  `python upload_to_firestore.py --service-account ./key.json --data ./output`
  to finish this.
- The complete 169,440-row file (the full dataset the station metadata
  describes) hasn't been processed — only the ~7,060-row export above.
- ~~No automated tests~~ — 36 pytest tests now cover data validation,
  feature engineering, and the risk engine (`weather_pipeline/test_*.py`).
  One of them caught a real bug during development (see the pipeline
  README's "Running tests" section). Flutter-side widget tests are still
  not written.
- No combined multi-metric timeline chart (Weather Explorer has separate
  per-metric charts, not one overlaid view).
- The AutoScientist plant-disease-scanner idea above is a documented
  recommendation, not implemented — it needs a labeled image dataset and
  platform access neither of which were available here.
