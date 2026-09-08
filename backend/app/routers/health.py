from datetime import UTC, datetime

from fastapi import APIRouter

from ..dependencies import GeoStoreDep

router = APIRouter(tags=["system"])


@router.get("/health")
async def health(geo: GeoStoreDep) -> dict:
    """Liveness plus a check that the seed data actually loaded.

    Returning 200 while the GeoJSON is missing would hide the most likely
    deployment mistake, so the seed count is part of the answer.
    """
    try:
        boundaries = len(geo.boundaries())
        zones = len(geo.fishing_zones())
        seed_ok = boundaries > 0 and zones > 0
    except FileNotFoundError:
        boundaries = zones = 0
        seed_ok = False

    return {
        "status": "ok" if seed_ok else "degraded",
        "seed_data": {"boundaries": boundaries, "fishing_zones": zones},
        "time": datetime.now(UTC),
    }
