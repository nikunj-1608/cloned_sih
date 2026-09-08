"""Spatial queries over the seeded GeoJSON.

Phase 2 reads flat files through Shapely so the API is not blocked on database
provisioning. Phase 6 replaces the internals with PostGIS queries; the method
signatures on `GeoStore` are the seam and should not need to change.
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

from shapely.geometry import Point, shape
from shapely.geometry.base import BaseGeometry

from ..config import get_settings

# One degree of latitude is ~111.32 km. Good enough to convert a search radius
# into a degree buffer at these latitudes; PostGIS does it properly in Phase 6.
_KM_PER_DEGREE = 111.32


class Feature:
    """A GeoJSON feature with its geometry parsed once, at load."""

    __slots__ = ("raw", "geometry", "properties")

    def __init__(self, raw: dict[str, Any]) -> None:
        self.raw = raw
        self.properties: dict[str, Any] = raw.get("properties", {})
        self.geometry: BaseGeometry = shape(raw["geometry"])

    @property
    def id(self) -> str:
        return str(self.properties.get("id", ""))

    @property
    def name(self) -> str:
        return str(self.properties.get("name", self.id))

    def distance_km(self, lat: float, lon: float) -> float:
        """Approximate distance from a point to this feature, in kilometres.

        Planar distance in degrees scaled to kilometres. Accurate to within a
        few percent over the tens of kilometres this app cares about, and the
        app does its own precise haversine on-device anyway — this figure is
        only used for ranking and for the conversational reply.
        """
        return self.geometry.distance(Point(lon, lat)) * _KM_PER_DEGREE

    def contains(self, lat: float, lon: float) -> bool:
        return bool(self.geometry.contains(Point(lon, lat)))


class GeoStore:
    def __init__(self, seed_dir: Path) -> None:
        self._seed_dir = seed_dir
        self._cache: dict[str, dict[str, Any]] = {}

    def _load(self, filename: str) -> dict[str, Any]:
        if filename not in self._cache:
            path = self._seed_dir / filename
            if not path.exists():
                raise FileNotFoundError(
                    f"Seed file missing: {path}. Run from the repo root, or see "
                    f"data/seed/ in the README."
                )
            self._cache[filename] = json.loads(path.read_text(encoding="utf-8"))
        return self._cache[filename]

    def boundaries_geojson(self, kinds: set[str] | None = None) -> dict[str, Any]:
        data = self._load("boundaries.geojson")
        if not kinds:
            return data
        return {
            **data,
            "features": [
                f for f in data["features"] if f["properties"].get("kind") in kinds
            ],
        }

    def pfz_geojson(self) -> dict[str, Any]:
        return self._load("pfz.geojson")

    def boundaries(self) -> list[Feature]:
        return [Feature(f) for f in self._load("boundaries.geojson")["features"]]

    def fishing_zones(self) -> list[Feature]:
        return [Feature(f) for f in self._load("pfz.geojson")["features"]]

    def nearest_boundary(self, lat: float, lon: float) -> tuple[Feature, float] | None:
        """The closest boundary feature and its distance, or None if none exist."""
        ranked = sorted(
            ((f, f.distance_km(lat, lon)) for f in self.boundaries()),
            key=lambda pair: pair[1],
        )
        return ranked[0] if ranked else None

    def zones_within(
        self, lat: float, lon: float, radius_km: float
    ) -> list[tuple[Feature, float]]:
        """Fishing zones within `radius_km`, nearest first."""
        hits = [
            (zone, distance)
            for zone in self.fishing_zones()
            if (distance := zone.distance_km(lat, lon)) <= radius_km
        ]
        return sorted(hits, key=lambda pair: pair[1])

    def containing_restricted_zone(self, lat: float, lon: float) -> Feature | None:
        """A restricted area the position currently sits inside, if any."""
        for feature in self.boundaries():
            if feature.geometry.geom_type in {"Polygon", "MultiPolygon"} and (
                feature.contains(lat, lon)
            ):
                return feature
        return None


@lru_cache
def get_geo_store() -> GeoStore:
    return GeoStore(get_settings().seed_dir)
