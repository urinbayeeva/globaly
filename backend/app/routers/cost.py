from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import CountryRequest
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/cost-of-living",
    tags=["cost-of-living"],
    dependencies=[Depends(require_user)],
)

_SCHEMA = {
    "type": "object",
    "properties": {
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "city": {"type": "string"},
                    "rentMonthly": {"type": "integer"},
                    "foodMonthly": {"type": "integer"},
                    "transportMonthly": {"type": "integer"},
                    "miscMonthly": {"type": "integer"},
                },
                "required": [
                    "city",
                    "rentMonthly",
                    "foodMonthly",
                    "transportMonthly",
                    "miscMonthly",
                ],
            },
        },
    },
    "required": ["items"],
}


@router.post("")
async def cities(
    req: CountryRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
Estimate the monthly cost of living for ONE person in the 5 most relevant
cities of {req.country} (capital + major economic/student hubs). Use conservative,
widely-reported figures in US dollars.

For each city break the monthly budget into:
- rentMonthly (int): average rent for a one-bedroom apartment
- foodMonthly (int): groceries plus occasional eating out
- transportMonthly (int): public transport pass plus occasional rides
- miscMonthly (int): utilities, mobile, internet, and leisure

Return an "items" array. For each city:
- city (string): the city name
- rentMonthly (int)
- foodMonthly (int)
- transportMonthly (int)
- miscMonthly (int)
"""
    return await mapped(
        lambda: ai.generate_json(
            JsonRequest(prompt=prompt, json_schema=_SCHEMA, locale=req.locale)
        )
    )
