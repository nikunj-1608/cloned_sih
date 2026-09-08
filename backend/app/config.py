"""Settings, read from the repository-root `.env`.

Nothing in the app reads `os.environ` directly. Every value funnels through
`Settings` so a missing or malformed key fails once, loudly, at import time
rather than as a `None` deep inside a request handler.
"""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = REPO_ROOT / "data" / "seed"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "ORCA API"
    debug: bool = True

    # Open-Meteo needs no key. Kept configurable so the demo can be pointed at
    # a recorded fixture if the venue's network is hostile.
    open_meteo_marine_url: str = "https://marine-api.open-meteo.com/v1/marine"
    open_meteo_forecast_url: str = "https://api.open-meteo.com/v1/forecast"

    # Every outbound call is bounded. At sea the app has no network at all, and
    # at a demo venue it may have a bad one; neither may hang a request.
    upstream_timeout_seconds: float = 6.0

    # CORS. Tightened before anything is deployed.
    allowed_origins: list[str] = ["*"]

    @property
    def seed_dir(self) -> Path:
        return SEED_DIR


@lru_cache
def get_settings() -> Settings:
    return Settings()
