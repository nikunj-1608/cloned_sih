"""Shared FastAPI dependencies."""

from typing import Annotated

from fastapi import Depends

from .config import Settings, get_settings
from .services.geo_store import GeoStore, get_geo_store
from .services.intent_router import IntentRouter
from .services.open_meteo import OpenMeteoClient

SettingsDep = Annotated[Settings, Depends(get_settings)]
GeoStoreDep = Annotated[GeoStore, Depends(get_geo_store)]


def get_weather_client(settings: SettingsDep) -> OpenMeteoClient:
    return OpenMeteoClient(settings)


WeatherDep = Annotated[OpenMeteoClient, Depends(get_weather_client)]


def get_intent_router(geo: GeoStoreDep, weather: WeatherDep) -> IntentRouter:
    return IntentRouter(geo, weather)


RouterDep = Annotated[IntentRouter, Depends(get_intent_router)]
