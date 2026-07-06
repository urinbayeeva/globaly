from fastapi import APIRouter, Depends

from ..auth import require_user
from ..dependencies import get_email
from ..schemas.email import OtpRequest, OtpResponse
from ..services.email import EmailService

router = APIRouter(
    prefix="/v1/email", tags=["email"], dependencies=[Depends(require_user)]
)


@router.post("/otp", response_model=OtpResponse)
async def send_otp(
    req: OtpRequest, service: EmailService = Depends(get_email)
) -> OtpResponse:
    sent = await service.send_otp(email=req.email, code=req.code, name=req.name)
    return OtpResponse(sent=sent, dev=not service.is_configured)
