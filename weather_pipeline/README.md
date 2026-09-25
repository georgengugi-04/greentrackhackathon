# GreenTrack Weather Intelligence — Ingestion Pipeline

Offline pipeline that turns the JKUAT GeoCSV 2.0 export into the compact,
aggregated data the GreenTrack app reads from Firestore. Runs **outside**
the Flutter app — this project has no backend server (Flutter talks to
Firestore directly), so this is meant to be run once (or on a schedule
via cron/GitHub Actions) rather than as a live API.

## Why rules-based, not ML

The raw dataset is environmental observations only — there is no
labelled disease/outcome data to train or validate a predictive model
against. `risk_engine.py` is a transparent, rules-based expert system
(the same philosophy the app's existing `IrrigationAdvisor` already
uses), not a fitted model. Every score comes with a plain-language
explanation of exactly which observed values produced it. This is a
deliberate choice, not a limitation to apologize for — see the
hackathon brief's own guidance: "a trustworthy model is better than
fake AI."

## Pipeline stages

```
GeoCSV file
  -> load()                     [ingest.py]      find header row, parse, coerce numeric
  -> validate()                 [data_quality.py] flag/drop bad rows, score data quality
  -> hourly_aggregates()        [feature_engineering.py]
  -> daily_summary()            [feature_engineering.py]
  -> rolling_window_features()  [feature_engineering.py]  1h/3h/6h/24h/7d windows
  -> assess_crop_risk() x6      [risk_engine.py]  per-crop disease/heat/water/wind/rain risk
  -> JSON output                                  ready for Firestore
```

## Running it

```bash
pip install -r requirements.txt
python ingest.py /path/to/full_jkuat_export.csv --out ./output
```

This prints a data-quality summary and writes:
- `station_meta.json`, `data_quality.json`, `current_features.json`,
  `crop_risks.json` — one document each
- `hourly_aggregates.json`, `daily_summary.json` — one document per
  row, batch-written

Then push it to Firestore:

```bash
pip install firebase-admin
python upload_to_firestore.py --service-account ./serviceAccountKey.json --data ./output
```

## Rainfall column semantics — resolved against real data

A real 30-day, 2,939-row export (`weatherdata_sample.csv`, a short
column-name CSV rather than the verbose GeoCSV format — see "Multiple
input formats" below) finally had genuine rain events, settling the
open question left by both formats' raw gauge columns (`rg1`/`rg2` /
"Rain Gauge 1"/"Rain Gauge 2") being entirely zero in every export seen:
the real signal lives in the "Total Today" columns (`rg2tt` in that
file), and they're **not** a simple midnight-reset counter — they climb
over several hours then decay back down within the same day (drainage
or evaporation, presumably). `ingest.py`'s `_pick_rain_column()` now
automatically prefers whichever rain-related column in a given file
actually has non-zero data.

`feature_engineering.detect_rainfall_mode()` classifies a rain column as
`"increment"` (mostly zero, isolated single-reading tips — plain sum) or
`"cumulative"` (sustained multi-reading runs, whether a clean counter or
a rise-then-decay accumulator — summed via *positive deltas only*, which
handles both shapes correctly and ignores drainage/reset decreases).
Classification is by average run-length of consecutive non-zero
readings, not a same-day-monotonic check (an earlier version of this
heuristic misclassified the real rise-then-decay data as "increment" —
caught by testing against this file, not assumed correct).

Validated against the real data: Aug 14's rainfall computed as 3.6mm via
sum-of-positive-deltas vs. a 3.7mm raw peak accumulator value that day —
matches, as expected physically (total rain that fell ≈ peak
accumulation before any drainage). `current_features.json` now reports
`rainfall_mode: "cumulative"` and `rainfall_mode_verified: true` against
this file. Still falls back to `"unknown"`/unverified for any file with
too few rain events to classify (<5 non-zero readings).

## Multiple input formats

Two different real exports from this station have used different CSV
shapes: the original GeoCSV 2.0 format (verbose column names like "Rain
Gauge 1", metadata preamble before the header row) and a plain CSV with
short snake_case names (`ts`, `rg1`, `temp_sht`, ...) and no preamble.
`ingest.py` detects and normalizes both — `find_header_row()` accepts
either a `Time,` or `ts,` header line, and `load()` renames short columns
to the verbose equivalents via `SHORT_TO_VERBOSE_COLUMNS` before anything
else in the pipeline sees the data.

## Gap detection — adapts to the actual sampling cadence

`data_quality.validate()` used to assume a fixed ~1-minute sampling
interval (hardcoded from the original GeoCSV sample) and flag anything
more than 5x that as a gap. The 30-day short-column CSV samples every
~15 minutes, and that fixed assumption flagged 2,938 of 2,939 rows as
"gaps" — obviously wrong, caught by actually running it against the
file rather than assuming the original logic generalized. It now infers
the expected interval from the *mode* of rounded timestamp deltas in
the actual file (robust to a handful of real gaps skewing things,
unlike a median on a small sample), falling back to 60s only when
there's too little data to infer anything (<2 rows). Re-running against
the 15-minute file now correctly reports 1 genuine gap (95 min).

## Tested against real data

`data_quality.py`, `feature_engineering.py`, and `risk_engine.py` have
a 36-test pytest suite (`test_*.py`) plus multiple full end-to-end runs
against real data, not just written and assumed correct:
- A 4-row and later ~182-row dense sample from the original GeoCSV
  export — 100% quality score, correct duplicate/gap/out-of-range
  detection on injected edge cases, and a correctly-explained
  disease-risk signal for cabbage at 87% humidity citing the actual
  threshold crossed.
- The real 30-day, 2,939-row short-column CSV — 98% quality score after
  the gap-detection fix, correct rain-column auto-selection, and the
  rainfall-mode validation described above.

Not yet run: the full 169,440-row GeoCSV file (only a ~7,060-row subset
of it, `full_jkuat.csv`, has been used so far).
