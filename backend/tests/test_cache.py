import asyncio
import json

import httpx
import respx

from app.services.cache import ResponseCache

GEMINI = "https://generativelanguage.googleapis.com/v1beta/models"


def gemini_json_payload(data: dict) -> dict:
    return {
        "candidates": [{"content": {"parts": [{"text": json.dumps(data)}]}}]
    }


def test_single_flight_collapses_concurrent_calls():
    async def scenario():
        cache = ResponseCache(ttl_seconds=60)
        calls = 0
        release = asyncio.Event()

        async def factory():
            nonlocal calls
            calls += 1
            await release.wait()
            return {"n": calls}

        tasks = [
            asyncio.ensure_future(cache.get_or_create("k", factory))
            for _ in range(50)
        ]
        await asyncio.sleep(0.05)
        release.set()
        results = await asyncio.gather(*tasks)
        return calls, results

    calls, results = asyncio.run(scenario())
    assert calls == 1
    assert all(r == {"n": 1} for r in results)


def test_ttl_hit_avoids_second_call():
    async def scenario():
        cache = ResponseCache(ttl_seconds=60)
        calls = 0

        async def factory():
            nonlocal calls
            calls += 1
            return {"n": calls}

        a = await cache.get_or_create("k", factory)
        b = await cache.get_or_create("k", factory)
        return calls, a, b

    calls, a, b = asyncio.run(scenario())
    assert calls == 1
    assert a == b == {"n": 1}


def test_distinct_keys_fetch_separately():
    async def scenario():
        cache = ResponseCache(ttl_seconds=60)
        calls = 0

        async def factory():
            nonlocal calls
            calls += 1
            return calls

        await cache.get_or_create("a", factory)
        await cache.get_or_create("b", factory)
        return calls

    assert asyncio.run(scenario()) == 2


def test_error_is_not_cached():
    async def scenario():
        cache = ResponseCache(ttl_seconds=60)
        calls = 0

        async def factory():
            nonlocal calls
            calls += 1
            if calls == 1:
                raise RuntimeError("boom")
            return {"ok": True}

        try:
            await cache.get_or_create("k", factory)
        except RuntimeError:
            pass
        result = await cache.get_or_create("k", factory)
        return calls, result

    calls, result = asyncio.run(scenario())
    assert calls == 2
    assert result == {"ok": True}


def test_expired_entry_is_refetched():
    async def scenario():
        cache = ResponseCache(ttl_seconds=0)
        calls = 0

        async def factory():
            nonlocal calls
            calls += 1
            return calls

        await cache.get_or_create("k", factory)
        await cache.get_or_create("k", factory)
        return calls

    assert asyncio.run(scenario()) == 2


def test_endpoint_caches_identical_requests(client):
    payload = {"items": [{"city": "Berlin", "rentMonthly": 900,
                          "foodMonthly": 300, "transportMonthly": 60,
                          "miscMonthly": 150}]}
    with respx.mock:
        route = respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        first = client.post("/v1/cost-of-living", json={"country": "Germany"})
        second = client.post("/v1/cost-of-living", json={"country": "Germany"})
    assert first.json() == second.json() == payload
    assert route.call_count == 1


def test_endpoint_varies_by_request(client):
    payload = {"items": [{"city": "Berlin", "rentMonthly": 900,
                          "foodMonthly": 300, "transportMonthly": 60,
                          "miscMonthly": 150}]}
    with respx.mock:
        route = respx.post(url__startswith=GEMINI).mock(
            return_value=httpx.Response(200, json=gemini_json_payload(payload))
        )
        client.post("/v1/cost-of-living", json={"country": "Germany"})
        client.post("/v1/cost-of-living", json={"country": "France"})
    assert route.call_count == 2
