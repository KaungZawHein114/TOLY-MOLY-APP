import json

from django.conf import settings
from openai import OpenAI

# ============================================================================
# AI TASKER FINDER — a THIRD, separate AI agent, alongside:
#   - apps.assistant  (App Assistant: in-app product help)
#   - apps.tasks      (AI Task Assistant: builds one structured task)
# Different prompt, different service module, different endpoint, on purpose.
# Nothing here is shared with either of the other two.
#
# SCOPE — deliberately tiny. This agent does exactly ONE thing: read a client's
# free-text problem ("my sink is leaking") and name the service category that
# solves it. It does NOT search, rank, score, or recommend taskers, and it is
# never shown the tasker database. All searching and ranking happens locally on
# the Flutter side against the hardcoded worker list, which keeps the feature
# fast (one round-trip), cheap (one short call), and deterministic (the same
# category always produces the same shortlist).
#
# FUTURE COMPATIBILITY — the response contract is additive-only. Real DB
# queries, GPS distance, live availability, marketplace demand, vector/RAG
# retrieval and personalization can all be layered in later (either here or in
# a sibling `search()` function) by ADDING response keys; `category`,
# `confidence` and `problem` keep their meaning, so the Flutter client and the
# API contract never have to change.
# ============================================================================

# The ONLY categories this agent may return. Mirrors the `skill` values in
# Flutter's lib/core/data/demo_data.dart exactly — every entry here must exist
# there, and vice versa, or a detected category silently matches zero taskers.
SERVICE_CATEGORIES = [
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

# The safe landing spot for a request no category fits. Mirrors the Flutter
# keyword matcher's default (`_skillForQuery` in ai_mock.dart) so the online
# and offline paths degrade to the same answer.
FALLBACK_CATEGORY = "Handyman"

SYSTEM_PROMPT = """You are the TOLY MOLY Tasker Finder — the classifier behind \
the "AI Tasker Finder" button in the TOLY MOLY mobile app, a Myanmar \
(Yangon-first) on-demand service marketplace connecting clients with local \
workers (taskers).

A client has just described a problem they need help with. Your ONLY job is to
decide which service category solves that problem.

CATEGORIES (choose exactly one, spelled exactly as written):
- Plumber — leaks, taps, sinks, drains, pipes, toilets, water tanks, water pressure
- Electrician — wiring, sockets, switches, breakers, lights, power outages, fans
- Cleaner — house/apartment/office cleaning, deep cleaning, laundry, post-move cleanup
- Carpenter — wood, doors, windows, cabinets, shelves, furniture repair or assembly
- AC Technician — air conditioner install, service, gas refill, cooling problems
- Tutor — teaching or lessons of any subject (maths, English, music, exam prep)
- Handyman — small mixed household repairs, mounting, patching, odd jobs
- Gardener — plants, lawn, trees, garden clearing, watering
- Delivery — moving, carrying, or delivering goods, parcels, or shopping

RULES
- Return exactly one category from the list. Never invent a category, never
  return an empty string, never return more than one.
- The client may write in Burmese, English, or mixed Yangon-style
  code-switching. Understand all three equally.
- If the request is vague, ambiguous, or fits nothing well, pick the CLOSEST
  reasonable category (use "Handyman" for general household work) and report a
  LOW confidence. Never refuse and never ask a follow-up question — the app
  always needs a category to search with.
- confidence is your own honest 0.0-1.0 estimate that the category is right.
  Use below 0.5 when you are guessing.
- problem is a very short restatement of what the client needs, in the SAME
  language they wrote in, maximum 8 words, no punctuation at the end. It is
  shown back to the client as "here is what I understood", so it must only
  contain what they actually said — never invent details.

OUTPUT FORMAT
Respond with ONLY a JSON object, no other text, of this exact shape:
{"category": "<one category from the list>", "confidence": <0.0-1.0>, "problem": "<short restatement>"}
"""


class MatchingServiceUnavailable(Exception):
    """Raised when OPENAI_API_KEY isn't configured, the OpenAI call itself
    fails, or its response can't be trusted (malformed JSON, no usable
    category). Callers turn this into a clear 503 — the Flutter side falls
    back to its local keyword matcher on any non-2xx response, so this never
    surfaces as an error to the user."""


def _client():
    if not settings.OPENAI_API_KEY:
        raise MatchingServiceUnavailable("Tasker Finder is not configured on this server.")
    return OpenAI(api_key=settings.OPENAI_API_KEY)


def _clamp_confidence(value):
    """Coerce whatever the model emitted into a 0.0-1.0 float. An unusable
    value becomes 0.0 (= "no idea") rather than failing the whole call: the
    category is the useful part, confidence is advisory."""
    try:
        return max(0.0, min(1.0, float(value)))
    except (TypeError, ValueError):
        return 0.0


def classify_category(message):
    """Classify one free-text problem description into a service category.

    message: what the client typed or spoke (str).

    Returns {"category": str, "confidence": float, "problem": str}.
    `category` is ALWAYS a member of SERVICE_CATEGORIES — an unrecognised
    value from the model is coerced to FALLBACK_CATEGORY rather than raising,
    because a slightly-wrong category still produces a useful shortlist while
    a hard failure produces none. `confidence` is always a float in [0, 1].
    `problem` may be an empty string (it is decoration, not data).

    Raises MatchingServiceUnavailable on a hard failure only: no API key, the
    OpenAI call itself failing, or a response that isn't valid JSON.
    """
    client = _client()

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": message},
            ],
            response_format={"type": "json_object"},
            temperature=0,
        )
        data = json.loads(response.choices[0].message.content)
    except Exception as exc:  # noqa: BLE001 — surface any SDK/network/parse failure uniformly
        raise MatchingServiceUnavailable(f"Tasker Finder classification failed: {exc}") from exc

    if not isinstance(data, dict):
        raise MatchingServiceUnavailable("Tasker Finder returned a non-object response.")

    category = data.get("category")
    if category not in SERVICE_CATEGORIES:
        # A hallucinated or missing category is recoverable: fall back to the
        # general category and let the low confidence tell the story.
        category = FALLBACK_CATEGORY

    problem = data.get("problem")
    problem = problem.strip() if isinstance(problem, str) else ""

    return {
        "category": category,
        "confidence": _clamp_confidence(data.get("confidence")),
        "problem": problem,
    }
