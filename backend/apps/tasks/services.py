import json

from django.conf import settings
from django.utils import timezone
from openai import OpenAI

from apps.tasks.models import BUDGET_TIER_BANDS, Task

# Canonical category vocabulary — matches the skill names already used
# elsewhere in the app (apps.taskers.Skill, the Flutter demo category grid),
# so a task posted here lines up with the same categories workers list
# skills under.
CANONICAL_CATEGORIES = [
    "Plumber",
    "Electrician",
    "Cleaner",
    "Carpenter",
    "AC Technician",
    "Tutor",
    "Handyman",
    "Gardener",
    "Delivery",
]

REQUIRED_FIELDS = ["category", "title", "date", "time", "urgency"]

CATEGORY_BASE_MMK = {
    "Plumber": 15000,
    "Electrician": 18000,
    "Cleaner": 10000,
    "Carpenter": 20000,
    "AC Technician": 22000,
    "Tutor": 12000,
    "Handyman": 13000,
    "Gardener": 9000,
    "Delivery": 6000,
}
DEFAULT_BASE_MMK = 12000

TIER_MULTIPLIER = {"ECONOMY": 0.7, "STANDARD": 1.0, "PROFESSIONAL": 1.6}
URGENT_SURCHARGE_MULTIPLIER = 1.2


class AIServiceUnavailable(Exception):
    """Raised when OPENAI_API_KEY isn't configured, or the OpenAI call
    itself fails — callers turn this into a clear 503 instead of a 500."""


def _client():
    if not settings.OPENAI_API_KEY:
        raise AIServiceUnavailable("AI features are not configured on this server.")
    return OpenAI(api_key=settings.OPENAI_API_KEY)


def transcribe_audio(file_bytes, filename="audio.m4a", content_type="audio/m4a"):
    """Whisper speech-to-text. file_bytes: raw audio bytes. Returns the
    recognized text (Burmese or English — Whisper auto-detects)."""
    client = _client()
    try:
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=(filename, file_bytes, content_type),
        )
    except Exception as exc:  # noqa: BLE001 — surface any SDK/network failure uniformly
        raise AIServiceUnavailable(f"Speech-to-text failed: {exc}") from exc
    return transcript.text


def analyze_task(message, history, known_fields):
    """GPT task-info extraction — one conversational turn.

    history: list of {"role": "user"|"assistant", "content": str} from
        earlier turns (does not include `message`, the newest one).
    known_fields: dict, a subset of REQUIRED_FIELDS already collected.

    Returns {"fields": dict, "question": str | None, "ready": bool}.
    `ready` is True once every required field is present — the caller
    moves on to budget recommendation at that point and stops asking.
    """
    client = _client()
    system_prompt = (
        "You are a task-extraction assistant for TOLY MOLY, a Myanmar "
        "on-demand service marketplace. Extract structured task "
        "information from the client's message(s) — they may write in "
        "Burmese or English.\n\n"
        f"Valid categories (pick the closest match, or null if truly "
        f"unclear): {', '.join(CANONICAL_CATEGORIES)}.\n\n"
        "Required fields: category, title (a short task summary), "
        "date (YYYY-MM-DD), time (HH:MM in 24h), urgency (\"NORMAL\" or "
        "\"URGENT\").\n\n"
        "Respond with ONLY a JSON object of this exact shape:\n"
        '{"category": string|null, "title": string|null, "date": '
        'string|null, "time": string|null, "urgency": string|null, '
        '"question": string|null}\n\n'
        f"Known fields so far: {json.dumps(known_fields)}\n"
        "Merge new information into the known fields — never discard a "
        "known field unless the user's new message clearly changes it.\n"
        "Resolve relative dates (\"tomorrow\", \"မနက်ဖြန်\") against "
        f"today's date, {timezone.localdate().isoformat()}.\n"
        "If any required field is still missing after merging, set "
        '"question" to one short, friendly Burmese question asking for '
        "exactly one missing field (the most important one) — never ask "
        "for more than one field at a time. If nothing is missing, set "
        '"question" to null.'
    )
    messages = [{"role": "system", "content": system_prompt}, *history, {"role": "user", "content": message}]

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            response_format={"type": "json_object"},
            temperature=0.2,
        )
        data = json.loads(response.choices[0].message.content)
    except Exception as exc:  # noqa: BLE001
        raise AIServiceUnavailable(f"Task analysis failed: {exc}") from exc

    extracted = {field: data.get(field) for field in REQUIRED_FIELDS if data.get(field)}
    merged_fields = {**known_fields, **extracted}
    missing = [field for field in REQUIRED_FIELDS if not merged_fields.get(field)]

    return {
        "fields": merged_fields,
        "question": data.get("question") if missing else None,
        "ready": not missing,
    }


def compute_budget_options(category, urgency):
    """Deterministic — no GPT call needed, same spirit as the Flutter
    offline flow's ai_mock.dart suggestBudget: a per-category base price,
    a tier multiplier, and an urgency surcharge. Returns one entry per
    BUDGET_TIER_BANDS key."""
    base = CATEGORY_BASE_MMK.get(category, DEFAULT_BASE_MMK)
    urgent_multiplier = URGENT_SURCHARGE_MULTIPLIER if urgency == Task.URGENCY_URGENT else 1.0

    options = {}
    for tier_name, (tier_min, tier_max) in BUDGET_TIER_BANDS.items():
        amount = base * TIER_MULTIPLIER[tier_name] * urgent_multiplier
        rounded = round(amount / 500) * 500
        options[tier_name] = {
            "worker_tier_min": tier_min,
            "worker_tier_max": tier_max,
            "budget_mmk": rounded,
        }
    return options
