"""Open-Meteo Marine client.

No API key required, which is why it is the backbone of the demo rather than
INCOIS (see blocker #1 in `PROJECT_STATE.md`).

Every call here can fail, and at a hackathon venue it probably will. The
contract is that `fetch_conditions` never raises and never hangs: on any
failure it returns a degraded result flagged `Freshness.UNAVAILABLE`, and the
caller decides what to tell the user. A boat at sea gets a cached answer with
an honest age on it, not a spinner.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime

import httpx

from ..config import Settings
from ..schemas.common import Evidence, Freshness, GeoPoint, Severity
from ..schemas.marine import MarineConditions

logger = logging.getLogger(__name__)

_MARINE_FIELDS = "wave_height,swell_wave_period,sea_surface_temperature"
_WEATHER_FIELDS = "wind_speed_10m,wind_direction_10m"


def _first(values: list | None) -> float | None:
    """The current hour's value: Open-Meteo returns the day from hour zero."""
    if not values:
        return None
    hour = datetime.now(UTC).hour
    index = hour if hour < len(values) else 0
    value = values[index]
    return float(value) if value is not None else None


def classify(wave_height_m: float | None, wind_speed_kmh: float | None) -> Severity:
    """Sea state to a go / no-go verdict.

    Thresholds follow INCOIS small-craft advisory practice for the Indian coast:
    country boats are warned off above roughly 2 m of wave height or 45 km/h of
    wind. They are conservative on purpose and belong in a config file once a
    domain expert has reviewed them.
    """
    if wave_height_m is None and wind_speed_kmh is None:
        return Severity.INFO
    if (wave_height_m or 0) >= 2.5 or (wind_speed_kmh or 0) >= 55:
        return Severity.DANGER
    if (wave_height_m or 0) >= 1.5 or (wind_speed_kmh or 0) >= 35:
        return Severity.CAUTION
    return Severity.SAFE


def _summarise(severity: Severity, wave: float | None, wind: float | None) -> str:
    if severity is Severity.INFO:
        return (
            "Live sea data could not be reached. Use the last saved advisory and "
            "your own judgement."
        )
    wave_text = f"{wave:.1f} m waves" if wave is not None else "unknown wave height"
    wind_text = f"{wind:.0f} km/h wind" if wind is not None else "unknown wind"
    if severity is Severity.DANGER:
        return f"Rough sea — {wave_text} and {wind_text}. Do not go out."
    if severity is Severity.CAUTION:
        return f"Choppy — {wave_text} and {wind_text}. Go only if you must."
    return f"Calm — {wave_text} and {wind_text}. Good conditions."


_SUMMARY_TA = {
    Severity.SAFE: "கடல் அமைதியாக உள்ளது. செல்லலாம்.",
    Severity.CAUTION: "கடல் சற்று கொந்தளிப்பாக உள்ளது. கவனமாக இருங்கள்.",
    Severity.DANGER: "கடல் மிகவும் கொந்தளிப்பாக உள்ளது. செல்ல வேண்டாம்.",
    Severity.INFO: "தரவு கிடைக்கவில்லை. கவனமாக இருங்கள்.",
}


class OpenMeteoClient:
    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None):
        self._settings = settings
        self._client = client

    async def _get(self, url: str, params: dict) -> dict | None:
        timeout = self._settings.upstream_timeout_seconds
        try:
            if self._client is not None:
                response = await self._client.get(url, params=params, timeout=timeout)
            else:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except (httpx.HTTPError, ValueError) as exc:
            # Degrade, never propagate. The caller has a fallback path.
            logger.warning("Open-Meteo call failed for %s: %s", url, exc)
            return None

    async def fetch_conditions(self, lat: float, lon: float) -> MarineConditions:
        marine = await self._get(
            self._settings.open_meteo_marine_url,
            {
                "latitude": lat,
                "longitude": lon,
                "hourly": _MARINE_FIELDS,
                "forecast_days": 1,
            },
        )
        weather = await self._get(
            self._settings.open_meteo_forecast_url,
            {
                "latitude": lat,
                "longitude": lon,
                "hourly": _WEATHER_FIELDS,
                "forecast_days": 1,
            },
        )

        marine_hourly = (marine or {}).get("hourly", {})
        weather_hourly = (weather or {}).get("hourly", {})

        wave = _first(marine_hourly.get("wave_height"))
        swell = _first(marine_hourly.get("swell_wave_period"))
        sst = _first(marine_hourly.get("sea_surface_temperature"))
        wind = _first(weather_hourly.get("wind_speed_10m"))
        wind_dir = _first(weather_hourly.get("wind_direction_10m"))

        reached = marine is not None or weather is not None
        freshness = Freshness.LIVE if reached else Freshness.UNAVAILABLE
        severity = classify(wave, wind) if reached else Severity.INFO
        now = datetime.now(UTC)

        evidence = [
            Evidence(
                source="Open-Meteo Marine",
                detail=(
                    f"Wave height {wave:.1f} m, swell period {swell:.0f} s"
                    if wave is not None and swell is not None
                    else "Marine forecast unavailable"
                ),
                observed_at=now if marine else None,
                freshness=Freshness.LIVE if marine else Freshness.UNAVAILABLE,
            ),
            Evidence(
                source="Open-Meteo Forecast",
                detail=(
                    f"Wind {wind:.0f} km/h from {wind_dir:.0f}°"
                    if wind is not None and wind_dir is not None
                    else "Wind forecast unavailable"
                ),
                observed_at=now if weather else None,
                freshness=Freshness.LIVE if weather else Freshness.UNAVAILABLE,
            ),
        ]

        return MarineConditions(
            position=GeoPoint(lat=lat, lon=lon),
            observed_at=now,
            wave_height_m=wave,
            swell_period_s=swell,
            wind_speed_kmh=wind,
            wind_direction_deg=wind_dir,
            sea_surface_temp_c=sst,
            freshness=freshness,
            severity=severity,
            summary=_summarise(severity, wave, wind),
            summary_ta=_SUMMARY_TA[severity],
            evidence=evidence,
        )
