"""Shared response primitives."""

from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, Field


class Severity(StrEnum):
    """Mirrors `SafetyLevel` in the Flutter app. Keep the two in step."""

    SAFE = "safe"
    CAUTION = "caution"
    DANGER = "danger"
    INFO = "info"


class Freshness(StrEnum):
    """How much an answer should be trusted given the age of its inputs.

    The app renders this directly — a stale forecast looks different from a live
    one. See the evidence-ledger USP in `Tasks.md`.
    """

    LIVE = "live"
    RECENT = "recent"
    STALE = "stale"
    UNAVAILABLE = "unavailable"


class Evidence(BaseModel):
    """One source that contributed to an answer.

    The problem statement asks four separate times for explainable,
    evidence-backed recommendations. Every answer carries these.
    """

    source: str = Field(description="Human-readable dataset name.")
    detail: str = Field(description="What this source actually said.")
    observed_at: datetime | None = None
    freshness: Freshness = Freshness.LIVE


class GeoPoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
