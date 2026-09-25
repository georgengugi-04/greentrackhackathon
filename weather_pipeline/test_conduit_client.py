"""
Tests for conduit_client.py. Uses a fake `session` object (matching the
tiny subset of the `requests` API this module actually calls) so these
tests run with no network access and without needing real credentials —
per spec section 27's API-failure test list.
"""
import json
import pytest
from conduit_client import (
    fetch_weather,
    ConduitCredentials,
    ConduitAuthError,
    ConduitEmptyResponseError,
    ConduitMalformedResponseError,
    ConduitNetworkError,
)

CREDS = ConduitCredentials(api_key="test-key", email="test@example.com")


class FakeResponse:
    def __init__(self, status_code=200, text=""):
        self.status_code = status_code
        self.text = text


class FakeSession:
    """Records the last request made and returns a pre-set response, or
    raises a pre-set exception (to simulate network failures)."""
    def __init__(self, response=None, raise_exc=None):
        self._response = response
        self._raise_exc = raise_exc
        self.last_call = None

    def post(self, url, data=None, timeout=None):
        self.last_call = {"url": url, "data": data, "timeout": timeout}
        if self._raise_exc:
            raise self._raise_exc
        return self._response


def _valid_records_json():
    return json.dumps([
        {"ts": "2026-08-14T00:00:00Z", "temp_sht": 15.0, "humidity_sht": 70.0, "rg2tt": 0.2},
        {"ts": "2026-08-14T00:15:00Z", "temp_sht": 15.2, "humidity_sht": 71.0, "rg2tt": 0.4},
    ])


def test_successful_fetch_returns_canonical_dataframe():
    session = FakeSession(response=FakeResponse(200, _valid_records_json()))
    df = fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)
    assert len(df) == 2
    assert "SHT Temperature" in df.columns
    assert session.last_call["data"]["apikey"] == "test-key"
    assert session.last_call["data"]["email"] == "test@example.com"
    assert session.last_call["data"]["fromdate"] == "2026-08-14"


def test_wrapped_object_payload_with_data_key():
    payload = json.dumps({"data": json.loads(_valid_records_json())})
    session = FakeSession(response=FakeResponse(200, payload))
    df = fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)
    assert len(df) == 2


def test_invalid_api_key_raises_auth_error():
    session = FakeSession(response=FakeResponse(401, "unauthorized"))
    with pytest.raises(ConduitAuthError):
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)


def test_empty_date_range_raises_empty_response_error():
    session = FakeSession(response=FakeResponse(200, json.dumps([])))
    with pytest.raises(ConduitEmptyResponseError):
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)


def test_blank_body_raises_empty_response_error():
    session = FakeSession(response=FakeResponse(200, "   "))
    with pytest.raises(ConduitEmptyResponseError):
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)


def test_malformed_response_raises():
    session = FakeSession(response=FakeResponse(200, "{not valid json or csv!!"))
    with pytest.raises(ConduitMalformedResponseError):
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)


def test_network_timeout_raises_network_error():
    session = FakeSession(raise_exc=TimeoutError("timed out"))
    with pytest.raises(ConduitNetworkError):
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)


def test_server_error_raises_conduit_error_not_auth_error():
    from conduit_client import ConduitError
    session = FakeSession(response=FakeResponse(500, "internal error"))
    with pytest.raises(ConduitError) as exc_info:
        fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)
    assert not isinstance(exc_info.value, ConduitAuthError)


def test_duplicate_observations_are_deduplicated():
    dup_json = json.dumps([
        {"ts": "2026-08-14T00:00:00Z", "temp_sht": 15.0, "humidity_sht": 70.0},
        {"ts": "2026-08-14T00:00:00Z", "temp_sht": 15.0, "humidity_sht": 70.0},
        {"ts": "2026-08-14T00:15:00Z", "temp_sht": 15.2, "humidity_sht": 71.0},
    ])
    session = FakeSession(response=FakeResponse(200, dup_json))
    df = fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)
    assert len(df) == 2


def test_future_timestamps_are_excluded():
    future_json = json.dumps([
        {"ts": "2026-08-14T00:00:00Z", "temp_sht": 15.0, "humidity_sht": 70.0},
        {"ts": "2099-01-01T00:00:00Z", "temp_sht": 99.0, "humidity_sht": 99.0},
    ])
    session = FakeSession(response=FakeResponse(200, future_json))
    df = fetch_weather("2026-08-14", "2026-08-14", credentials=CREDS, session=session)
    assert len(df) == 1
    assert df.iloc[0]["SHT Temperature"] == 15.0


def test_missing_credentials_raise_auth_error():
    import os
    old_key = os.environ.pop("CONDUIT_API_KEY", None)
    old_email = os.environ.pop("CONDUIT_EMAIL", None)
    try:
        with pytest.raises(ConduitAuthError):
            ConduitCredentials.from_env()
    finally:
        if old_key is not None:
            os.environ["CONDUIT_API_KEY"] = old_key
        if old_email is not None:
            os.environ["CONDUIT_EMAIL"] = old_email
