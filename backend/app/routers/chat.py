from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import HistoryTurn, TextRequest, TextResponse
from ..schemas.features import ChatRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/chat", tags=["chat"], dependencies=[Depends(require_user)]
)

_IMAGE_ONLY_PROMPT = (
    "Describe this image and explain anything relevant to someone moving "
    "abroad (e.g. what a form/sign/document means and what to do next)."
)


def _system_prompt(destination_country: str, purpose: str) -> str:
    dest_line = (
        "The user has not picked a destination country yet."
        if not destination_country
        else f"The user is planning to move to {destination_country}."
    )
    return f"""
You are the Globaly assistant — a friendly, practical helper for people
moving abroad. Keep answers concise (2–4 short paragraphs max), specific,
and grounded in commonly available public knowledge. If a question needs
country-specific facts you are unsure about, say so and point the user at
the official source (embassy, ministry, university).

User context:
- {dest_line}
- Stated purpose: {purpose}.

Style:
- Use plain language; no jargon unless you define it.
- When listing steps use short numbered points (e.g. "1.", "2.") on new
  lines — do NOT use bullet stars or hyphens.
- Output PLAIN TEXT ONLY. No markdown whatsoever: no **bold**, no *italics*,
  no _underscores_, no `backticks`, no #headings, no [links](urls) — just
  the words. The chat UI shows raw characters, so any markdown marks will
  appear as literal punctuation.
- Never invent prices, dates, or document names — round to typical ranges
  or say "verify on the official site".
- Politely decline anything outside the moving-abroad / immigration scope.
"""


@router.post("", response_model=TextResponse)
async def chat(req: ChatRequest, ai: AiGateway = Depends(get_ai)) -> TextResponse:
    prompt = (
        _IMAGE_ONLY_PROMPT
        if not req.message.strip() and req.image_base64
        else req.message
    )
    text = await mapped(
        lambda: ai.generate_text(
            TextRequest(
                prompt=prompt,
                system_prompt=_system_prompt(req.destination_country, req.purpose),
                history=[
                    HistoryTurn(role=t.role, text=t.text) for t in req.history
                ],
                temperature=0.6,
                max_output_tokens=1024,
                image_base64=req.image_base64,
                image_mime_type=req.image_mime_type,
                locale=req.locale,
            )
        )
    )
    return TextResponse(text=text)
