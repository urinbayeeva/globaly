from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class HistoryTurn(BaseModel):
    role: str = "user"
    text: str = ""


class TextRequest(BaseModel):
    prompt: str
    system_prompt: str = ""
    history: list[HistoryTurn] = Field(default_factory=list)
    temperature: float = Field(default=0.6, ge=0.0, le=2.0)
    max_output_tokens: int = Field(default=1024, gt=0, le=8192)
    image_base64: str | None = None
    image_mime_type: str = "image/jpeg"
    locale: str = "en"


class TextResponse(BaseModel):
    text: str


class JsonRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    prompt: str
    json_schema: dict[str, Any] = Field(alias="schema")
    temperature: float = Field(default=0.2, ge=0.0, le=2.0)
    image_base64: str | None = None
    image_mime_type: str = "image/jpeg"
    locale: str = "en"


class JsonResponse(BaseModel):
    data: dict[str, Any]
