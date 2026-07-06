import logging

from fastapi import HTTPException, Request

from .config import get_settings

logger = logging.getLogger("globaly.auth")

try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth
    from firebase_admin import credentials
except ImportError:
    firebase_admin = None
    firebase_auth = None
    credentials = None


def init_firebase() -> None:
    settings = get_settings()
    if not settings.firebase_credentials:
        return
    if firebase_admin is None:
        raise RuntimeError(
            "FIREBASE_CREDENTIALS is set but firebase-admin is not installed"
        )
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(settings.firebase_credentials)
        )


def require_user(request: Request) -> str | None:
    settings = get_settings()
    if not settings.firebase_credentials:
        return None
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    try:
        decoded = firebase_auth.verify_id_token(header[7:])
    except Exception as e:
        logger.warning("Token verification failed: %s", e)
        raise HTTPException(status_code=401, detail="invalid token") from e
    return decoded.get("uid")
