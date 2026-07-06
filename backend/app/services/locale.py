_DIRECTIVES = {
    "en": "Respond entirely in English.",
    "ru": (
        "Respond entirely in Russian (русский). All text fields, titles, "
        "descriptions, summaries, notes, and explanations must be in Russian. "
        "JSON keys stay in English. Numbers, dates and currency codes stay "
        "numeric."
    ),
    "uz": (
        "Respond entirely in Uzbek (O'zbek, Latin script). All text fields, "
        "titles, descriptions, summaries, notes, and explanations must be in "
        "Uzbek. JSON keys stay in English. Numbers, dates and currency codes "
        "stay numeric."
    ),
}


def directive(locale: str) -> str:
    return _DIRECTIVES.get(locale, _DIRECTIVES["en"])


def localised_prompt(prompt: str, locale: str) -> str:
    return f"{directive(locale)}\n\n{prompt}"


def composed_system(system_prompt: str, locale: str) -> str:
    if not system_prompt:
        return directive(locale)
    return f"{directive(locale)}\n\n{system_prompt}"
