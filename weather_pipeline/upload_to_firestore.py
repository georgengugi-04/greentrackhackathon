"""
GreenTrack Weather Intelligence — Firestore Upload
=====================================================
Pushes the JSON output from ingest.py into Firestore, in the compact
aggregated form the Flutter app actually reads (never the raw 169k rows).

Requires a Firebase service-account key — download one from:
  Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
Never commit this key file to source control.

Usage:
    pip install firebase-admin
    python upload_to_firestore.py --service-account ./serviceAccountKey.json --data ./output

Firestore layout this writes:
  weather_stations/{station_id}                      <- station_meta.json
  weather_stations/{station_id}/quality/latest        <- data_quality.json
  weather_stations/{station_id}/features/current      <- current_features.json
  weather_stations/{station_id}/crop_risks/{crop_key} <- one doc per crop, from crop_risks.json
  weather_stations/{station_id}/hourly/{iso_hour}     <- one doc per hour (hourly_aggregates.json)
  weather_stations/{station_id}/daily/{iso_date}      <- one doc per day (daily_summary.json)
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def main(service_account_path: str, data_dir: str):
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    data = Path(data_dir)
    station_meta = json.loads((data / "station_meta.json").read_text())
    station_id = station_meta["station_id"]
    station_ref = db.collection("weather_stations").document(station_id)

    print(f"Writing station_meta -> weather_stations/{station_id}")
    station_ref.set(station_meta, merge=True)

    quality = json.loads((data / "data_quality.json").read_text())
    print("Writing data_quality -> .../quality/latest")
    station_ref.collection("quality").document("latest").set(quality)

    features = json.loads((data / "current_features.json").read_text())
    print("Writing current_features -> .../features/current")
    station_ref.collection("features").document("current").set(features)

    crop_risks = json.loads((data / "crop_risks.json").read_text())
    print(f"Writing {len(crop_risks)} crop risk docs -> .../crop_risks/*")
    for crop_key, risk in crop_risks.items():
        station_ref.collection("crop_risks").document(crop_key).set(risk)

    hourly = json.loads((data / "hourly_aggregates.json").read_text())
    print(f"Writing {len(hourly)} hourly docs -> .../hourly/*  (batched)")
    batch = db.batch()
    for i, row in enumerate(hourly):
        doc_id = row["Time"].replace(":", "-")
        batch.set(station_ref.collection("hourly").document(doc_id), row)
        if (i + 1) % 400 == 0:  # Firestore batch limit is 500 writes
            batch.commit()
            batch = db.batch()
    batch.commit()

    daily = json.loads((data / "daily_summary.json").read_text())
    print(f"Writing {len(daily)} daily docs -> .../daily/*")
    batch = db.batch()
    for row in daily:
        doc_id = row["Time"][:10]
        batch.set(station_ref.collection("daily").document(doc_id), row)
    batch.commit()

    print("\nDone.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--data", default="./output")
    args = parser.parse_args()
    main(args.service_account, args.data)
