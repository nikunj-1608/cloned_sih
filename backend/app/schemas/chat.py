"""The `/v1/chat` contract.

> [!IMPORTANT]
> This schema is the interface between three people's work. Phase 2 fills it
> from a deterministic keyword router; Phase 4 fills it from the LangGraph
> swarm. The frontend must not need to change when that swap happens, so treat
> any edit here as a breaking change and say so in the PR.
"""

from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel, Field

from .common import Evidence, GeoPoint, Severity
from .geo import MapLayer


class Intent(StrEnum):
    FIND_FISH = "find_fish"
    TRIP_SAFETY = "trip_safety"
    WEATHER = "weather"
    BOUNDARY = "boundary"
    ROUTE_HOME = "route_home"
    UNKNOWN = "unknown"


class Engine(StrEnum):
    """Which brain produced the answer.

    Surfaced so a demo never implies more autonomy than actually ran. The app
    shows a different badge for each.
    """

    RULES = "rules"
    LANGGRAPH = "langgraph"


class AgentStep(BaseModel):
    """One step of the reasoning trace.

    Rendered in the app's expandable trace panel. In Phase 2 these describe the
    deterministic router honestly; in Phase 4 they come from LangGraph.
    """

    agent: str
    action: str
    result: str
    duration_ms: int = 0


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    position: GeoPoint | None = None
    language: str = Field(default="en", description="BCP-47-ish tag: en, ta.")
    heading_deg: float | None = Field(default=None, ge=0, lt=360)
    speed_knots: float | None = Field(default=None, ge=0, le=60)


class ChatResponse(BaseModel):
    reply: str
    reply_ta: str | None = None
    intent: Intent
    severity: Severity
    evidence: list[Evidence] = Field(default_factory=list)
    map_layers: list[MapLayer] = Field(default_factory=list)
    agent_trace: list[AgentStep] = Field(default_factory=list)
    engine: Engine = Engine.RULES
    generated_at: datetime
