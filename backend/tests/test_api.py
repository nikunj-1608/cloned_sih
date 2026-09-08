"""Endpoint contract tests.

Network is stubbed with `respx` throughout. A test suite that reaches the real
Open-Meteo would be flaky at a venue and slow in CI, and would not tell us what
we most need to know: that the API degrades correctly when the upstream is gone.
"""

import httpx
import respx

from app.schemas.chat import Engine, Intent
from app.schemas.common import Freshness, Severity

RAMESWARAM = {"lat": 9.2876, "lon": 79.3129}

_MARINE_OK = {
    "hourly": {
        "time": [f"2026-09-08T{h:02d}:00" for h in range(24)],
        "wave_height": [0.8] * 24,
        "swell_wave_period": [7.0] * 24,
        "sea_surface_temperature": [28.4] * 24,
    }
}
_WEATHER_OK = {
    "hourly": {
        "time": [f"2026-09-08T{h:02d}:00" for h in range(24)],
        "wind_speed_10m": [12.0] * 24,
        "wind_direction_10m": [230.0] * 24,
    }
}


def _mock_upstream(marine=_MARINE_OK, weather=_WEATHER_OK):
    respx.get(url__startswith="https://marine-api.open-meteo.com").mock(
        return_value=httpx.Response(200, json=marine)
    )
    respx.get(url__startswith="https://api.open-meteo.com").mock(
        return_value=httpx.Response(200, json=weather)
    )


class TestHealth:
    def test_reports_ok_with_seed_data_loaded(self, client):
        body = client.get("/health").json()
        assert body["status"] == "ok"
        assert body["seed_data"]["boundaries"] == 2
        assert body["seed_data"]["fishing_zones"] == 2


class TestGeospatial:
    def test_boundaries_returns_geojson(self, client):
        body = client.get("/v1/boundaries").json()
        assert body["type"] == "FeatureCollection"
        assert len(body["features"]) == 2

    def test_boundaries_filters_by_kind(self, client):
        body = client.get("/v1/boundaries", params={"kinds": "imbl"}).json()
        assert [f["properties"]["kind"] for f in body["features"]] == ["imbl"]

    def test_pfz_radius_excludes_distant_zones(self, client):
        near = client.get("/v1/pfz", params={**RAMESWARAM, "radius_km": 100})
        far = client.get("/v1/pfz", params={**RAMESWARAM, "radius_km": 5})
        assert len(near.json()["features"]) == 2
        assert far.json()["features"] == []

    def test_rejects_out_of_range_coordinates(self, client):
        assert client.get("/v1/pfz", params={"lat": 200, "lon": 0}).status_code == 422


class TestMarineConditions:
    @respx.mock
    def test_classifies_calm_sea_as_safe(self, client):
        _mock_upstream()
        body = client.get("/v1/marine/conditions", params=RAMESWARAM).json()
        assert body["severity"] == Severity.SAFE
        assert body["wave_height_m"] == 0.8
        assert body["wind_speed_kmh"] == 12.0
        assert body["freshness"] == Freshness.LIVE
        assert body["summary_ta"]

    @respx.mock
    def test_classifies_rough_sea_as_danger(self, client):
        _mock_upstream(
            marine={
                "hourly": {"wave_height": [3.2] * 24, "swell_wave_period": [11.0] * 24}
            },
            weather={
                "hourly": {
                    "wind_speed_10m": [60.0] * 24,
                    "wind_direction_10m": [200.0] * 24,
                }
            },
        )
        body = client.get("/v1/marine/conditions", params=RAMESWARAM).json()
        assert body["severity"] == Severity.DANGER
        assert "Do not go out" in body["summary"]

    @respx.mock
    def test_degrades_instead_of_failing_when_upstream_is_down(self, client):
        """The single most important behaviour in this file.

        A boat with no network must get an honest, flagged answer — never a 500
        and never a hang.
        """
        respx.get(url__startswith="https://marine-api.open-meteo.com").mock(
            side_effect=httpx.ConnectError("no network")
        )
        respx.get(url__startswith="https://api.open-meteo.com").mock(
            side_effect=httpx.ConnectError("no network")
        )

        response = client.get("/v1/marine/conditions", params=RAMESWARAM)
        assert response.status_code == 200

        body = response.json()
        assert body["freshness"] == Freshness.UNAVAILABLE
        assert body["severity"] == Severity.INFO
        assert body["wave_height_m"] is None
        assert all(e["freshness"] == Freshness.UNAVAILABLE for e in body["evidence"])

    @respx.mock
    def test_survives_partial_upstream_failure(self, client):
        """Marine down, weather up. Still a usable answer."""
        respx.get(url__startswith="https://marine-api.open-meteo.com").mock(
            side_effect=httpx.TimeoutException("slow")
        )
        respx.get(url__startswith="https://api.open-meteo.com").mock(
            return_value=httpx.Response(200, json=_WEATHER_OK)
        )
        body = client.get("/v1/marine/conditions", params=RAMESWARAM).json()
        assert body["wave_height_m"] is None
        assert body["wind_speed_kmh"] == 12.0
        assert body["freshness"] == Freshness.LIVE


class TestAdvisoryPack:
    @respx.mock
    def test_bundles_everything_needed_offline(self, client):
        _mock_upstream()
        body = client.get("/v1/advisory-pack", params=RAMESWARAM).json()
        assert body["valid_until"] > body["generated_at"]
        assert len(body["boundaries"]["features"]) == 2
        assert len(body["fishing_zones"]["features"]) == 2
        assert body["conditions"]["severity"] == Severity.SAFE
        assert "not be used for navigation" in body["note"]


class TestChat:
    @respx.mock
    def _ask(self, client, message, **kwargs):
        _mock_upstream()
        payload = {"message": message, "position": RAMESWARAM, **kwargs}
        response = client.post("/v1/chat", json=payload)
        assert response.status_code == 200
        return response.json()

    @respx.mock
    def test_find_fish_returns_zones_as_map_layers(self, client):
        body = self._ask(client, "Where can I find fish today?")
        assert body["intent"] == Intent.FIND_FISH
        assert len(body["map_layers"]) == 2
        assert body["map_layers"][0]["style"] == "fishing"
        assert body["evidence"]

    @respx.mock
    def test_boundary_query_reports_distance(self, client):
        body = self._ask(client, "How far is the border?")
        assert body["intent"] == Intent.BOUNDARY
        assert "km" in body["reply"]
        assert body["map_layers"][0]["style"] == "boundary"

    @respx.mock
    def test_safety_query_uses_live_weather(self, client):
        body = self._ask(client, "Is it safe to go out tomorrow?")
        assert body["intent"] == Intent.TRIP_SAFETY
        assert body["severity"] == Severity.SAFE
        assert any("Open-Meteo" in e["source"] for e in body["evidence"])

    @respx.mock
    def test_tamil_query_routes_correctly(self, client):
        body = self._ask(client, "இன்று மீன் எங்கே கிடைக்கும்?")
        assert body["intent"] == Intent.FIND_FISH

    @respx.mock
    def test_unknown_query_offers_guidance_rather_than_guessing(self, client):
        body = self._ask(client, "what is the capital of france")
        assert body["intent"] == Intent.UNKNOWN
        assert body["severity"] == Severity.INFO
        assert body["map_layers"] == []

    @respx.mock
    def test_every_answer_carries_a_reasoning_trace(self, client):
        body = self._ask(client, "Is it safe to go out?")
        assert len(body["agent_trace"]) >= 2
        assert body["agent_trace"][0]["agent"] == "Supervisor"
        assert {"agent", "action", "result", "duration_ms"} <= set(
            body["agent_trace"][0]
        )

    @respx.mock
    def test_declares_which_engine_answered(self, client):
        """The demo must never imply autonomy that did not run."""
        assert self._ask(client, "weather?")["engine"] == Engine.RULES

    @respx.mock
    def test_works_without_a_position(self, client):
        _mock_upstream()
        response = client.post("/v1/chat", json={"message": "where are the fish"})
        assert response.status_code == 200
        assert response.json()["intent"] == Intent.FIND_FISH

    def test_rejects_an_empty_message(self, client):
        assert client.post("/v1/chat", json={"message": ""}).status_code == 422
