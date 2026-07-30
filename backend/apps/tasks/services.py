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

# Always-required fields for every task, any category (design doc §5/§7).
REQUIRED_FIELDS = ["category", "title", "description", "township", "date", "time", "urgency"]

# Category-specific required info (design doc §7) — passed into the prompt
# per-request based on the resolved category, not baked into the system
# prompt text, so tuning one category's checklist never means editing the
# prompt itself. Values are freeform strings the model reads as guidance for
# what to ask about; there is no fixed key schema for category_fields.
CATEGORY_REQUIRED_FIELDS = {
    "Plumber": [
        "what's broken or leaking (fixture: sink, toilet, pipe, water heater...)",
        "how severe (dripping vs. actively flooding)",
    ],
    "Electrician": [
        "what needs fixing or installing (device/wiring/outlet/breaker)",
        "is the power currently on or off at that point",
    ],
    "Cleaner": [
        "approximate home size (number of rooms, or sqft if given)",
        "type of clean (regular tidy vs. deep-clean/move-out)",
    ],
    "AC Technician": [
        "number of units affected",
        "the symptom (not cooling, leaking water, making noise, won't turn on)",
    ],
    "Carpenter": [
        "type of work (repair existing / build new / install purchased item)",
        "rough size or material if mentioned",
    ],
    "Tutor": [
        "subject",
        "student's grade/level",
        "one-time session or recurring",
        "online or in-person",
    ],
    "Delivery": [
        "BOTH pickup location and drop-off location (a single location isn't enough)",
        "what's being delivered",
        "whether it's fragile or oversized",
    ],
    "Gardener": [
        "yard/area size (rough)",
        "task type (mowing, trimming, planting, general cleanup)",
        "one-time or recurring",
    ],
    "Handyman": [
        "a specific description of what needs doing — push a little harder here "
        "than other categories to avoid a vague listing, since this is the "
        "fallback category (also covers moving/installation/beauty/event-shaped "
        "requests: for a move ask pickup+destination, size, floor/elevator "
        "access; for an installation ask what's being installed and whether "
        "it's already on-site; for beauty/event requests ask service type, "
        "headcount, and push on the date early for events)",
    ],
}

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


def _analyze_task_system_prompt(category_hint):
    category_fields_hint = (
        CATEGORY_REQUIRED_FIELDS.get(category_hint) if category_hint else None
    )
    category_section = (
        f"Category-specific required info for {category_hint}, ask about "
        f"whichever of these are still missing (whatever order feels most "
        f"natural given what the client already said): "
        f"{'; '.join(category_fields_hint)}."
        if category_fields_hint
        else "The category isn't resolved yet — that's your first priority. "
        "Once you know it, category-specific required info will be provided "
        "on the next turn."
    )
    return (
        "You are TOLY MOLY's Task Assistant — not a general chatbot. Your "
        "ONLY job is to help a client describe a task well enough to post it "
        "on TOLY MOLY, a Myanmar on-demand service marketplace.\n\n"
        "Respond in the SAME language the client is using. If they write in "
        "English, reply in English. If Burmese, reply in Burmese. If they "
        "mix both in one message, mix naturally the way a bilingual Yangon "
        "speaker would — never force a switch and never comment on "
        "language.\n\n"
        "Rules:\n"
        "- Ask ONE question at a time. Never ask about more than one "
        "missing field in a single message.\n"
        "- Never repeat a question about information you already have.\n"
        "- Never ask about anything that belongs to a LATER step in the app "
        "(budget, tasker level/trust tier, and photos/videos are handled "
        "after this conversation — never ask about them).\n"
        "- Never make small talk, answer general questions, explain what "
        "you are, or discuss anything unrelated to the task. If the client "
        "goes off-topic, redirect in one short line back to the task and "
        "re-ask your last question.\n"
        "- Be concise, warm, and practical — never sound like a generic AI "
        "assistant. No filler (\"Great question!\", \"As an AI...\"), no "
        "over-explaining.\n"
        "- Every message must move the task toward being postable. If you "
        "already have enough to build a complete, useful task listing, stop "
        "asking questions — do not manufacture extra questions to seem "
        "thorough.\n\n"
        f"Valid categories (pick the closest match; if truly unclear, ask "
        f"the client to describe the job in their own words rather than "
        f"guessing): {', '.join(CANONICAL_CATEGORIES)}.\n\n"
        "Always-required fields (every task, any category): category, title "
        "(a short 3-8 word summary), description (1-2 sentences, using only "
        "what the client actually said), township (a Yangon township), date "
        "(YYYY-MM-DD or \"flexible\"), time (HH:MM 24h or \"flexible\"), "
        "urgency (\"NORMAL\" or \"URGENT\").\n\n"
        f"{category_section}\n\n"
        "Merge new information into known_fields — never discard a known "
        "value unless the client's new message clearly changes it. Resolve "
        "relative dates (\"tomorrow\", \"မနက်ဖြန်\", \"this weekend\") "
        f"against today's date, {timezone.localdate().isoformat()}. Never "
        "invent a value the client didn't state or clearly imply.\n\n"
        "Once EVERY always-required field and EVERY category-specific "
        "required field is filled (or the client has explicitly said one "
        "doesn't apply), set ready to true and, instead of a question, "
        "write a short natural-language recap of the task and ask the "
        "client to confirm it's correct.\n\n"
        "Respond with ONLY a JSON object of this exact shape:\n"
        '{"category": string|null, "title": string|null, "description": '
        'string|null, "township": string|null, "address": string|null, '
        '"date": string|null, "time": string|null, "urgency": '
        '"NORMAL"|"URGENT"|null, "category_fields": {"<any keys you have '
        'collected for the category-specific info above>": "<value>"}, '
        '"reply": string, "ready": boolean}'
    )


def analyze_task(message, history, known_fields):
    """GPT task-info extraction — one conversational turn of the AI Task
    Assistant conversation (Task Posting's "AI Assistant" method). A
    SEPARATE agent from apps.assistant's App Assistant — different prompt,
    different job (building one structured task, not answering product
    questions), never sharing code with that app.

    history: list of {"role": "user"|"assistant", "content": str} from
        earlier turns (does not include `message`, the newest one).
    known_fields: dict — a subset of REQUIRED_FIELDS plus an optional
        "category_fields" dict, already collected.

    Returns {"fields": dict, "reply": str, "ready": bool}. `fields` is the
    merged known_fields (always-required flat keys + "category_fields").
    `reply` is either the next question or (once `ready`) a confirmation
    recap — the caller doesn't need to distinguish them structurally, just
    render `reply` and switch its own input affordance based on `ready`.
    `ready` is only ever True once every always-required field the backend
    itself can verify is present; the model additionally judges
    category-specific completeness (an open field set the backend can't
    schema-check), so a `ready: true` from the model is trusted for that
    part but always re-checked against the flat required fields here.
    """
    client = _client()
    category_hint = known_fields.get("category")
    system_prompt = _analyze_task_system_prompt(category_hint)
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "system", "content": f"known_fields so far: {json.dumps(known_fields)}"},
        *history,
        {"role": "user", "content": message},
    ]

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            response_format={"type": "json_object"},
            temperature=0.3,
        )
        data = json.loads(response.choices[0].message.content)
    except Exception as exc:  # noqa: BLE001 — surface any SDK/network failure uniformly
        raise AIServiceUnavailable(f"Task analysis failed: {exc}") from exc

    reply = data.get("reply")
    if not isinstance(reply, str) or not reply.strip():
        # No usable text back is as good as no response — the caller treats
        # this exactly like a network failure and falls back locally.
        raise AIServiceUnavailable("Task assistant returned an empty reply.")

    flat_fields = {"category", "title", "description", "township", "address", "date", "time", "urgency"}
    extracted = {field: data.get(field) for field in flat_fields if data.get(field)}
    merged_fields = {**known_fields, **extracted}

    incoming_category_fields = data.get("category_fields")
    if isinstance(incoming_category_fields, dict):
        merged_category_fields = {
            **known_fields.get("category_fields", {}),
            **{k: v for k, v in incoming_category_fields.items() if v not in (None, "")},
        }
    else:
        merged_category_fields = known_fields.get("category_fields", {})
    merged_fields["category_fields"] = merged_category_fields

    missing_required = [field for field in REQUIRED_FIELDS if not merged_fields.get(field)]
    ready = bool(data.get("ready")) and not missing_required

    return {
        "fields": merged_fields,
        "reply": reply.strip(),
        "ready": ready,
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
