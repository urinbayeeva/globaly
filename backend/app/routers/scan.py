from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import ImageRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/scan", tags=["scan"], dependencies=[Depends(require_user)]
)

_PROMPT = """
You are a careful legal document reviewer for migrants. The user has
photographed a document. Do two things:

1) Identify the document type. Return one of:
   "contract" | "passport" | "diploma" | "id_card" | "transcript" |
   "certificate" | "unknown".

2) If — and only if — it is a contract (employment, rental, service,
   freelance, etc.), evaluate it from the user's perspective:
   - List up to 5 RISKY clauses with severity "dangerous" | "warning" |
     "notice". For each risk include: title (≤7 words), severity, a SHORT
     verbatim quote from the document (≤25 words), and a 1–2 sentence
     explanation in plain English of why the user should care.
   - List up to 3 FAIR / SAFE points (clauses that protect the user, e.g.
     reasonable notice period, clear scope, mutual termination).
   - Write a 1-sentence summary.

If the document is NOT a contract, leave "risks" and "safePoints" empty
and set "summary" to a polite single-sentence reply like
"This looks like a [TYPE]. Please scan a contract for risk analysis."

Also always return the raw text you extracted from the image in
"rawText" (best-effort transcription).
"""

_SCHEMA = {
    "type": "object",
    "properties": {
        "documentType": {"type": "string"},
        "summary": {"type": "string"},
        "rawText": {"type": "string"},
        "risks": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string"},
                    "severity": {"type": "string"},
                    "quote": {"type": "string"},
                    "explanation": {"type": "string"},
                },
                "required": ["title", "severity", "quote", "explanation"],
            },
        },
        "safePoints": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["documentType", "summary", "rawText", "risks", "safePoints"],
}


@router.post("/analyze")
async def analyze(
    req: ImageRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    return await mapped(
        lambda: ai.generate_json(
            JsonRequest(
                prompt=_PROMPT,
                json_schema=_SCHEMA,
                temperature=0.1,
                image_base64=req.image_base64,
                image_mime_type=req.image_mime_type,
                locale=req.locale,
            )
        )
    )
