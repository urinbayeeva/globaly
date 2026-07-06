import httpx
import respx

GEMINI = "https://generativelanguage.googleapis.com/v1beta/models"
GROQ = "https://api.groq.com/openai/v1/chat/completions"


def gemini_payload(text: str) -> dict:
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


def groq_payload(content: str) -> dict:
    return {"choices": [{"message": {"content": content}}]}


def test_text_uses_first_gemini_model(client):
    with respx.mock:
        respx.post(f"{GEMINI}/gemini-flash-latest:generateContent").mock(
            return_value=httpx.Response(200, json=gemini_payload("Salom!"))
        )
        res = client.post("/v1/ai/text", json={"prompt": "hi", "locale": "uz"})
    assert res.status_code == 200
    assert res.json() == {"text": "Salom!"}


def test_text_falls_through_gemini_models(client):
    with respx.mock:
        respx.post(f"{GEMINI}/gemini-flash-latest:generateContent").mock(
            return_value=httpx.Response(503)
        )
        respx.post(f"{GEMINI}/gemini-2.5-flash:generateContent").mock(
            return_value=httpx.Response(200, json=gemini_payload("second"))
        )
        res = client.post("/v1/ai/text", json={"prompt": "hi"})
    assert res.json()["text"] == "second"


def test_text_falls_back_to_groq_when_gemini_rate_limited(client):
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(429, json={"error": {}})
        )
        respx.post(GROQ).mock(
            return_value=httpx.Response(200, json=groq_payload("from groq"))
        )
        res = client.post("/v1/ai/text", json={"prompt": "hi"})
    assert res.status_code == 200
    assert res.json()["text"] == "from groq"


def test_json_parses_fenced_groq_output(client):
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(return_value=httpx.Response(500))
        respx.post(GROQ).mock(
            return_value=httpx.Response(
                200, json=groq_payload('```json\n{"ok": true}\n```')
            )
        )
        res = client.post(
            "/v1/ai/json",
            json={"prompt": "p", "schema": {"type": "object"}},
        )
    assert res.status_code == 200
    assert res.json()["data"] == {"ok": True}


def test_all_rate_limited_maps_to_429_with_retry_after(client):
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(429, json={"error": {}})
        )
        respx.post(GROQ).mock(return_value=httpx.Response(429))
        res = client.post("/v1/ai/text", json={"prompt": "hi"})
    assert res.status_code == 429
    assert "retry-after" in res.headers


def test_all_unavailable_maps_to_502(client):
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(return_value=httpx.Response(500))
        respx.post(GROQ).mock(return_value=httpx.Response(500))
        res = client.post("/v1/ai/text", json={"prompt": "hi"})
    assert res.status_code == 502
