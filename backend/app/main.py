"""ORCA backend entry point.

Run from the repository root:
    uv run --directory backend uvicorn app.main:app --reload --host 0.0.0.0

Binding 0.0.0.0 matters: the Android emulator reaches the host at 10.0.2.2 and
a physical handset reaches it over the LAN, neither of which can see localhost.
"""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routers import chat, geo, health, marine

logging.basicConfig(level=logging.INFO)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    summary="Marine intelligence API for the ORCA mobile app (SIH26176).",
    description=(
        "Serves maritime boundaries, fishing-zone advisories, live sea state, "
        "and the conversational assistant.\n\n"
        "**Development data.** Boundary and PFZ geometry is seeded and not "
        "survey-accurate. It must not be used for navigation."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(geo.router)
app.include_router(marine.router)
app.include_router(chat.router)
