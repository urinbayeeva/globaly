from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_ai
from ..schemas.ai import JsonRequest, JsonResponse, TextRequest, TextResponse
from ..services.gateway import AiGateway
from .common import mapped

router = APIRouter(
    prefix="/v1/ai", tags=["ai"], dependencies=[Depends(require_user)]
)


@router.post("/text", response_model=TextResponse)
async def generate_text(
    req: TextRequest, ai: AiGateway = Depends(get_ai)
) -> TextResponse:
    return TextResponse(text=await mapped(lambda: ai.generate_text(req)))


@router.post("/json", response_model=JsonResponse)
async def generate_json(
    req: JsonRequest, ai: AiGateway = Depends(get_ai)
) -> JsonResponse:
    return JsonResponse(data=await mapped(lambda: ai.generate_json(req)))
