from fastapi import Request

from .services.currency import CurrencyService
from .services.email import EmailService
from .services.gateway import AiGateway


def get_ai(request: Request) -> AiGateway:
    return request.app.state.ai


def get_email(request: Request) -> EmailService:
    return request.app.state.email


def get_currency(request: Request) -> CurrencyService:
    return request.app.state.currency
