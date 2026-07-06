from pydantic import BaseModel


class RateResponse(BaseModel):
    from_code: str
    to_code: str
    rate: float
    source: str


class CountryCurrencyResponse(BaseModel):
    country: str
    currency: str
