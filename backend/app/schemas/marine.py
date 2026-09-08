"""Marine conditions and the offline advisory pack."""

from datetime import datetime

from pydantic import BaseModel, Field

from .common import Evidence, Freshness, GeoPoint, Severity
from .geo import FeatureCollection


class MarineConditions(BaseModel):
    """Normalized sea state for one position.

    Upstream units vary; everything here is metric and named, so the app never
    has to know which provider a number came from.
    """

    position: GeoPoint
    observed_at: datetime
    wave_height_m: float | None = None
    swell_period_s: float | None = None
    wind_speed_kmh: float | None = None
    wind_direction_deg: float | None = None
    sea_surface_temp_c: float | None = None
    freshness: Freshness = Freshness.LIVE

    severity: Severity
    summary: str
    summary_ta: str | None = None
    evidence: list[Evidence] = Field(default_factory=list)


class AdvisoryPack(BaseModel):
    """Everything the app needs to survive a trip with no network.

    Downloaded in one request at port and written to `sqflite`. `valid_until`
    is what drives the staleness meter on the home screen.
    """

    generated_at: datetime
    valid_until: datetime
    centre: GeoPoint
    conditions: MarineConditions
    boundaries: FeatureCollection
    fishing_zones: FeatureCollection
    note: str
