from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import InterviewRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/interview",
    tags=["interview"],
    dependencies=[Depends(require_user)],
)

_TARGET_QUESTIONS = 5

_SCHEMA = {
    "type": "object",
    "properties": {
        "feedback": {"type": "string"},
        "question": {"type": "string"},
        "done": {"type": "boolean"},
        "assessment": {"type": "string"},
        "score": {"type": "integer"},
        "tips": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["feedback", "question", "done", "assessment", "score", "tips"],
}


def _transcript(req: InterviewRequest) -> str:
    lines: list[str] = []
    for i, turn in enumerate(req.turns):
        lines.append(f"Officer Q{i + 1}: {turn.question}")
        answer = turn.answer.strip() or "(not answered yet)"
        lines.append(f"Applicant A{i + 1}: {answer}")
    if req.latest_answer.strip() and req.turns:
        lines.append(f"Latest applicant answer to Q{len(req.turns)}:")
        lines.append(req.latest_answer.strip())
    return "\n".join(lines)


@router.post("/next")
async def next_exchange(
    req: InterviewRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    country = req.country or "your destination country"
    asked = len(req.turns)
    transcript = _transcript(req)
    prompt = f"""
You are a realistic but encouraging visa officer conducting a mock
{req.purpose} visa interview for an applicant who wants to go
to {country}. Your goal is to help them practise and improve.

Rules:
- Ask common, realistic interview questions ONE at a time. Keep each question
  to 1–2 short sentences. Tailor them to a {req.purpose} visa.
- Aim for about {_TARGET_QUESTIONS} questions total. You have asked {asked} so far.
- After each applicant answer, put one short, constructive sentence in
  "feedback" (what was good and one thing to improve). For the very first
  question, leave "feedback" empty.
- While the interview continues: set "done" to false, put the next question in
  "question", and leave "assessment" empty and "score" 0.
- Once you have asked about {_TARGET_QUESTIONS} questions AND received answers,
  finish: set "done" to true, leave "question" empty, write a 2–3 sentence
  overall "assessment", give an integer "score" 0–100 for interview
  readiness, and up to 3 short "tips" for improvement.
- Be specific and practical. Never invent the applicant's personal facts.

Conversation so far:
{transcript or '(none yet — ask the first question)'}

Return only the next exchange as JSON.
"""
    return await mapped(
        lambda: ai.generate_json(
            JsonRequest(
                prompt=prompt,
                json_schema=_SCHEMA,
                temperature=0.6,
                locale=req.locale,
            )
        )
    )
