from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .auth import init_firebase
from .config import get_settings
from .routers import (
    ai,
    chat,
    cost,
    culture,
    currency,
    email,
    health,
    interview,
    recommendations,
    scan,
    translator,
    universities,
)
from .services.cache import ResponseCache
from .services.currency import CurrencyService
from .services.email import EmailService
from .services.gateway import AiGateway
from .services.gemini import GeminiProvider
from .services.groq import GroqProvider


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    init_firebase()
    http = httpx.AsyncClient(
        timeout=httpx.Timeout(30.0, connect=10.0, write=15.0)
    )
    app.state.http = http
    app.state.ai = AiGateway(
        GeminiProvider(http, settings),
        GroqProvider(http, settings),
        ResponseCache(
            settings.ai_cache_ttl_seconds, settings.ai_cache_max_entries
        ),
    )
    app.state.email = EmailService(http, settings)
    app.state.currency = CurrencyService(http, settings)
    yield
    await http.aclose()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="Globaly API", version="1.0.0", lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(health.router)
    app.include_router(chat.router)
    app.include_router(universities.router)
    app.include_router(recommendations.router)
    app.include_router(cost.router)
    app.include_router(culture.router)
    app.include_router(interview.router)
    app.include_router(scan.router)
    app.include_router(translator.router)
    app.include_router(ai.router)
    app.include_router(email.router)
    app.include_router(currency.router)
    return app


app = create_app()
