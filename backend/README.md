# Globaly Backend

FastAPI service that moves the Gemini, Groq and Resend API keys off the Flutter
client. Mirrors the behaviour of `GeminiClient`, `GroqClient`, `EmailService`
and `CurrencyService` from the app: same model failover chain, locale
directives, Groq fallback, offline FX rates.

## Run locally

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # keyinguni to'ldiring
uvicorn app.main:app --reload
```

Docs: http://127.0.0.1:8000/docs

## Tests

```bash
pip install -r requirements-dev.txt
python -m pytest
```

## Docker

```bash
docker build -t globaly-api backend
docker run -p 8000:8000 --env-file backend/.env globaly-api
```

## Environment

| Variable | Purpose |
| --- | --- |
| `GEMINI_API_KEY` | Google AI Studio key (primary provider) |
| `GROQ_API_KEY` | Groq key (fallback provider) |
| `RESEND_API_KEY` | Resend key for OTP emails; empty = dev mode (code logged) |
| `RESEND_FROM` | From address for OTP emails |
| `FIREBASE_CREDENTIALS` | Path to a Firebase service-account JSON; when set, `/v1/ai/*` and `/v1/email/*` require `Authorization: Bearer <Firebase ID token>` |
| `CORS_ORIGINS` | Comma-separated allowed origins (`*` by default) |
| `AI_CACHE_TTL_SECONDS` | How long deterministic AI responses are cached (default `21600` = 6h) |
| `AI_CACHE_MAX_ENTRIES` | Max cached AI responses before oldest are evicted (default `512`) |

## Response caching

Deterministic feature endpoints (`/v1/culture`, `/v1/universities/insights`,
`/v1/cost-of-living`, `/v1/recommendations/*`) cache their AI result by request
content. Identical requests are served from memory instead of re-calling the
provider, and concurrent identical requests are coalesced into a **single**
upstream call (single-flight), so a burst of users asking the same thing costs
one API call rather than one per user. Per-user or image endpoints (`/v1/chat`,
`/v1/interview`, `/v1/scan`, `/v1/translate`, `/v1/ai/*`) are never cached.

## Endpoints

Feature APIs (prompts and schemas live server-side):

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| POST | `/v1/chat` | `{message, history?, image_base64?, image_mime_type?, destination_country?, purpose?, locale?}` | `{text}` |
| POST | `/v1/universities/insights` | `{name, location?, website?, locale?}` | admission profile JSON |
| POST | `/v1/recommendations/destinations` | `{country, locale?}` | `{items: [...]}` |
| POST | `/v1/recommendations/hotels` | `{country, city?, locale?}` | `{items: [...]}` |
| POST | `/v1/recommendations/jobs` | `{country, field, language, experience_years, locale?}` | `{items: [...]}` |
| POST | `/v1/recommendations/business` | `{country, locale?}` | `{items: [...]}` |
| POST | `/v1/recommendations/visa-info` | `{country, purpose, locale?}` | visa pathway JSON |
| POST | `/v1/recommendations/roadmap` | `{country, purpose, locale?}` | `{headline, steps}` |
| POST | `/v1/recommendations/documents` | `{country, purpose, origin_country?, locale?}` | `{items: [...]}` |
| POST | `/v1/cost-of-living` | `{country, locale?}` | `{items: [...]}` |
| POST | `/v1/culture` | `{country, locale?}` | culture briefing JSON |
| POST | `/v1/interview/next` | `{turns, latest_answer?, country?, purpose?, locale?}` | interview exchange JSON |
| POST | `/v1/scan/analyze` | `{image_base64, image_mime_type?, locale?}` | contract analysis JSON |
| POST | `/v1/translate/document` | `{image_base64, image_mime_type?, locale?}` | translation JSON |

Infrastructure APIs:

| Method | Path | Body / query | Returns |
| --- | --- | --- | --- |
| GET | `/health` | — | `{status, providers}` |
| POST | `/v1/ai/text` | generic Gemini/Groq text proxy | `{text}` |
| POST | `/v1/ai/json` | generic Gemini/Groq structured proxy | `{data}` |
| POST | `/v1/email/otp` | `{email, code, name?}` | `{sent, dev}` |
| GET | `/v1/currency/rate?from=USD&to=UZS` | — | `{from_code, to_code, rate, source}` |
| GET | `/v1/currency/country/UZ` | — | `{country, currency}` |

`history` turns use the Gemini roles: `{"role": "user" | "model", "text": "..."}`.
`locale` (`en` / `ru` / `uz`) sets the response language. Rate limiting maps to
HTTP 429 with a `Retry-After` header; upstream failures map to 502. When
`FIREBASE_CREDENTIALS` is set, all `/v1/*` AI and email routes require
`Authorization: Bearer <Firebase ID token>`.

The Flutter app calls these through `lib/core/services/backend_api.dart`; the
`locale` field is attached automatically from the app's language setting.
