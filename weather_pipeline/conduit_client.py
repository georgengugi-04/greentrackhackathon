"""
GreenTrack Weather Intelligence — JHUB Conduit Live API Client
==================================================================
Talks to the official live weather-data source for this hackathon:

    POST https://conduit.jhubafrica.com/data.php
    apikey=<CONDUIT_API_KEY>
    email=<CONDUIT_EMAIL>
    fromdate=YYYY-MM-DD
    todate=YYYY-MM-DD

CREDENTIALS: never hard-code CONDUIT_API_KEY / CONDUIT_EMAIL. This module
only reads them from environment variables (or an explicit call
argument, for tests) — see .env.example at the project root for the
variable names. Nothing here writes a key to disk or logs it.

HONESTY NOTE: the exact shape of a real, authenticated Conduit response
(JSON object vs list, exact field names, error payload format) has not
been observed by this pipeline yet — only the request contract above was
supplied. This client is written defensively: it accepts a JSON list of
records, a JSON object wrapping a list under a common key (data/records/
results/rows), or CSV text, and routes whatever it gets through the same
schema.normalize() used for the CSV exports, using the alias table in
schema.py to catch reasonably-likely field-name variants. If a real
response uses field names outside that alias table, normalize() raises
a clear SchemaError naming the unrecognized columns rather than silently
mismapping data — treat that as a signal to extend SHORT_FORM_ALIASES,
not a bug in the caller.
"""
from __future__ import annotations
import json
import os
from dataclasses import dataclass

import pandas as pd

from schema import (
    load_dataframe_from_records,
    load_dataframe_from_csv_text,
    SchemaError,
)

CONDUIT_URL = "https://conduit.jhubafrica.com/data.php"
DEFAULT_TIMEOUT_SECONDS = 20


class ConduitError(Exception):
    """Base class for all Conduit API failures. Callers (the Flutter app,
    a cron job, this module's own CLI) should catch this specifically and
    fall back to cached/historical data rather than crashing — see
    section 17 (LIVE / HISTORICAL / OFFLINE) of the project's data spec."""


class ConduitAuthError(ConduitError):
    """Invalid API key or email."""


class ConduitEmptyResponseError(ConduitError):
    """Request succeeded but returned no observations for the range."""


class ConduitMalformedResponseError(ConduitError):
    """Response body could not be parsed as JSON or CSV at all."""


class ConduitNetworkError(ConduitError):
    """Timeout, DNS failure, connection refused, etc."""


@dataclass
class ConduitCredentials:
    api_key: str
    email: str

    @classmethod
    def from_env(cls) -> "ConduitCredentials":
        api_key = os.environ.get("CONDUIT_API_KEY", "")
        email = os.environ.get("CONDUIT_EMAIL", "")
        if not api_key or not email:
            raise ConduitAuthError(
                "CONDUIT_API_KEY and/or CONDUIT_EMAIL are not set in the "
                "environment. Copy .env.example to .env and fill them in, "
                "or export them before running this script. Never commit "
                "real credentials."
            )
        return cls(api_key=api_key, email=email)


def _extract_records(payload) -> list[dict]:
    """Accept a few reasonably-likely JSON shapes for the record list."""
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        for key in ("data", "records", "results", "rows", "observations"):
            if key in payload and isinstance(payload[key], list):
                return payload[key]
        # A single observation returned as one object.
        if any(k.lower() in ("ts", "time", "timestamp") for k in payload):
            return [payload]
    raise ConduitMalformedResponseError(
        f"Could not find a list of observations in the response payload "
        f"(top-level type: {type(payload).__name__})."
    )


def fetch_weather(
    fromdate: str,
    todate: str,
    credentials: ConduitCredentials | None = None,
    timeout: int = DEFAULT_TIMEOUT_SECONDS,
    session=None,
) -> pd.DataFrame:
    """Fetch and normalize weather observations from the live Conduit API
    for the inclusive [fromdate, todate] range (YYYY-MM-DD strings).
    Returns a canonical-schema DataFrame (see schema.py). Raises a
    ConduitError subclass on any failure — callers should catch
    ConduitError and fall back to cached/historical data rather than
    letting this propagate into the dashboard.

    `session` lets callers/tests inject a requests-like object; a real
    `requests` import is deferred into this function so environments
    without network access (or without the `requests` package) can still
    import this module and exercise everything else in the pipeline.
    """
    creds = credentials or ConduitCredentials.from_env()

    if session is None:
        try:
            import requests as _requests
        except ImportError as exc:
            raise ConduitError(
                "The 'requests' package is required to call the live "
                "Conduit API (pip install requests)."
            ) from exc
        session = _requests

    try:
        response = session.post(
            CONDUIT_URL,
            data={
                "apikey": creds.api_key,
                "email": creds.email,
                "fromdate": fromdate,
                "todate": todate,
            },
            timeout=timeout,
        )
    except Exception as exc:  # noqa: BLE001 - deliberately broad: any
        # transport-layer failure (timeout, DNS, connection reset, ...)
        # should become a ConduitNetworkError, not crash the caller.
        raise ConduitNetworkError(f"Could not reach the Conduit API: {exc}") from exc

    status = getattr(response, "status_code", None)
    if status in (401, 403):
        raise ConduitAuthError(
            f"Conduit API rejected the request (HTTP {status}) — check "
            "CONDUIT_API_KEY / CONDUIT_EMAIL."
        )
    if status is not None and status >= 400:
        raise ConduitError(f"Conduit API returned HTTP {status}: {getattr(response, 'text', '')[:300]}")

    text = response.text
    if text is None or not text.strip():
        raise ConduitEmptyResponseError(
            f"Conduit API returned an empty response for {fromdate}..{todate}."
        )

    df = None
    try:
        payload = json.loads(text)
    except (json.JSONDecodeError, ValueError):
        payload = None

    if payload is not None:
        try:
            records = _extract_records(payload)
        except ConduitMalformedResponseError:
            records = None
        if records is not None:
            if len(records) == 0:
                raise ConduitEmptyResponseError(
                    f"Conduit API returned 0 observations for {fromdate}..{todate}."
                )
            try:
                df = load_dataframe_from_records(records)
            except SchemaError as exc:
                raise ConduitMalformedResponseError(str(exc)) from exc

    if df is None:
        # Not valid/handled JSON — try CSV as a fallback shape.
        try:
            df = load_dataframe_from_csv_text(text)
        except SchemaError as exc:
            raise ConduitMalformedResponseError(str(exc)) from exc
        except Exception as exc:  # noqa: BLE001
            raise ConduitMalformedResponseError(
                f"Conduit response was neither valid JSON nor CSV: {exc}"
            ) from exc

    if df.empty:
        raise ConduitEmptyResponseError(
            f"Conduit API returned 0 observations for {fromdate}..{todate}."
        )

    # Parse timestamps here too (data_quality.validate() will re-parse
    # downstream, but we need real Timestamps now for the future-data
    # and dedup checks below).
    df["Time"] = pd.to_datetime(df["Time"], utc=True, errors="coerce")

    # Never trust future timestamps into "current" intelligence — matches
    # the existing feature-engineering guard against future-data leakage.
    now_utc = pd.Timestamp.now(tz="UTC")
    df = df[df["Time"] <= now_utc]

    # Deduplicate on timestamp (keep first) in case the API returns
    # overlapping pages/retries.
    df = df.dropna(subset=["Time"]).drop_duplicates(subset=["Time"], keep="first")
    df = df.sort_values("Time").reset_index(drop=True)

    if df.empty:
        raise ConduitEmptyResponseError(
            f"Conduit API returned only future-dated or duplicate rows for {fromdate}..{todate}."
        )

    return df
