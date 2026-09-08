from fastapi import APIRouter, Query

from ..dependencies import GeoStoreDep
from ..schemas.geo import FeatureCollection

router = APIRouter(prefix="/v1", tags=["geospatial"])


@router.get("/boundaries", response_model=FeatureCollection)
async def boundaries(
    geo: GeoStoreDep,
    kinds: str = Query(
        default="imbl,mpa",
        description="Comma-separated feature kinds to include.",
    ),
) -> dict:
    """Maritime boundaries and restricted areas as GeoJSON.

    The app downloads this once at port and caches it; at sea it is the only
    boundary source there is.
    """
    wanted = {k.strip() for k in kinds.split(",") if k.strip()}
    return geo.boundaries_geojson(wanted)


@router.get("/pfz", response_model=FeatureCollection)
async def potential_fishing_zones(
    geo: GeoStoreDep,
    lat: float | None = Query(default=None, ge=-90, le=90),
    lon: float | None = Query(default=None, ge=-180, le=180),
    radius_km: float = Query(default=100, gt=0, le=500),
) -> dict:
    """Potential Fishing Zones, optionally filtered to a radius around a point."""
    if lat is None or lon is None:
        return geo.pfz_geojson()

    nearby = geo.zones_within(lat, lon, radius_km)
    return {
        **geo.pfz_geojson(),
        "features": [zone.raw for zone, _ in nearby],
    }
