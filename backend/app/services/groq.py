import json
from typing import Any

import httpx

from ..config import Settings
from ..errors import ProviderRateLimited, ProviderUnavailable
from ..schemas.ai import JsonRequest, TextRequest
from .locale import composed_system, directive, localised_prompt

_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"


class GroqProvider:
    def __init__(self, http: httpx.AsyncClient, settings: Settings):
        self._http = http
        self._key = settings.groq_api_key
        self._models = settings.groq_model_list
        self._vision_model = settings.groq_vision_model

    @property
    def is_configured(self) -> bool:
        return bool(self._key)

    async def generate_text(self, req: TextRequest) -> str:
        messages: list[dict[str, Any]] = [
            {
                "role": "system",
                "content": composed_system(req.system_prompt, req.locale),
            }
        ]
        for turn in req.history:
            role = "assistant" if turn.role == "model" else turn.role
            messages.append({"role": role, "content": turn.text})
        messages.append({"role": "user", "content": self._user_content(req.prompt, req)})

        payload = await self._try_models(
            {"temperature": req.temperature, "messages": messages},
            has_image=req.image_base64 is not None,
        )
        content = self._extract_content(payload).strip()
        if not content:
            raise ProviderUnavailable("groq returned no content")
        return content

    async def generate_json(self, req: JsonRequest) -> dict[str, Any]:
        system = "\n".join(
            [
                directive(req.locale),
                "You return strictly valid JSON that conforms to the provided schema.",
                "Schema:",
                json.dumps(req.json_schema),
                "Return only the JSON object — no markdown fences, no commentary.",
            ]
        )
        messages = [
            {"role": "system", "content": system},
            {
                "role": "user",
                "content": self._user_content(
                    localised_prompt(req.prompt, req.locale), req
                ),
            },
        ]
        payload = await self._try_models(
            {
                "temperature": req.temperature,
                "messages": messages,
                "response_format": {"type": "json_object"},
            },
            has_image=req.image_base64 is not None,
        )
        content = self._extract_content(payload)
        if not content:
            raise ProviderUnavailable("groq returned no content")
        return self._decode_json_object(content)

    def _user_content(
        self, prompt: str, req: TextRequest | JsonRequest
    ) -> str | list[dict[str, Any]]:
        if not req.image_base64:
            return prompt
        return [
            {"type": "text", "text": prompt},
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:{req.image_mime_type};base64,{req.image_base64}"
                },
            },
        ]

    async def _try_models(
        self, body: dict[str, Any], *, has_image: bool
    ) -> dict[str, Any]:
        models = [self._vision_model] if has_image else self._models
        rate_limited = False
        last_detail = "all groq models failed"
        for model in models:
            try:
                return await self._post({**body, "model": model})
            except ProviderRateLimited:
                rate_limited = True
            except ProviderUnavailable as e:
                last_detail = e.detail
        if rate_limited:
            raise ProviderRateLimited(30.0)
        raise ProviderUnavailable(last_detail)

    async def _post(self, body: dict[str, Any]) -> dict[str, Any]:
        try:
            res = await self._http.post(
                _ENDPOINT,
                json=body,
                headers={"Authorization": f"Bearer {self._key}"},
            )
        except httpx.HTTPError as e:
            raise ProviderUnavailable(f"groq network error: {e}") from e
        if res.status_code == 429:
            raise ProviderRateLimited(30.0)
        if res.status_code != 200:
            raise ProviderUnavailable(f"groq HTTP {res.status_code}")
        return res.json()

    def _decode_json_object(self, raw: str) -> dict[str, Any]:
        s = raw.strip()
        if s.startswith("```"):
            s = s.split("\n", 1)[1] if "\n" in s else s
            s = s.rsplit("```", 1)[0].strip()
        try:
            parsed = json.loads(s)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            pass
        start, end = s.find("{"), s.rfind("}")
        if start != -1 and end > start:
            try:
                parsed = json.loads(s[start : end + 1])
                if isinstance(parsed, dict):
                    return parsed
            except json.JSONDecodeError:
                pass
        raise ProviderUnavailable(f"groq returned non-JSON: {s[:120]}")

    def _extract_content(self, payload: dict[str, Any]) -> str:
        choices = payload.get("choices") or []
        if not choices:
            return ""
        return (choices[0].get("message") or {}).get("content") or ""
