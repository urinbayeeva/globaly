class ProviderRateLimited(Exception):
    def __init__(self, retry_after_seconds: float = 60.0):
        super().__init__(f"rate limited, retry after {retry_after_seconds}s")
        self.retry_after_seconds = retry_after_seconds


class ProviderUnavailable(Exception):
    def __init__(self, detail: str):
        super().__init__(detail)
        self.detail = detail
