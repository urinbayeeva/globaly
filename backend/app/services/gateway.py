from typing import Any

from ..errors import ProviderRateLimited, ProviderUnavailable
from ..schemas.ai import JsonRequest, TextRequest
from .gemini import GeminiProvider
from .groq import GroqProvider


class AiGateway:
    def __init__(self, gemini: GeminiProvider, groq: GroqProvider):
        self._gemini = gemini
        self._groq = groq

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
