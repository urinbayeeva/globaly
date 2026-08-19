import asyncio
import hashlib
import json
import time
from collections.abc import Awaitable, Callable
from typing import Any


class ResponseCache:
    def __init__(self, ttl_seconds: int, max_entries: int = 512):
        self._ttl = ttl_seconds
        self._max = max_entries
        self._store: dict[str, tuple[float, Any]] = {}
        self._inflight: dict[str, asyncio.Task[Any]] = {}
        self._lock = asyncio.Lock()

    @staticmethod
    def key(payload: Any) -> str:
        raw = json.dumps(payload, sort_keys=True, ensure_ascii=False, default=str)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    async def get_or_create(
        self, key: str, factory: Callable[[], Awaitable[Any]]
    ) -> Any:
        async with self._lock:
            fresh = self._fresh(key)
            if fresh is not None:
                return fresh
            task = self._inflight.get(key)
            if task is None:
                task = asyncio.ensure_future(self._produce(key, factory))
                self._inflight[key] = task
        return await asyncio.shield(task)

    def _fresh(self, key: str) -> Any:
        entry = self._store.get(key)
        if entry is None:
            return None
        expires_at, value = entry
        if expires_at <= time.monotonic():
            del self._store[key]
            return None
        return value

    async def _produce(
        self, key: str, factory: Callable[[], Awaitable[Any]]
    ) -> Any:
        try:
            value = await factory()
        except BaseException:
            async with self._lock:
                self._inflight.pop(key, None)
            raise
        async with self._lock:
            self._store[key] = (time.monotonic() + self._ttl, value)
            self._inflight.pop(key, None)
            self._evict()
        return value

    def _evict(self) -> None:
        while len(self._store) > self._max:
            del self._store[next(iter(self._store))]
