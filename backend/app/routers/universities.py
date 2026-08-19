from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import UniversityInsightsRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/universities",
    tags=["universities"],
    dependencies=[Depends(require_user)],
)

_SCHEMA = {
    "type": "object",
    "properties": {
        "acceptsInternational": {"type": "boolean"},
        "minIelts": {"type": "number"},
        "minToefl": {"type": "integer"},
        "minSat": {"type": "integer"},
        "scholarshipAvailable": {"type": "boolean"},
        "scholarshipPercent": {"type": "integer"},
        "scholarshipName": {"type": "string"},
        "notes": {"type": "string"},
    },
    "required": [
        "acceptsInternational",
        "minIelts",
        "minToefl",
        "minSat",
        "scholarshipAvailable",
        "scholarshipPercent",
        "scholarshipName",
        "notes",
    ],
}


@router.post("/insights")
async def insights(
    req: UniversityInsightsRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
You are an admissions data assistant. For the university below, return a
JSON object with realistic, **conservative** estimates of its
international-undergraduate admission profile. Use widely reported public
data; if a value is genuinely unknown, use 0 (numbers) or false (bool).
Do NOT invent precise figures — round to typical thresholds.

University: {req.name}
Location: {req.location}
Website: {req.website}

Fields:
- acceptsInternational (bool): does it admit non-citizen / non-resident students?
- minIelts (number, 0–9): typical minimum IELTS overall band for undergrad
- minToefl (int, 0–120): typical minimum TOEFL iBT total
- minSat (int, 0–1600): typical SAT total (0 if not required, e.g. UK/EU schools)
- scholarshipAvailable (bool): are merit/need scholarships offered to international students?
- scholarshipPercent (int, 0–100): coverage of the most accessible scholarship; 0 if N/A
- scholarshipName (string): concrete scholarship title (e.g. "President's International Award"); empty string if none
- notes (string, 1–2 sentences): who qualifies for the scholarship and any caveats
"""
    return await mapped(
        lambda: ai.generate_json_cached(
            JsonRequest(prompt=prompt, json_schema=_SCHEMA, locale=req.locale)
        )
    )
