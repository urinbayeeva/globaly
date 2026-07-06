def test_health_reports_providers(client):
    res = client.get("/health")
    assert res.status_code == 200
    body = res.json()
    assert body["status"] == "ok"
    assert body["providers"] == {"gemini": True, "groq": True, "resend": False}
