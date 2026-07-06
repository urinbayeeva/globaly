import logging
import time

import httpx

from ..config import Settings

_ENDPOINT = "https://api.frankfurter.dev/v1/latest"

logger = logging.getLogger("globaly.currency")

FRANKFURTER_SUPPORTED = {
    "AUD", "BGN", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP",
    "HKD", "HUF", "IDR", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR",
    "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD",
    "ZAR",
}

USD_FALLBACK = {
    "UZS": 12600, "RUB": 90, "KZT": 480, "KGS": 88, "TJS": 10.5, "TMT": 3.5,
    "AZN": 1.7, "AMD": 388, "GEL": 2.7, "BYN": 3.25, "UAH": 41, "MDL": 18,
    "AED": 3.67, "SAR": 3.75, "QAR": 3.64, "EGP": 49, "PKR": 280, "BDT": 120,
    "LKR": 295, "NPR": 134, "VND": 25300, "IRR": 42000, "IQD": 1310,
    "JOD": 0.71, "LBP": 89500, "NGN": 1600, "KES": 129, "GHS": 15,
    "TZS": 2700, "UGX": 3700, "XOF": 605, "XAF": 605, "MAD": 9.9, "TND": 3.1,
    "DZD": 134, "COP": 4200, "CLP": 970, "ARS": 1010, "PEN": 3.78, "VES": 49,
    "BOB": 6.91, "UYU": 42, "PYG": 7900, "CRC": 510, "DOP": 60, "GTQ": 7.8,
    "HNL": 25, "HTG": 132, "JMD": 159, "NIO": 36.8, "PAB": 1, "BHD": 0.38,
    "OMR": 0.38, "KWD": 0.31, "YER": 250, "BAM": 1.78, "RSD": 107, "MKD": 56,
    "ALL": 91, "ISK": 138,
}

COUNTRY_TO_CURRENCY = {
    "AF": "AFN", "AL": "ALL", "DZ": "DZD", "AD": "EUR", "AO": "AOA",
    "AG": "XCD", "AR": "ARS", "AM": "AMD", "AU": "AUD", "AT": "EUR",
    "AZ": "AZN", "BS": "BSD", "BH": "BHD", "BD": "BDT", "BB": "BBD",
    "BY": "BYN", "BE": "EUR", "BZ": "BZD", "BJ": "XOF", "BT": "BTN",
    "BO": "BOB", "BA": "BAM", "BW": "BWP", "BR": "BRL", "BN": "BND",
    "BG": "BGN", "BF": "XOF", "BI": "BIF", "KH": "KHR", "CM": "XAF",
    "CA": "CAD", "CV": "CVE", "CF": "XAF", "TD": "XAF", "CL": "CLP",
    "CN": "CNY", "CO": "COP", "KM": "KMF", "CG": "XAF", "CD": "CDF",
    "CR": "CRC", "CI": "XOF", "HR": "EUR", "CU": "CUP", "CY": "EUR",
    "CZ": "CZK", "DK": "DKK", "DJ": "DJF", "DM": "XCD", "DO": "DOP",
    "EC": "USD", "EG": "EGP", "SV": "USD", "GQ": "XAF", "ER": "ERN",
    "EE": "EUR", "SZ": "SZL", "ET": "ETB", "FJ": "FJD", "FI": "EUR",
    "FR": "EUR", "GA": "XAF", "GM": "GMD", "GE": "GEL", "DE": "EUR",
    "GH": "GHS", "GR": "EUR", "GD": "XCD", "GT": "GTQ", "GN": "GNF",
    "GW": "XOF", "GY": "GYD", "HT": "HTG", "HN": "HNL", "HK": "HKD",
    "HU": "HUF", "IS": "ISK", "IN": "INR", "ID": "IDR", "IR": "IRR",
    "IQ": "IQD", "IE": "EUR", "IL": "ILS", "IT": "EUR", "JM": "JMD",
    "JP": "JPY", "JO": "JOD", "KZ": "KZT", "KE": "KES", "KI": "AUD",
    "KW": "KWD", "KG": "KGS", "LA": "LAK", "LV": "EUR", "LB": "LBP",
    "LS": "LSL", "LR": "LRD", "LY": "LYD", "LI": "CHF", "LT": "EUR",
    "LU": "EUR", "MO": "MOP", "MG": "MGA", "MW": "MWK", "MY": "MYR",
    "MV": "MVR", "ML": "XOF", "MT": "EUR", "MH": "USD", "MR": "MRU",
    "MU": "MUR", "MX": "MXN", "FM": "USD", "MD": "MDL", "MC": "EUR",
    "MN": "MNT", "ME": "EUR", "MA": "MAD", "MZ": "MZN", "MM": "MMK",
    "NA": "NAD", "NR": "AUD", "NP": "NPR", "NL": "EUR", "NZ": "NZD",
    "NI": "NIO", "NE": "XOF", "NG": "NGN", "KP": "KPW", "MK": "MKD",
    "NO": "NOK", "OM": "OMR", "PK": "PKR", "PW": "USD", "PS": "ILS",
    "PA": "PAB", "PG": "PGK", "PY": "PYG", "PE": "PEN", "PH": "PHP",
    "PL": "PLN", "PT": "EUR", "QA": "QAR", "RO": "RON", "RU": "RUB",
    "RW": "RWF", "KN": "XCD", "LC": "XCD", "VC": "XCD", "WS": "WST",
    "SM": "EUR", "ST": "STN", "SA": "SAR", "SN": "XOF", "RS": "RSD",
    "SC": "SCR", "SL": "SLE", "SG": "SGD", "SK": "EUR", "SI": "EUR",
    "SB": "SBD", "SO": "SOS", "ZA": "ZAR", "KR": "KRW", "SS": "SSP",
    "ES": "EUR", "LK": "LKR", "SD": "SDG", "SR": "SRD", "SE": "SEK",
    "CH": "CHF", "SY": "SYP", "TW": "TWD", "TJ": "TJS", "TZ": "TZS",
    "TH": "THB", "TL": "USD", "TG": "XOF", "TO": "TOP", "TT": "TTD",
    "TN": "TND", "TR": "TRY", "TM": "TMT", "TV": "AUD", "UG": "UGX",
    "UA": "UAH", "AE": "AED", "GB": "GBP", "US": "USD", "UY": "UYU",
    "UZ": "UZS", "VU": "VUV", "VA": "EUR", "VE": "VES", "VN": "VND",
    "YE": "YER", "ZM": "ZMW", "ZW": "ZWL",
}


class CurrencyService:
    def __init__(self, http: httpx.AsyncClient, settings: Settings):
        self._http = http
        self._ttl = settings.currency_cache_ttl_seconds
        self._cache: dict[str, tuple[float, float]] = {}

    def currency_for(self, country_code: str) -> str | None:
        return COUNTRY_TO_CURRENCY.get(country_code.upper())

    async def rate(self, from_code: str, to_code: str) -> tuple[float, str] | None:
        if from_code == to_code:
            return 1.0, "identity"
        cached = self._cached(from_code, to_code)
        if cached is not None:
            return cached

        live_supported = (
            from_code in FRANKFURTER_SUPPORTED and to_code in FRANKFURTER_SUPPORTED
        )
        if live_supported:
            live = await self._fetch(from_code, to_code)
            if live is not None:
                self._store(from_code, to_code, live)
                return live, "frankfurter"

        offline = self._offline_rate(from_code, to_code)
        if offline is not None:
            self._store(from_code, to_code, offline)
            return offline, "fallback"
        return None

    def _cached(self, from_code: str, to_code: str) -> tuple[float, str] | None:
        entry = self._cache.get(f"{from_code}|{to_code}")
        if entry is None:
            return None
        value, stored_at = entry
        if time.monotonic() - stored_at > self._ttl:
            return None
        return value, "cache"

    def _store(self, from_code: str, to_code: str, value: float) -> None:
        self._cache[f"{from_code}|{to_code}"] = (value, time.monotonic())

    def _offline_rate(self, from_code: str, to_code: str) -> float | None:
        from_per_usd = 1.0 if from_code == "USD" else USD_FALLBACK.get(from_code)
        to_per_usd = 1.0 if to_code == "USD" else USD_FALLBACK.get(to_code)
        if from_per_usd is None or to_per_usd is None:
            return None
        return to_per_usd / from_per_usd

    async def _fetch(self, from_code: str, to_code: str) -> float | None:
        try:
            res = await self._http.get(
                _ENDPOINT, params={"base": from_code, "symbols": to_code}
            )
            raw = res.json().get("rates", {}).get(to_code)
            return float(raw) if isinstance(raw, (int, float)) else None
        except (httpx.HTTPError, ValueError) as e:
            logger.warning("FX %s→%s failed: %s", from_code, to_code, e)
            return None
