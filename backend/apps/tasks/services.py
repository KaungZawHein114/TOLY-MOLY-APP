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


# Fields extract_task can return. `township` is a human-readable location
# label (mapped to Task.address on publish, since the model stores GPS in
# latitude/longitude, not a township name). urgency uses the Task choices.
EXTRACT_STRING_FIELDS = ["title", "description", "date", "time", "township"]


def extract_task(transcript):
    """One-shot task extraction from a single spoken/typed description.

    Unlike analyze_task (a conversational turn that asks for one missing
    field at a time), this makes ONE pass over the whole transcript and
    never asks a follow-up question — the caller drops the client straight
    on a review screen, showing "Not given" for anything the client didn't
    mention. Built for the voice-first "just say what you need" flow.

    transcript: the full text the client dictated (English or Burmese).

    Returns {"fields": dict} holding only the fields the model could fill
    from what was actually said — missing fields are omitted (not null), so
    the app can render them as "Not given". Nothing is ever invented.
    """
    client = _client()
    system_prompt = (
        "You are a task-extraction assistant for TOLY MOLY, a Myanmar "
        "on-demand home-service marketplace in Yangon. Extract structured "
        "task information from ONE message in which a client describes what "
        "they need. The client may write in Burmese or English.\n\n"
        f"Valid categories (pick the closest match, or null if truly "
        f"unclear): {', '.join(CANONICAL_CATEGORIES)}.\n\n"
        "Extract these fields:\n"
        "- category: one value from the list above, or null\n"
        "- title: a short 3-8 word summary of the task, or null\n"
        "- description: a clear one or two sentence description of the work, "
        "using ONLY details the client actually gave, or null\n"
        "- date: the requested date as YYYY-MM-DD, or null\n"
        "- time: the requested time as HH:MM in 24-hour form, or null\n"
        '- urgency: "URGENT" if the client signals urgency (emergency, '
        'today, right now, asap), otherwise "NORMAL"; null if not indicated\n'
        "- budget_mmk: the budget in Myanmar Kyat as a plain integer with no "
        "separators or currency text, or null\n"
        "- township: the Yangon township or location mentioned, or null\n\n"
        "Resolve relative dates (\"tomorrow\", \"this weekend\", "
        f'"မနက်ဖြန်") against today\'s date, {timezone.localdate().isoformat()}.\n'
        "Only fill a field when the client actually provided that "
        "information. Use null for anything they did not say — never guess a "
        "budget, date, or time that was not stated.\n\n"
        "Respond with ONLY a JSON object of this exact shape:\n"
        '{"category": string|null, "title": string|null, "description": '
        'string|null, "date": string|null, "time": string|null, "urgency": '
        'string|null, "budget_mmk": integer|null, "township": string|null}'
    )

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": transcript},
            ],
            response_format={"type": "json_object"},
            temperature=0.2,
        )
        data = json.loads(response.choices[0].message.content)
    except Exception as exc:  # noqa: BLE001 — surface any SDK/network failure uniformly
        raise AIServiceUnavailable(f"Task extraction failed: {exc}") from exc

    # Keep only what the model actually filled; validate the constrained ones
    # so a bad value can never reach the review screen or the database.
    fields = {}
    if data.get("category") in CANONICAL_CATEGORIES:
        fields["category"] = data["category"]
    for key in EXTRACT_STRING_FIELDS:
        value = data.get(key)
        if isinstance(value, str) and value.strip():
            fields[key] = value.strip()
    if data.get("urgency") in (Task.URGENCY_NORMAL, Task.URGENCY_URGENT):
        fields["urgency"] = data["urgency"]
    budget = data.get("budget_mmk")
    if isinstance(budget, (int, float)) and not isinstance(budget, bool) and budget > 0:
        fields["budget_mmk"] = int(budget)

    return {"fields": fields}


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
