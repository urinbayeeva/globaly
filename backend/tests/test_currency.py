import httpx
import respx


def test_offline_rate_for_unsupported_pair(client):
    res = client.get("/v1/currency/rate", params={"from": "USD", "to": "UZS"})
    assert res.status_code == 200
    body = res.json()
    assert body["rate"] == 12600
    assert body["source"] == "fallback"


def test_live_rate_from_frankfurter(client):
    with respx.mock:
        respx.get("https://api.frankfurter.dev/v1/latest").mock(
            return_value=httpx.Response(200, json={"rates": {"EUR": 0.9}})
        )
        res = client.get("/v1/currency/rate", params={"from": "USD", "to": "EUR"})
    assert res.json()["rate"] == 0.9
    assert res.json()["source"] == "frankfurter"


def test_identity_rate(client):
    res = client.get("/v1/currency/rate", params={"from": "USD", "to": "USD"})
    assert res.json()["rate"] == 1.0


def test_unknown_pair_returns_404(client):
    res = client.get("/v1/currency/rate", params={"from": "USD", "to": "AFN"})
    assert res.status_code == 404


def test_country_currency(client):
    res = client.get("/v1/currency/country/uz")
    assert res.json() == {"country": "UZ", "currency": "UZS"}
