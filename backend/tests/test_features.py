import json

import httpx
import respx

GEMINI = "https://generativelanguage.googleapis.com/v1beta/models"


def gemini_json_payload(data: dict) -> dict:
    return {
        "candidates": [{"content": {"parts": [{"text": json.dumps(data)}]}}]
    }


def gemini_text_payload(text: str) -> dict:
    return {"candidates": [{"content": {"parts": [{"text": text}]}}]}


def test_chat_returns_text(client):
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_text_payload("Salom!"))
        )
        res = client.post(
            "/v1/chat",
            json={
                "message": "salom",
                "history": [{"role": "user", "text": "oldingi savol"}],
                "destination_country": "Germany",
                "purpose": "study",
                "locale": "uz",
            },
        )
    assert res.status_code == 200
    assert res.json() == {"text": "Salom!"}


def test_destinations_returns_items(client):
    payload = {"items": [{"name": "Munich", "region": "Bavaria",
                          "summary": "s", "bestSeason": ""}]}
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        res = client.post(
            "/v1/recommendations/destinations", json={"country": "Germany"}
        )
    assert res.status_code == 200
    assert res.json() == payload


def test_university_insights(client):
    payload = {
        "acceptsInternational": True, "minIelts": 6.5, "minToefl": 80,
        "minSat": 0, "scholarshipAvailable": True, "scholarshipPercent": 50,
        "scholarshipName": "DAAD", "notes": "n",
    }
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        res = client.post(
            "/v1/universities/insights",
            json={"name": "TUM", "location": "Munich, Germany",
                  "website": "https://tum.de"},
        )
    assert res.status_code == 200
    assert res.json() == payload


def test_interview_next(client):
    payload = {"feedback": "", "question": "Why Germany?", "done": False,
               "assessment": "", "score": 0, "tips": []}
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        res = client.post(
            "/v1/interview/next",
            json={"turns": [], "country": "Germany", "purpose": "study"},
        )
    assert res.status_code == 200
    assert res.json()["question"] == "Why Germany?"


def test_scan_requires_image(client):
    res = client.post("/v1/scan/analyze", json={})
    assert res.status_code == 422


def test_cost_of_living(client):
    payload = {"items": [{"city": "Berlin", "rentMonthly": 900,
                          "foodMonthly": 300, "transportMonthly": 60,
                          "miscMonthly": 150}]}
    with respx.mock:
        respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        res = client.post("/v1/cost-of-living", json={"country": "Germany"})
    assert res.status_code == 200
    assert res.json() == payload
