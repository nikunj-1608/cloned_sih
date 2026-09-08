"""GeoJSON pass-through models.

Deliberately loose: the seed files are already valid GeoJSON and the app hands
them straight to `flutter_map`. Validating every coordinate here would buy
nothing and would break the moment a real dataset carries an extra property.
"""

from typing import Any, Literal

from pydantic import BaseModel, Field


class FeatureCollection(BaseModel):
    type: Literal["FeatureCollection"] = "FeatureCollection"
    features: list[dict[str, Any]] = Field(default_factory=list)
    note: str | None = None


class MapLayer(BaseModel):
    """A GeoJSON layer an answer wants drawn on the map."""

    id: str
    label: str
    label_ta: str | None = None
    style: Literal["boundary", "restricted", "fishing", "route", "marker"]
    geojson: dict[str, Any]
