from fastapi import APIRouter, Depends, Request

from ..dependencies import get_ai
from ..services.gateway import AiGateway

router = APIRouter(tags=["health"])


@router.get("/health")
async def health(request: Request, ai: AiGateway = Depends(get_ai)) -> dict:
    return {
        "status": "ok",
        "providers": {
            **ai.providers,
            "resend": request.app.state.email.is_configured,
        },
    }
