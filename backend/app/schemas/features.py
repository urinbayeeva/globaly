from pydantic import BaseModel, Field


class LocalisedRequest(BaseModel):
    locale: str = "en"


class ChatTurn(BaseModel):
    role: str = "user"
    text: str = ""


class ChatRequest(LocalisedRequest):
    message: str = ""
    history: list[ChatTurn] = Field(default_factory=list)
    image_base64: str | None = None
    image_mime_type: str = "image/jpeg"
    destination_country: str = ""
    purpose: str = "study"


class UniversityInsightsRequest(LocalisedRequest):
    name: str
    location: str = ""
    website: str = ""


class CountryRequest(LocalisedRequest):
    country: str


class HotelsRequest(CountryRequest):
    city: str = ""


class JobsRequest(CountryRequest):
    field: str
    language: str
    experience_years: int = 0


class PurposeRequest(CountryRequest):
    purpose: str = "study"


class DocumentsRequest(PurposeRequest):
    origin_country: str = ""


class InterviewTurn(BaseModel):
    question: str = ""
    answer: str = ""


class InterviewRequest(LocalisedRequest):
    turns: list[InterviewTurn] = Field(default_factory=list)
    latest_answer: str = ""
    country: str = ""
    purpose: str = "study"


class ImageRequest(LocalisedRequest):
    image_base64: str
    image_mime_type: str = "image/jpeg"
