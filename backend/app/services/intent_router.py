"""Deterministic stand-in for the agent swarm.

> [!IMPORTANT]
> This exists so the frontend can integrate against the real `/v1/chat` schema
> before LangGraph is ready. It classifies by keyword and calls the same tools
> the agents will call. In Phase 4 this module is replaced wholesale; nothing
> outside it should need to change.
>
> It reports `engine="rules"` on every response, so a demo can never imply
> autonomy that did not run.
"""

from __future__ import annotations

import time
from datetime import UTC, datetime

from ..schemas.chat import (
    AgentStep,
    ChatRequest,
    ChatResponse,
    Engine,
    Intent,
)
from ..schemas.common import Evidence, Freshness, Severity
from ..schemas.geo import MapLayer
from .geo_store import GeoStore
from .open_meteo import OpenMeteoClient

# Rameswaram harbour — the pilot region's home port, used when the caller sends
# no position (a query typed at the jetty rather than at sea).
DEFAULT_LAT, DEFAULT_LON = 9.2876, 79.3129

# Keyword sets in English and Tamil. Order matters: the first intent whose
# keywords appear wins, so the more specific intents are listed first.
_KEYWORDS: list[tuple[Intent, tuple[str, ...]]] = [
    (
        Intent.BOUNDARY,
        (
            "boundary",
            "border",
            "imbl",
            "line",
            "restricted",
            "arrest",
            "எல்லை",
            "கடல் எல்லை",
        ),
    ),
    (
        Intent.ROUTE_HOME,
        (
            "route",
            "back to port",
            "go home",
            "harbour",
            "harbor",
            "return",
            "வழி",
            "துறைமுகம்",
            "திரும்ப",
        ),
    ),
    (
        Intent.FIND_FISH,
        (
            "fish",
            "pfz",
            "catch",
            "shoal",
            "fishing zone",
            "மீன்",
            "மீன்பிடி",
        ),
    ),
    (
        Intent.TRIP_SAFETY,
        (
            "safe",
            "should i go",
            "can i go",
            "venture",
            "risky",
            "danger",
            "பாதுகாப்ப",
            "செல்லலாமா",
        ),
    ),
    (
        Intent.WEATHER,
        (
            "weather",
            "wave",
            "wind",
            "rain",
            "storm",
            "cyclone",
            "sea condition",
            "வானிலை",
            "அலை",
            "காற்று",
            "புயல்",
        ),
    ),
]


def classify_intent(message: str) -> Intent:
    lowered = message.lower()
    for intent, keywords in _KEYWORDS:
        if any(keyword in lowered for keyword in keywords):
            return intent
    return Intent.UNKNOWN


class _Trace:
    """Collects reasoning steps with real timings."""

    def __init__(self) -> None:
        self._steps: list[AgentStep] = []

    def step(self, agent: str, action: str, result: str, started: float) -> None:
        self._steps.append(
            AgentStep(
                agent=agent,
                action=action,
                result=result,
                duration_ms=int((time.perf_counter() - started) * 1000),
            )
        )

    @property
    def steps(self) -> list[AgentStep]:
        return self._steps


class IntentRouter:
    def __init__(self, geo_store: GeoStore, weather: OpenMeteoClient) -> None:
        self._geo = geo_store
        self._weather = weather

    async def handle(self, request: ChatRequest) -> ChatResponse:
        lat = request.position.lat if request.position else DEFAULT_LAT
        lon = request.position.lon if request.position else DEFAULT_LON

        trace = _Trace()
        started = time.perf_counter()
        intent = classify_intent(request.message)
        trace.step(
            "Supervisor", "classify_intent", f"Routed to {intent.value}", started
        )

        handlers = {
            Intent.FIND_FISH: self._find_fish,
            Intent.TRIP_SAFETY: self._trip_safety,
            Intent.WEATHER: self._weather_report,
            Intent.BOUNDARY: self._boundary,
            Intent.ROUTE_HOME: self._route_home,
        }
        handler = handlers.get(intent, self._unknown)
        reply, reply_ta, severity, evidence, layers = await handler(lat, lon, trace)

        return ChatResponse(
            reply=reply,
            reply_ta=reply_ta,
            intent=intent,
            severity=severity,
            evidence=evidence,
            map_layers=layers,
            agent_trace=trace.steps,
            engine=Engine.RULES,
            generated_at=datetime.now(UTC),
        )

    # --- handlers --------------------------------------------------------
    # Each returns (reply, reply_ta, severity, evidence, map_layers) and each
    # maps to a specialist agent in Phase 4.

    async def _find_fish(self, lat, lon, trace):
        started = time.perf_counter()
        zones = self._geo.zones_within(lat, lon, radius_km=80)
        trace.step(
            "OceanAnalytics",
            "query_pfz(radius_km=80)",
            f"{len(zones)} zone(s) found",
            started,
        )

        if not zones:
            return (
                "No fishing zone advisory covers your area today.",
                "இன்று உங்கள் பகுதிக்கு மீன்பிடி அறிவிப்பு இல்லை.",
                Severity.INFO,
                [],
                [],
            )

        nearest, distance = zones[0]
        confidence = nearest.properties.get("confidence", "unknown")
        reply = (
            f"{nearest.name} is your closest fishing zone, about "
            f"{distance:.0f} km away. Confidence is {confidence}. Sea surface "
            f"temperature there is {nearest.properties.get('sst_c')}°C with "
            f"chlorophyll at {nearest.properties.get('chlorophyll_mg_m3')} mg/m³."
        )
        evidence = [
            Evidence(
                source="INCOIS PFZ advisory (seeded)",
                detail=f"{nearest.name}, confidence {confidence}",
                observed_at=datetime.now(UTC),
                freshness=Freshness.RECENT,
            )
        ]
        layers = [
            MapLayer(
                id=zone.id,
                label=zone.name,
                label_ta="மீன்பிடி மண்டலம்",
                style="fishing",
                geojson=zone.raw,
            )
            for zone, _ in zones
        ]
        return (
            reply,
            "அருகில் உள்ள மீன்பிடி மண்டலம் காட்டப்பட்டுள்ளது.",
            Severity.SAFE,
            evidence,
            layers,
        )

    async def _trip_safety(self, lat, lon, trace):
        started = time.perf_counter()
        conditions = await self._weather.fetch_conditions(lat, lon)
        trace.step(
            "WeatherIntelligence",
            "get_marine_conditions",
            conditions.summary,
            started,
        )

        started = time.perf_counter()
        nearest = self._geo.nearest_boundary(lat, lon)
        boundary_note = ""
        if nearest:
            feature, distance = nearest
            trace.step(
                "GeospatialReasoning",
                "nearest_boundary",
                f"{feature.name} at {distance:.1f} km",
                started,
            )
            if distance < 10:
                boundary_note = (
                    f" Stay alert — {feature.name} is only {distance:.0f} km away."
                )

        return (
            conditions.summary + boundary_note,
            conditions.summary_ta,
            conditions.severity,
            conditions.evidence,
            [],
        )

    async def _weather_report(self, lat, lon, trace):
        started = time.perf_counter()
        conditions = await self._weather.fetch_conditions(lat, lon)
        trace.step(
            "WeatherIntelligence",
            "get_marine_conditions",
            conditions.summary,
            started,
        )
        return (
            conditions.summary,
            conditions.summary_ta,
            conditions.severity,
            conditions.evidence,
            [],
        )

    async def _boundary(self, lat, lon, trace):
        started = time.perf_counter()
        inside = self._geo.containing_restricted_zone(lat, lon)
        if inside:
            trace.step(
                "GeospatialReasoning",
                "point_in_polygon",
                f"Inside {inside.name}",
                started,
            )
            return (
                f"You are inside {inside.name}. "
                f"{inside.properties.get('advice', 'Leave the area immediately.')}",
                inside.properties.get("advice_ta"),
                Severity.DANGER,
                [
                    Evidence(
                        source="Restricted area boundaries (seeded)",
                        detail=inside.name,
                        observed_at=datetime.now(UTC),
                        freshness=Freshness.RECENT,
                    )
                ],
                [
                    MapLayer(
                        id=inside.id,
                        label=inside.name,
                        label_ta=inside.properties.get("name_ta"),
                        style="restricted",
                        geojson=inside.raw,
                    )
                ],
            )

        nearest = self._geo.nearest_boundary(lat, lon)
        if not nearest:
            return (
                "No boundary data is loaded.",
                "எல்லைத் தரவு ஏற்றப்படவில்லை.",
                Severity.INFO,
                [],
                [],
            )

        feature, distance = nearest
        trace.step(
            "GeospatialReasoning",
            "nearest_boundary",
            f"{feature.name} at {distance:.1f} km",
            started,
        )
        severity = (
            Severity.DANGER
            if distance < 5
            else Severity.CAUTION
            if distance < 15
            else Severity.SAFE
        )
        return (
            f"{feature.name} is about {distance:.0f} km from you. "
            f"{feature.properties.get('advice', '')}".strip(),
            f"எல்லை சுமார் {distance:.0f} கி.மீ தொலைவில் உள்ளது.",
            severity,
            [
                Evidence(
                    source="Maritime boundaries (seeded)",
                    detail=f"{feature.name}, {distance:.1f} km",
                    observed_at=datetime.now(UTC),
                    freshness=Freshness.RECENT,
                )
            ],
            [
                MapLayer(
                    id=feature.id,
                    label=feature.name,
                    label_ta=feature.properties.get("name_ta"),
                    style="boundary",
                    geojson=feature.raw,
                )
            ],
        )

    async def _route_home(self, lat, lon, trace):
        started = time.perf_counter()
        conditions = await self._weather.fetch_conditions(lat, lon)
        trace.step(
            "WeatherIntelligence", "get_marine_conditions", conditions.summary, started
        )

        # Honest placeholder. Real routing is Phase 7 — saying so is better than
        # drawing a line that looks authoritative and is not.
        started = time.perf_counter()
        bearing = "west" if lon > DEFAULT_LON else "east"
        trace.step(
            "RouteOptimization",
            "not_implemented",
            "Straight-line guidance only; routing lands in Phase 7",
            started,
        )
        return (
            f"Head {bearing} toward Rameswaram harbour. {conditions.summary} "
            "Optimised routing is not available yet — steer by your own chart.",
            "துறைமுகம் நோக்கிச் செல்லுங்கள்.",
            conditions.severity,
            conditions.evidence,
            [],
        )

    async def _unknown(self, lat, lon, trace):
        return (
            "I can help with fishing zones, sea safety, weather, and how close "
            "you are to a maritime boundary. Try asking one of those.",
            "மீன்பிடி மண்டலம், கடல் பாதுகாப்பு, வானிலை மற்றும் எல்லை பற்றி கேட்கலாம்.",
            Severity.INFO,
            [],
            [],
        )
