import httpx
import respx


def test_dev_mode_when_resend_not_configured(client):
    res = client.post(
        "/v1/email/otp",
        json={"email": "user@example.com", "code": "123456"},
    )
    assert res.status_code == 200
    assert res.json() == {"sent": True, "dev": True}


def test_invalid_code_rejected(client):
    res = client.post(
        "/v1/email/otp",
        json={"email": "user@example.com", "code": "abc"},
    )
    assert res.status_code == 422


def test_sends_via_resend_when_configured(client, monkeypatch):
    client.app.state.email._key = "re_test"
    with respx.mock:
        respx.post("https://api.resend.com/emails").mock(
            return_value=httpx.Response(200, json={"id": "1"})
        )
        res = client.post(
            "/v1/email/otp",
            json={"email": "user@example.com", "code": "123456", "name": "Ali"},
        )
    assert res.json() == {"sent": True, "dev": False}
