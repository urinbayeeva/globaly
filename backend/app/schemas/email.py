from pydantic import BaseModel, EmailStr, Field


class OtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(pattern=r"^\d{4,8}$")
    name: str | None = None


class OtpResponse(BaseModel):
    sent: bool
    dev: bool = False
