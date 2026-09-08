from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Query

from ..dependencies import GeoStoreDep, WeatherDep
from ..schemas.common import GeoPoint
from ..schemas.geo import FeatureCollection
from ..schemas.marine import AdvisoryPack, MarineConditions

router = APIRouter(prefix="/v1", tags=["marine"])

# How long a downloaded pack is considered good for. Matches the app's staleness
# meter, which starts degrading confidence well before this expires.
PACK_VALIDITY = timedelta(hours=24)


@router.get("/marine/conditions", response_model=MarineConditions)
async def conditions(
    weather: WeatherDep,
    lat: float = Query(ge=-90, le=90),
    lon: float = Query(ge=-180, le=180),
) -> MarineConditions:
    """Live sea state for one position.

    Never fails: if the upstream is unreachable the response comes back flagged
    `freshness="unavailable"` with a `severity` of `info`, and the app falls
    back to its cached pack.
    """
    return await weather.fetch_conditions(lat, lon)


@router.get("/advisory-pack", response_model=AdvisoryPack)
async def advisory_pack(
    weather: WeatherDep,
    geo: GeoStoreDep,
    lat: float = Query(ge=-90, le=90),
    lon: float = Query(ge=-180, le=180),
) -> AdvisoryPack:
    """Everything needed for a trip with no network, in one request.

    Downloaded at port and written to `sqflite`. One call rather than four
    because it is issued over a marginal harbour connection, often while the
    boat is already casting off.
    """
    now = datetime.now(UTC)
    return AdvisoryPack(
        generated_at=now,
        valid_until=now + PACK_VALIDITY,
        centre=GeoPoint(lat=lat, lon=lon),
        conditions=await weather.fetch_conditions(lat, lon),
        boundaries=FeatureCollection(**geo.boundaries_geojson()),
        fishing_zones=FeatureCollection(**geo.pfz_geojson()),
        note=(
            "Seeded development data. Boundaries are not survey-accurate and "
            "must not be used for navigation."
        ),
    )
