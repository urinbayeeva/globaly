from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import ImageRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/translate",
    tags=["translate"],
    dependencies=[Depends(require_user)],
)

_PROMPT = """
You help a migrant understand a document they photographed in a foreign
country. Do all of the following:

1) Detect the source language of the document and return its English name in
   "detectedLanguage" (e.g. "German", "Turkish", "Korean").
2) Identify what the document is in 2–4 words in "documentType"
   (e.g. "Rental agreement", "Bank letter", "Registration form", "Bill").
3) In "translation", translate ALL readable text faithfully and completely
   into the response language. Preserve the structure — labels, fields,
   amounts, dates — using line breaks. Keep numbers, dates, currency codes
   and proper names as-is.
4) In "summary", write 1–2 plain sentences explaining what this document is
   and why it matters to the user.
5) In "nextSteps", list up to 3 short, concrete actions the user should take
   (e.g. "Sign and return before the date shown", "Bring this to the town
   hall"). Use an empty list if none apply.

If the image contains no readable text, set "documentType" to "unknown",
leave "translation" empty, and explain that politely in "summary".
"""

_SCHEMA = {
    "type": "object",
    "properties": {
        "detectedLanguage": {"type": "string"},
        "documentType": {"type": "string"},
        "translation": {"type": "string"},
        "summary": {"type": "string"},
        "nextSteps": {"type": "array", "items": {"type": "string"}},
    },
    "required": [
        "detectedLanguage",
        "documentType",
        "translation",
        "summary",
        "nextSteps",
    ],
}


@router.post("/document")
async def translate_document(
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
