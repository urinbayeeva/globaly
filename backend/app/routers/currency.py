from fastapi import APIRouter, Depends, HTTPException, Query

from ..dependencies import get_currency
from ..schemas.currency import CountryCurrencyResponse, RateResponse
from ..services.currency import CurrencyService

router = APIRouter(prefix="/v1/currency", tags=["currency"])


@router.get("/rate", response_model=RateResponse)
async def rate(
    from_code: str = Query(alias="from", min_length=3, max_length=3),
    to_code: str = Query(alias="to", min_length=3, max_length=3),
    currency: CurrencyService = Depends(get_currency),
) -> RateResponse:
    result = await currency.rate(from_code.upper(), to_code.upper())
    if result is None:
        raise HTTPException(status_code=404, detail="rate unavailable")
    value, source = result
    return RateResponse(
        from_code=from_code.upper(),
        to_code=to_code.upper(),
        rate=value,
        source=source,
    )


@router.get("/country/{country_code}", response_model=CountryCurrencyResponse)
async def country_currency(
    country_code: str, currency: CurrencyService = Depends(get_currency)
) -> CountryCurrencyResponse:
    code = currency.currency_for(country_code)
    if code is None:
        raise HTTPException(status_code=404, detail="unknown country code")
    return CountryCurrencyResponse(country=country_code.upper(), currency=code)
