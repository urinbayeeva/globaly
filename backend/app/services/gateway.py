from typing import Any

from ..errors import ProviderRateLimited, ProviderUnavailable
from ..schemas.ai import JsonRequest, TextRequest
from .cache import ResponseCache
from .gemini import GeminiProvider
from .groq import GroqProvider


class AiGateway:
    def __init__(
        self,
        gemini: GeminiProvider,
        groq: GroqProvider,
        cache: ResponseCache | None = None,
    ):
        self._gemini = gemini
        self._groq = groq
        self._cache = cache

    @property
    def providers(self) -> dict[str, bool]:
        return {
            "gemini": self._gemini.is_configured,
            "groq": self._groq.is_configured,
        }

    async def generate_text(self, req: TextRequest) -> str:
        return await self._run(
            lambda p: p.generate_text(req)
        )

    async def generate_json(self, req: JsonRequest) -> dict[str, Any]:
        return await self._run(
            lambda p: p.generate_json(req)
        )

    async def generate_json_cached(self, req: JsonRequest) -> dict[str, Any]:
        if self._cache is None or req.image_base64:
            return await self.generate_json(req)
        key = ResponseCache.key(req.model_dump())
        return await self._cache.get_or_create(
            key, lambda: self.generate_json(req)
        )

    async def _run(self, call):
        chain = [p for p in (self._gemini, self._groq) if p.is_configured]
        if not chain:
            raise ProviderUnavailable("no AI provider configured")
        rate_limited: ProviderRateLimited | None = None
        unavailable: ProviderUnavailable | None = None
        for provider in chain:
            try:
                return await call(provider)
            except ProviderRateLimited as e:
                rate_limited = e
            except ProviderUnavailable as e:
                unavailable = e
        if rate_limited is not None:
            raise rate_limited
        raise unavailable or ProviderUnavailable("all providers failed")
