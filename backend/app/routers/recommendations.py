from typing import Any

from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest
from ..schemas.features import (
    CountryRequest,
    DocumentsRequest,
    HotelsRequest,
    JobsRequest,
    PurposeRequest,
)
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/recommendations",
    tags=["recommendations"],
    dependencies=[Depends(require_user)],
)


async def _json(
    ai: AiGateway, prompt: str, schema: dict[str, Any], locale: str
) -> dict[str, Any]:
    return await mapped(
        lambda: ai.generate_json_cached(
            JsonRequest(prompt=prompt, json_schema=schema, locale=locale)
        )
    )


def _items_schema(properties: dict[str, Any]) -> dict[str, Any]:
    return {
        "type": "object",
        "properties": {
            "items": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": properties,
                    "required": list(properties),
                },
            },
        },
        "required": ["items"],
    }


_DESTINATIONS_SCHEMA = _items_schema(
    {
        "name": {"type": "string"},
        "region": {"type": "string"},
        "summary": {"type": "string"},
        "bestSeason": {"type": "string"},
    }
)


@router.post("/destinations")
async def destinations(
    req: CountryRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
List the 6 most popular travel destinations in {req.country} for an international
visitor. Mix iconic cities, scenic regions, and at least one off-the-beaten-path
spot. Be concrete (specific city / region names — not "the south coast").

Return an "items" array. For each destination:
- name (string): the place
- region (string): broader area (e.g. "Bavaria", "Catalonia"); empty if not relevant
- summary (string, 1 sentence): why a foreigner would visit
- bestSeason (string): season window like "May–September"; empty if year-round
"""
    return await _json(ai, prompt, _DESTINATIONS_SCHEMA, req.locale)


_HOTELS_SCHEMA = _items_schema(
    {
        "name": {"type": "string"},
        "city": {"type": "string"},
        "priceUsdPerNight": {"type": "integer"},
        "stars": {"type": "integer"},
        "rating": {"type": "number"},
        "summary": {"type": "string"},
        "bookingHint": {"type": "string"},
        "photoQuery": {"type": "string"},
    }
)


@router.post("/hotels")
async def hotels(
    req: HotelsRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    scope = req.country if not req.city else f"{req.city}, {req.country}"
    prompt = f"""
Suggest 6 real, well-reviewed hotels in {scope} for international travellers,
mixing budget ($, 2–3 stars), mid-range ($$, 3–4 stars), and premium
($$$, 4–5 stars). Use real hotel names that travellers would find on major
booking sites. Conservative numeric estimates only.

Return an "items" array. For each hotel:
- name (string): real hotel name
- city (string): city it's located in
- priceUsdPerNight (int): typical USD/night for a standard double
- stars (int, 1–5): rating
- rating (number, 0–10): typical guest rating (e.g. 8.6)
- summary (string, 1 sentence): why it's a good fit (location / amenities / value)
- bookingHint (string): a comma-separated list of booking platforms (e.g. "Booking.com, Hotels.com, Expedia")
- photoQuery (string): 2–4 word search query that finds a representative photo on Unsplash, e.g. "burj khalifa dubai" or "ritz paris facade"
"""
    return await _json(ai, prompt, _HOTELS_SCHEMA, req.locale)


_JOBS_SCHEMA = _items_schema(
    {
        "title": {"type": "string"},
        "company": {"type": "string"},
        "city": {"type": "string"},
        "salaryUsdPerMonthMin": {"type": "integer"},
        "salaryUsdPerMonthMax": {"type": "integer"},
        "experienceYears": {"type": "integer"},
        "languageRequirement": {"type": "string"},
        "visaSponsorship": {"type": "boolean"},
        "summary": {"type": "string"},
        "searchUrl": {"type": "string"},
    }
)


@router.post("/jobs")
async def jobs(req: JobsRequest, ai: AiGateway = Depends(get_ai)) -> dict[str, Any]:
    prompt = f"""
Suggest 6 realistic job opportunities for a foreigner relocating to {req.country}.
Filter strictly by:
- Field: {req.field}
- Spoken language: {req.language}
- Years of experience: {req.experience_years}

Mix entry-level and senior roles within the filter. Prefer real companies that
historically sponsor visas in {req.country}. For salaries use conservative USD/month
ranges typical of the country and role.

Return an "items" array. For each job:
- title (string): role title
- company (string): real or representative company
- city (string): main location
- salaryUsdPerMonthMin (int)
- salaryUsdPerMonthMax (int)
- experienceYears (int): typical minimum years required
- languageRequirement (string): "English", "Local language", "Both", or "None"
- visaSponsorship (bool): does the role typically sponsor work visas?
- summary (string, 1 sentence): what makes the role a fit
- searchUrl (string): a real job-board search URL that surfaces similar listings
  (e.g. https://www.linkedin.com/jobs/search/?keywords=ROLE&location={req.country})
"""
    return await _json(ai, prompt, _JOBS_SCHEMA, req.locale)


_BUSINESS_SCHEMA = _items_schema(
    {
        "city": {"type": "string"},
        "region": {"type": "string"},
        "lat": {"type": "number"},
        "lng": {"type": "number"},
        "summary": {"type": "string"},
        "ideas": {"type": "array", "items": {"type": "string"}},
        "demandLevel": {"type": "string"},
    }
)


@router.post("/business")
async def business(
    req: CountryRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
List 6 cities or districts in {req.country} where a foreign entrepreneur could start
a venture. Spread them across the country (mix capital + regional hubs).

For each city return:
- city (string): city or district name
- region (string): broader administrative region; empty if unknown
- lat (number): WGS84 latitude
- lng (number): WGS84 longitude
- summary (string, 1 sentence): why this city is good for business
- ideas (array of strings, 3–5 items): concrete venture ideas suited to the city
  (e.g. "Co-working space for remote workers", "Halal export-oriented food brand")
- demandLevel (string): one of "low" | "medium" | "high"

Only include cities you can locate with reasonable accuracy. Do NOT invent
coordinates — return 0 for both lat and lng if unsure.
"""
    return await _json(ai, prompt, _BUSINESS_SCHEMA, req.locale)


_VISA_SCHEMA = {
    "type": "object",
    "properties": {
        "visaTypeName": {"type": "string"},
        "visaTypeCode": {"type": "string"},
        "processingWeeks": {"type": "integer"},
        "applicationFeeUsd": {"type": "integer"},
        "totalCostUsd": {"type": "integer"},
        "notes": {"type": "string"},
    },
    "required": [
        "visaTypeName",
        "visaTypeCode",
        "processingWeeks",
        "applicationFeeUsd",
        "totalCostUsd",
        "notes",
    ],
}


@router.post("/visa-info")
async def visa_info(
    req: PurposeRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
You are an immigration data assistant. For someone entering {req.country} with
purpose "{req.purpose}" (one of: study | work | family | tourism | business),
return the typical visa pathway as JSON. Use widely reported public figures;
if a value is unknown use 0 (numbers) or empty string (strings).

Fields:
- visaTypeName (string): human-readable name, e.g. "Student Visa (Type D)" / "Skilled Worker Visa"
- visaTypeCode (string): official short code, e.g. "F-1", "Tier 4", "Type D"; empty if none
- processingWeeks (int): typical processing time end-to-end
- applicationFeeUsd (int): government application fee in USD
- totalCostUsd (int): full end-to-end cost (fees + translations + insurance + medical + courier)
- notes (string, 1 short sentence): what's included or any caveat
"""
    return await _json(ai, prompt, _VISA_SCHEMA, req.locale)


_ROADMAP_SCHEMA = {
    "type": "object",
    "properties": {
        "headline": {"type": "string"},
        "steps": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "title": {"type": "string"},
                    "description": {"type": "string"},
                    "weeks": {"type": "integer"},
                },
                "required": ["id", "title", "description", "weeks"],
            },
        },
    },
    "required": ["headline", "steps"],
}


@router.post("/roadmap")
async def roadmap(
    req: PurposeRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
You are a migration planner. For someone moving to {req.country} with purpose
"{req.purpose}" (one of: study | work | family | tourism | business), build a
realistic step-by-step roadmap.

Constraints:
- Return 8–10 steps in chronological order (earliest first).
- Include country-specific procedures (e.g. "Anmeldung" in Germany,
  "SSN application" in the US, "PR check-in" in Canada).
- Steps must be actionable, not generic ("Apply for X visa", not "Prepare visa").
- Each step gets a short id (lower_snake_case), title, 1-sentence description,
  and weeks (integer estimate of duration).

Return:
- headline (string): short subtitle like "{req.country} · {req.purpose} · ~14 weeks"
- steps (array): the ordered steps
"""
    return await _json(ai, prompt, _ROADMAP_SCHEMA, req.locale)


_DOCUMENTS_SCHEMA = _items_schema(
    {
        "id": {"type": "string"},
        "title": {"type": "string"},
        "issuer": {"type": "string"},
        "statusCode": {"type": "string"},
        "iconHint": {"type": "string"},
        "description": {"type": "string"},
        "validityYears": {"type": "integer"},
        "costUsd": {"type": "integer"},
        "notes": {"type": "array", "items": {"type": "string"}},
    }
)


@router.post("/documents")
async def documents(
    req: DocumentsRequest, ai: AiGateway = Depends(get_ai)
) -> dict[str, Any]:
    prompt = f"""
You are an immigration paperwork expert. Given a person moving from
{req.origin_country} to {req.country} with purpose "{req.purpose}" (one of:
study | work | family | tourism | business), return the full list of
documents and permits they will need.

Constraints:
- Return 6–12 items, ordered by importance (passport + visa first).
- Be SPECIFIC to {req.country}. Use the real names of {req.country}'s documents
  and procedures. Examples (NEVER skip these when applicable to the
  destination):
    • Russia (work): Russian work patent (патент на работу) + monthly
      patent tax payment; migration card; notification of arrival;
      Russian language test (РКТ); HIV / medical certificate; voluntary
      health insurance (ДМС); INN tax number.
    • Germany: Anmeldung (address registration); Schufa; blocked account.
    • United States: SEVIS I-901; DS-160; SSN application; I-94.
    • United Kingdom: BRP / eVisa share code; ATAS (sensitive subjects);
      TB test (some countries).
    • Saudi Arabia / UAE: Emirates ID; medical fitness test; attestation
      of certificates by MoFA.
- Include RECURRING fees (monthly / yearly taxes, residence-card renewal
  fees, mandatory insurance) as separate items where applicable, with
  the monthly cost reflected in notes (e.g. "Monthly patent fee ~6000
  RUB" for Russia).
- Pick statusCode honestly: "required" if it's mandatory, "recommended" if
  consulates ask for it often, "optional" otherwise.

Per item return:
- id (string, lower_snake_case): stable identifier
- title (string): exact local-language-friendly name (e.g. "Work patent
  (патент на работу)" for Russia)
- issuer (string): who issues it (e.g. "Embassy / VFS", "GUVM",
  "MFA attestation", "You")
- statusCode (string): "required" | "recommended" | "optional"
- iconHint (string): ONE of: passport, id, visa, diploma, transcript,
  language, motivation, finance, cv, contract, criminal, family,
  business_plan, translate, other
- description (string, 1–2 sentences): plain-English explanation of what
  it is and the headline thing to get right
- validityYears (int): years of validity, 0 if N/A
- costUsd (int): approximate UPFRONT cost in USD, 0 if free/unknown.
  For recurring fees use the monthly amount and mention "(monthly)" in
  notes.
- notes (array of 0–3 short strings): caveats, where to apply, monthly /
  yearly costs, deadlines.
"""
    return await _json(ai, prompt, _DOCUMENTS_SCHEMA, req.locale)
