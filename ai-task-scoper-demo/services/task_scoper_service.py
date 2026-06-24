"""Service layer that talks to the OpenAI API.

The web layer (app.py) should not know anything about OpenAI. It just calls
`scope_task(text)` and gets back a clean Python dict, or a ValueError it can
turn into an error message.
"""

import json
import os

from openai import OpenAI, OpenAIError

from prompts.task_scoper_prompt import SYSTEM_PROMPT, build_user_prompt

# Read configuration once at import time.
_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

# A lazily-created client so importing this module never crashes when the key
# is missing (we want a friendly error at request time instead).
_client = None


def _get_client() -> OpenAI:
    """Return a shared OpenAI client, creating it on first use."""
    global _client
    if _client is None:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError(
                "OPENAI_API_KEY is not set. Copy .env.example to .env and add "
                "your key."
            )
        _client = OpenAI(api_key=api_key)
    return _client


# The fields we promise to return to the frontend. Used to validate the model
# output so the UI never receives a half-filled object.
_REQUIRED_FIELDS = (
    "improved_description",
    "missing_information",
    "budget_assessment",
    "suggested_budget_range",
    "estimated_completion_time",
    "tasker_match_score",
    "reasoning",
)


def scope_task(task_text: str) -> dict:
    """Analyze a task posting and return the structured scoping result.

    Raises:
        ValueError: for any problem the user should see (empty input, missing
            key, bad AI response, or an API failure).
    """
    task_text = (task_text or "").strip()
    if not task_text:
        raise ValueError("Please enter a task description first.")
    if len(task_text) > 4000:
        raise ValueError("That task description is too long. Please shorten it.")

    client = _get_client()

    try:
        response = client.chat.completions.create(
            model=_MODEL,
            # Ask the model to return strict JSON.
            response_format={"type": "json_object"},
            temperature=0.4,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": build_user_prompt(task_text)},
            ],
        )
    except OpenAIError as exc:
        # Network/auth/rate-limit errors all land here.
        raise ValueError(f"The AI service could not be reached: {exc}") from exc

    raw = response.choices[0].message.content or ""

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError("The AI returned an unexpected response. Please try "
                         "again.") from exc

    return _normalize(data)


def _normalize(data: dict) -> dict:
    """Make sure every field exists and has a sensible, UI-friendly type."""
    if not isinstance(data, dict):
        raise ValueError("The AI returned an unexpected response. Please try again.")

    for field in _REQUIRED_FIELDS:
        if field not in data:
            raise ValueError("The AI response was incomplete. Please try again.")

    # Missing information: always a list of strings.
    missing = data.get("missing_information") or []
    if isinstance(missing, str):
        missing = [missing]
    data["missing_information"] = [str(item) for item in missing]

    # Budget assessment: always a dict with status + explanation.
    budget = data.get("budget_assessment") or {}
    if not isinstance(budget, dict):
        budget = {"status": "Fair", "explanation": str(budget)}
    status = str(budget.get("status", "Fair")).strip().title()
    if status not in ("Low", "Fair", "High"):
        status = "Fair"
    data["budget_assessment"] = {
        "status": status,
        "explanation": str(budget.get("explanation", "")),
    }

    # Match score: clamp to an integer 0-100.
    try:
        score = int(round(float(data.get("tasker_match_score", 0))))
    except (TypeError, ValueError):
        score = 0
    data["tasker_match_score"] = max(0, min(100, score))

    # Plain-string fields.
    for field in (
        "improved_description",
        "suggested_budget_range",
        "estimated_completion_time",
        "reasoning",
    ):
        data[field] = str(data.get(field, "")).strip()

    return data
