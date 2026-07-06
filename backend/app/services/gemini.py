import json
import re
from collections.abc import Awaitable, Callable
from typing import Any

import httpx

from ..config import Settings
from ..errors import ProviderRateLimited, ProviderUnavailable
from ..schemas.ai import JsonRequest, TextRequest
from .locale import composed_system, localised_prompt

_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models"
_RETRY_DELAY = re.compile(r"^([0-9.]+)s$")


class GeminiProvider:
    def __init__(self, http: httpx.AsyncClient, settings: Settings):
        self._http = http
        self._key = settings.gemini_api_key
        self._models = settings.gemini_model_list

    @property
    def is_configured(self) -> bool:
        return bool(self._key)

    async def generate_text(self, req: TextRequest) -> str:
        contents = [
            {"role": turn.role, "parts": [{"text": turn.text}]}
            for turn in req.history
        ]
        contents.append({"role": "user", "parts": self._parts(req.prompt, req)})

        async def call(model: str) -> dict[str, Any]:
            config: dict[str, Any] = {
                "temperature": req.temperature,
                "responseMimeType": "text/plain",
                "maxOutputTokens": req.max_output_tokens,
            }
            if "2.5" in model or model == "gemini-flash-latest":
                config["thinkingConfig"] = {"thinkingBudget": 0}
            return await self._post(
                model,
                {
                    "contents": contents,
                    "generationConfig": config,
                    "systemInstruction": {
                        "parts": [
                            {"text": composed_system(req.system_prompt, req.locale)}
                        ]
                    },
                },
            )

        payload = await self._try_models(call)
        text = self._extract_text(payload).strip()
        if not text:
            raise ProviderUnavailable("gemini returned no content")
        return text

    async def generate_json(self, req: JsonRequest) -> dict[str, Any]:
        body = {
            "contents": [
                {
                    "role": "user",
                    "parts": self._parts(
                        localised_prompt(req.prompt, req.locale), req
                    ),
                }
            ],
            "generationConfig": {
                "temperature": req.temperature,
                "responseMimeType": "application/json",
                "responseSchema": req.json_schema,
            },
        }

        async def call(model: str) -> dict[str, Any]:
            return await self._post(model, body)

        payload = await self._try_models(call)
        text = self._extract_text(payload)
        try:
            data = json.loads(text)
        except json.JSONDecodeError as e:
            raise ProviderUnavailable(f"gemini returned invalid JSON: {e}") from e
        if not isinstance(data, dict):
            raise ProviderUnavailable("gemini returned non-object JSON")
        return data

    def _parts(
        self, prompt: str, req: TextRequest | JsonRequest
    ) -> list[dict[str, Any]]:
        parts: list[dict[str, Any]] = [{"text": prompt}]
        if req.image_base64:
            parts.append(
                {
                    "inline_data": {
                        "mime_type": req.image_mime_type,
                        "data": req.image_base64,
                    }
                }
            )
        return parts

    async def _try_models(
        self, call: Callable[[str], Awaitable[dict[str, Any]]]
    ) -> dict[str, Any]:
        min_retry: float | None = None
        last_detail = "all gemini models failed"
        for model in self._models:
            try:
                return await call(model)
            except ProviderRateLimited as e:
                min_retry = (
                    e.retry_after_seconds
                    if min_retry is None
                    else min(min_retry, e.retry_after_seconds)
                )
            except ProviderUnavailable as e:
                last_detail = e.detail
        if min_retry is not None:
            raise ProviderRateLimited(min_retry)
        raise ProviderUnavailable(last_detail)

    async def _post(self, model: str, body: dict[str, Any]) -> dict[str, Any]:
        try:
            res = await self._http.post(
                f"{_ENDPOINT}/{model}:generateContent",
                params={"key": self._key},
                json=body,
            )
        except httpx.HTTPError as e:
            raise ProviderUnavailable(f"gemini {model} network error: {e}") from e
        if res.status_code == 429:
            raise ProviderRateLimited(self._retry_after(res))
        if res.status_code != 200:
            raise ProviderUnavailable(f"gemini {model} HTTP {res.status_code}")
        return res.json()

    def _retry_after(self, res: httpx.Response) -> float:
        try:
            details = res.json().get("error", {}).get("details", [])
            for detail in details:
                if "RetryInfo" in detail.get("@type", ""):
                    match = _RETRY_DELAY.match(detail.get("retryDelay", ""))
                    if match:
                        return float(match.group(1))
        except (ValueError, AttributeError):
            pass
        return 60.0

    def _extract_text(self, payload: dict[str, Any]) -> str:
        candidates = payload.get("candidates") or []
        if not candidates:
            return ""
        parts = (candidates[0].get("content") or {}).get("parts") or []
        if not parts:
            return ""
        return parts[0].get("text") or ""
