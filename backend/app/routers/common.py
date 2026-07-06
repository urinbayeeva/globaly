from collections.abc import Awaitable, Callable
from typing import TypeVar

from fastapi import HTTPException

from ..errors import ProviderRateLimited, ProviderUnavailable

T = TypeVar("T")


async def mapped(call: Callable[[], Awaitable[T]]) -> T:
    try:
        return await call()
    except ProviderRateLimited as e:
        raise HTTPException(
            status_code=429,
            detail="AI providers rate limited",
            headers={"Retry-After": str(int(e.retry_after_seconds))},
        ) from e
    except ProviderUnavailable as e:
        raise HTTPException(status_code=502, detail=e.detail) from e
