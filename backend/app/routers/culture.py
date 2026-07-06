from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import CountryRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/culture", tags=["culture"], dependencies=[Depends(require_user)]
)

_SCHEMA = {
    "type": "object",
    "properties": {
        "headline": {"type": "string"},
        "facts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "kind": {"type": "string"},
                    "value": {"type": "string"},
                },
                "required": ["kind", "value"],
            },
        },
        "sections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "tips": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "text": {"type": "string"},
                                "isDo": {"type": "boolean"},
                            },
                            "required": ["text", "isDo"],
                        },
                    },
                },
                "required": ["title", "tips"],
            },
        },
        "scenarios": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "situation": {"type": "string"},
                    "options": {"type": "array", "items": {"type": "string"}},
                    "correctIndex": {"type": "integer"},
                    "explanation": {"type": "string"},
                },
                "required": [
                    "situation",
                    "options",
                    "correctIndex",
                    "explanation",
                ],
            },
        },
    },
    "required": ["headline", "facts", "sections", "scenarios"],
}


@router.post("")
async def briefing(
    req: CountryRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
You are a cross-cultural relocation coach. Write a practical cultural briefing
for a newcomer moving to {req.country}. Focus on the unwritten social rules locals
take for granted — the things that help someone fit in and avoid embarrassment.
Be specific to {req.country}, not generic. Keep every string concise and mobile-friendly.

Return JSON with:
- "headline": one vivid sentence capturing the social vibe of {req.country}.
- "facts": exactly 4 quick facts, one for each "kind" in this order —
  "greeting", "tipping", "punctuality", "dress". Each fact has:
    - "kind": the kind string above
    - "value": a short phrase (max ~6 words) for that aspect in {req.country}
- "sections": exactly 4 themed sections. Each has:
    - "title": a short theme name (e.g. dining, conversation,
      public behaviour, taboos)
    - "tips": 3 to 4 concise tips. Each tip has:
        - "text": one practical sentence
        - "isDo": true for something to DO, false for something to AVOID
  Make the final section about clear taboos (mostly isDo=false).
- "scenarios": exactly 3 "what would you do" etiquette challenges. Each has:
    - "situation": a realistic 1–2 sentence situation in {req.country}
    - "options": exactly 3 short answer options
    - "correctIndex": the 0-based index of the most culturally appropriate option
    - "explanation": one sentence on why that option is best
"""
    return await mapped(
        lambda: ai.generate_json(
            JsonRequest(
                prompt=prompt,
                json_schema=_SCHEMA,
                temperature=0.5,
                locale=req.locale,
            )
        )
    )
