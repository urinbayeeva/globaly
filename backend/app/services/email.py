import logging

import httpx

from ..config import Settings

_ENDPOINT = "https://api.resend.com/emails"

logger = logging.getLogger("globaly.email")


class EmailService:
    def __init__(self, http: httpx.AsyncClient, settings: Settings):
        self._http = http
        self._key = settings.resend_api_key
        self._from = settings.resend_from

    @property
    def is_configured(self) -> bool:
        return bool(self._key)

    async def send_otp(self, *, email: str, code: str, name: str | None) -> bool:
        if not self.is_configured:
            logger.warning("RESEND_API_KEY missing — DEV OTP for %s: %s", email, code)
            return True
        try:
            res = await self._http.post(
                _ENDPOINT,
                headers={"Authorization": f"Bearer {self._key}"},
                json={
                    "from": self._from,
                    "to": [email],
                    "subject": f"Globaly — verification code: {code}",
                    "html": self._html(code=code, name=name),
                    "text": (
                        f"Your Globaly verification code is {code}. "
                        "It expires in 10 minutes."
                    ),
                },
            )
        except httpx.HTTPError as e:
            logger.warning("Resend error: %s", e)
            return False
        if 200 <= res.status_code < 300:
            return True
        logger.warning("Resend failed (%s): %s", res.status_code, res.text)
        return False

    def _html(self, *, code: str, name: str | None) -> str:
        hello = "Hello," if not name or not name.strip() else f"Hello {name.strip()},"
        return f"""<!DOCTYPE html>
<html>
  <body style="margin:0;background:#F6F7F9;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <div style="max-width:480px;margin:0 auto;padding:32px 24px;">
      <div style="background:#ffffff;border-radius:16px;padding:32px;border:1px solid #E6E8EC;">
        <h1 style="margin:0 0 8px;font-size:20px;color:#0B1220;">Globaly</h1>
        <p style="margin:0 0 24px;color:#4B5360;font-size:15px;">{hello}</p>
        <p style="margin:0 0 16px;color:#4B5360;font-size:15px;">
          Use this code to verify your email and finish creating your account:
        </p>
        <div style="font-size:34px;font-weight:700;letter-spacing:10px;color:#DC1F2E;text-align:center;padding:20px 0;background:#FEECEE;border-radius:12px;">
          {code}
        </div>
        <p style="margin:20px 0 0;color:#6B7280;font-size:13px;">
          This code expires in 10 minutes. If you didn't request it, you can
          safely ignore this email.
        </p>
      </div>
      <p style="text-align:center;color:#9CA3B0;font-size:12px;margin-top:16px;">
        © Globaly — your guide for moving abroad
      </p>
    </div>
  </body>
</html>"""
