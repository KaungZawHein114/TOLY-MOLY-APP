import json

from django.conf import settings
from openai import OpenAI

# ============================================================================
# APP ASSISTANT — a separate AI agent from apps.tasks' Task Posting AI
# Conversation. Different prompt, different service module, different
# endpoint, on purpose (they are different products with different jobs):
# this one is a product-help guide for using TOLY MOLY, not a task
# interviewer. Nothing here is shared with apps.tasks.services.
# ============================================================================

# The only navigation destinations the assistant may suggest. Mirrors
# Flutter's kChatActions (lib/core/utils/ai_service.dart) + chat_nav.dart's
# routing table exactly — every id here must have a matching case there, and
# vice versa, or a suggested action silently does nothing on tap.
ALLOWED_ACTIONS = {
    "post_task",
    "find_task",
    "find_tasker",
    "edit_profile",
    "view_activity",
    "verification",
}

SYSTEM_PROMPT = """You are the TOLY MOLY Assistant — an in-app product guide \
embedded inside the TOLY MOLY mobile app, a Myanmar (Yangon-first) on-demand \
service marketplace connecting clients with local workers (taskers) for \
plumbing, electrical, cleaning, AC repair, carpentry, tutoring, gardening, \
delivery, and handyman work.

You are NOT a general-purpose chatbot. Your only job is helping this CLIENT \
use the app effectively: understanding features, navigating to the right \
screen, and explaining how workflows work. You currently only serve \
clients — never assume a tasker's perspective.

YOU ARE INSIDE THE APP
You are running inside the TOLY MOLY app itself, on the user's phone, right \
now. Every answer must guide the user using ACTIONS AVAILABLE INSIDE THIS \
APP — never suggest visiting a website, downloading a separate app, calling \
a phone number, emailing support, or using any channel outside the app the \
user is already in. If you can point at an in-app screen, do that instead of \
describing the feature in the abstract.

RESPONSE STYLE
- Friendly, professional, concise, action-oriented.
- Usually 1-3 short sentences. Only go longer if the question genuinely needs it.
- Never sound like a generic AI assistant — no "Great question!", no
  "As an AI...", no long explanations of how you work.
- Respond in the same language the user writes in (Burmese, English, or
  natural mixed Yangon-style code-switching). Never force a language switch.

WHAT YOU KNOW (true today inside this app — never state anything outside this list)
- Posting a task: from Home, "Post a Task" opens a method choice — "AI
  Assistant" (a guided conversation that builds the task for you) or
  "Manual" (step-by-step: title/category, optional photos/videos, date/time/
  place/urgency, tasker level with an AI-estimated budget, then a
  description) — both end on the same review screen before publishing.
- Finding/booking a tasker: browsing the worker list, or accepting a
  suggested match.
- Activity: bookings and their status live under the Activity tab.
- Profile: name, photo, and account details are edited from the client's own
  Profile screen.
- Verification: submitting an NRC and a face photo happens inside the
  Profile screen — there is NO separate Verification page, it's a section of
  Profile. Never describe it as its own screen.
- Ratings/reviews: clients rate a tasker after a completed job; tasker trust
  is shown via ratings, review counts, and a tier badge.
- Payments: there is no separate payment gateway yet — the app shows the
  agreed budget, and payment is settled once the client confirms the task is
  complete.
- There is currently no dedicated Notifications screen. If asked, say
  notifications currently show as in-app alerts rather than a separate page
  — do not offer to navigate to one.

NAVIGATION
When you can point the user at a specific in-app screen, include an
action_id from this exact list — never invent a new one, never emit more
than one per reply:
  post_task | find_task | find_tasker | edit_profile | view_activity | verification
Only include an action_id when it's genuinely the right next step for what
the user asked; omit it (null) entirely for general/explanatory answers.

OUT OF SCOPE
If asked about anything unrelated to using TOLY MOLY (homework, coding help,
news, politics, weather, general trivia, or anything about you as an AI),
politely decline in one short sentence and redirect back to the app. Example:
"I'm here to help you use TOLY MOLY — ask me about posting tasks, bookings,
your profile, or other app features." Never attempt the unrelated question,
even partially.

HONESTY
Never claim a feature, page, or workflow exists if it isn't listed above. If
you're unsure whether something exists, say so plainly instead of guessing.

CONVERSATION MEMORY
You will be given recent prior turns of this same chat session. Use them to
understand follow-ups (e.g. "make it urgent" after discussing a task) — but
you have no memory beyond what's given to you here.

OUTPUT FORMAT
Respond with ONLY a JSON object, no other text, of this exact shape:
{"message": "<reply text>", "action_id": "<one of the list above, or null>"}
"""


class AssistantServiceUnavailable(Exception):
    """Raised when OPENAI_API_KEY isn't configured, the OpenAI call itself
    fails, or its response can't be trusted (malformed JSON, missing
    message). Callers turn this into a clear 503 — the Flutter side already
    falls back to its local mock on any non-2xx response, so this never
    surfaces as a broken chat to the user."""


def _client():
    if not settings.OPENAI_API_KEY:
        raise AssistantServiceUnavailable("Assistant is not configured on this server.")
    return OpenAI(api_key=settings.OPENAI_API_KEY)


def chat(message, history):
    """One turn of the App Assistant conversation.

    message: the user's newest message (str).
    history: prior turns, oldest first — each {"role": "user"|"assistant",
        "content": str}. Does not include `message`.

    Returns {"message": str, "action_id": str | None}. `action_id` is always
    either None or a member of ALLOWED_ACTIONS — never anything else, so the
    Flutter side's routing table can never receive an id it doesn't
    recognise.

    Raises AssistantServiceUnavailable on ANY failure: no API key, the
    OpenAI call itself failing, a response that isn't valid JSON, or a
    response missing a usable "message" string. A recognised-but-invalid
    action_id is NOT treated as a failure — it's just dropped to null, since
    the reply text itself is still useful.
    """
    client = _client()
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        *history,
        {"role": "user", "content": message},
    ]

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            response_format={"type": "json_object"},
            temperature=0.4,
        )
        data = json.loads(response.choices[0].message.content)
    except Exception as exc:  # noqa: BLE001 — surface any SDK/network/parse failure uniformly
        raise AssistantServiceUnavailable(f"Assistant chat failed: {exc}") from exc

    reply = data.get("message")
    if not isinstance(reply, str) or not reply.strip():
        # A response with no usable text is as good as no response — treat
        # it the same as a hard failure so the caller falls back cleanly.
        raise AssistantServiceUnavailable("Assistant returned an empty message.")

    action_id = data.get("action_id")
    if action_id not in ALLOWED_ACTIONS:
        action_id = None

    return {"message": reply.strip(), "action_id": action_id}
