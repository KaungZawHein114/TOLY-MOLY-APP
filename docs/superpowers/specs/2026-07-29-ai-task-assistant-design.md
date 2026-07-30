# AI Task Assistant — Conversation Design

Status: **DESIGN LOCKED — awaiting sign-off on the implementation plan. No implementation code
has been written for this feature.** All architectural open questions (§11) are resolved; two
minor parameters (timeout, off-topic guard) are proceeding on a stated default, not a block.
Scope: Part 3 of the "Remove Firebase / simplify AI" refactor. Parts 1 (Firebase removal)
and 2 (demo-ify remaining AI features) are tracked separately and are not blocked by this doc.

## 1. What this replaces

Today, "Post a Task" → "AI Assistant" opens `voice_task_chat_screen.dart`, a **fully scripted**
5-question conversation (`taskVoiceScript` in `ai_mock.dart`) — fixed questions, fixed order,
fixed keyword extraction, no real understanding. Per your answer to Q9, **this screen is not
replaced, it's repurposed**: same route, same "conversational task-posting screen," but the
brain behind it changes from a fixed script to a real multi-turn AI conversation, with a
**local fallback engine** that keeps the experience identical if the backend/OpenAI is ever
unreachable.

Nothing about the method picker changes (Q4): `Post Task → Choose Method → AI Assistant | Manual`.
Manual is untouched.

## 2. What I found already exists (Q5 — reviewed before designing anything)

`backend/apps/tasks/` already has a real, working Django + OpenAI pipeline from an earlier
phase of this project, currently **unused by the Flutter app** (the app's voice flow is 100%
local today):

| Endpoint | Function | Verdict |
|---|---|---|
| `POST /api/tasks/ai/analyze` | `analyze_task(message, history, known_fields)` — multi-turn, merges fields across turns, returns `{fields, question, ready}` | **Reuse the pattern, refactor the contents.** This is the right shape (conversational, stateless per-request, merges known fields) but its field list and prompt don't match the new spec — see §7. |
| `POST /api/tasks/ai/extract` | `extract_task(transcript)` — one-shot, no follow-up questions | **Superseded.** Built for the old one-shot voice flow this app no longer has. Recommend deprecating (not deleting yet — that's your call, flagged in §11). |
| `POST /api/tasks/ai/transcribe` | `transcribe_audio(...)` — Whisper server-side STT | **Recommend not using.** See §6.3 — I'd rather reuse the app's existing on-device `speech_to_text` package (already a dependency, already used by `tasker_shortlist_sheet.dart`) so voice input produces text locally and joins the same message pipeline as typed text, live or fallback. Whisper adds an audio-upload round trip for no benefit here. Flagged as a decision in §11. |
| `POST /api/tasks/ai/budget-options` | `compute_budget_options(category, urgency)` — deterministic, no GPT | **Out of scope.** Budget/tier stays a separate step after the chat (Q6, Q8) — the AI conversation never touches it. |

I did **not** find any budget/tier fields, media fields, or category-specific field logic in
`analyze_task` — it asks for exactly 5 flat fields (category, title, date, time, urgency)
regardless of category. That's the main gap this doc closes.

## 3. Category taxonomy — RESOLVED

**Decision: constrain to the existing 9 skills** (Plumber, Electrician, Cleaner, Carpenter,
AC Technician, Tutor, Gardener, Delivery, Handyman). Moving, Installation, Beauty, and Event are
**not** recognized categories — the assistant maps that kind of request onto the closest existing
skill instead: "moving to a new apartment" / general installation work → Handyman (or Carpenter
when the item being installed is clearly furniture); "install a ceiling fan" → Electrician (same
keyword mapping `demo_data.dart`'s `_skillKeywords` already uses); "Repair" resolves to whichever
of Plumber/Electrician/AC Technician/Carpenter/Handyman actually fits what's broken. Zero ripple
into demo data, worker profiles, icons, or budget rates. The §7 checklists and §13 examples below
reflect this — the "Moving" example collapses into a Handyman listing.

## 4. Conversation architecture

```
┌─────────┐   ┌──────────────┐   ┌─────────────┐   ┌───────────┐   ┌─────────┐   ┌─────────┐
│ Greeting│ → │  Collecting  │ → │  Confirming │ → │  Media    │ → │ Building│ → │ Summary │
│ (1 line)│   │ (N questions)│   │ (1 question)│   │ (optional)│   │ (spinner)│   │ screen  │
└─────────┘   └──────────────┘   └─────────────┘   └───────────┘   └─────────┘   └─────────┘
```

- **Greeting**: Pho Wa Yoke opens with one open-ended line (your Stage 1) — no form, no
  category picker shown yet. Same UI shell as today's chat screen (bubbles, typing indicator,
  quick-reply chips, mic + text input) so this reads as an upgrade, not a rebuild.
- **Collecting**: the core loop. Every user turn — typed, or the mic's fixed canned line (§6.3) —
  is sent with the running `known_fields` + `history`; the response either asks exactly one more
  question or flips `ready: true`. One AI message per turn, always.
- **Confirming**: once `ready`, the assistant's next message *is* a natural-language recap
  framed as a question ("So: fix a leaking kitchen sink in Hledan, tomorrow morning, not
  urgent — did I get that right?"), and the UI switches from free text to two quick-reply
  chips: **"Yes, that's right"** / **"No, let me change something."** Saying no drops back
  into Collecting with the correction as the next user turn (fields re-merge; `ready` can
  transiently flip back to false if the correction invalidates something).
- **Media (optional)**: deterministic, NOT part of the LLM turn contract (see §6.4 — keeping
  this out of the JSON schema means it can never be forgotten or asked at the wrong time).
  Reuses the **existing** `TaskMediaPicker` / `task_media_screen.dart` built last session —
  same skip-or-continue button, same max-3 limit, just surfaced as one more chat turn instead
  of a separate route.
- **Building → Summary**: the collected fields map onto `TaskDraft` (§8) and the user lands on
  the **existing, unmodified** `review_publish_screen.dart` — same as Manual, same Edit-row
  behavior, same publish flow. Nothing downstream of the chat changes (Q6).

## 5. Stopping conditions

The assistant stops asking questions when **all** of the following are true:

1. Category is resolved (not null/ambiguous) — this should lock in within the first 1-2 turns;
   if still unclear by turn 2, ask a direct disambiguating question rather than guessing.
2. Every **always-required** field is filled: title/description of the problem, location
   (minimum: township), date/time-or-"flexible", urgency (explicit, or defaulted to NORMAL
   after one direct check).
3. Every **category-specific required** field for the resolved category is filled or explicitly
   waived by the user (§7).

Plus one hard safety net regardless of the above: **8 questions maximum.** If the conversation
hits that ceiling with fields still missing, the assistant wraps up anyway, treating anything
unresolved as "not specified" (never invents a value) rather than looping. This should be rare —
your target is 3-6 questions for a normal task, and the category checklists in §7 are sized to
fit that budget — but a demo must never be able to get stuck in an infinite question loop.

## 6. System prompt (draft)

### 6.1 Full prompt text

```
You are TOLY MOLY's Task Assistant — not a general chatbot. Your ONLY job is to
help a client describe a task well enough to post it on TOLY MOLY, a Myanmar
on-demand service marketplace.

Respond in the SAME language the client is using. If they write in English,
reply in English. If Burmese, reply in Burmese. If they mix both in one
message, mix naturally the way a bilingual Yangon speaker would — never force
a switch and never comment on language.

Rules:
- Ask ONE question at a time. Never ask about more than one missing field in
  a single message.
- Never repeat a question about information you already have.
- Never ask about anything that belongs to a LATER step in the app (budget,
  tasker level/trust tier, and photos/videos are handled after this
  conversation — never ask about them).
- Never make small talk, answer general questions, explain what you are, or
  discuss anything unrelated to the task. If the client goes off-topic,
  redirect in one short line back to the task and re-ask your last question.
- Be concise, warm, and practical — never sound like a generic AI assistant.
  No filler ("Great question!", "As an AI..."), no over-explaining.
- Every message must move the task toward being postable. If you already
  have enough to build a complete, useful task listing, stop asking
  questions — do not manufacture extra questions to seem thorough.

You will be given:
- `category_hint`: the category this app already recognizes for this kind of
  job, if any (see the required-fields list below for that category).
- `known_fields`: a JSON object of what's confirmed so far.
- `history`: prior turns of this conversation.
- the client's newest message.

Always-required fields (every task, any category): category, title (a short
3-8 word summary), description (1-2 sentences, using only what the client
actually said), location (at minimum a Yangon township), date (YYYY-MM-DD or
"flexible"), time (HH:MM 24h or "flexible"), urgency ("NORMAL" or "URGENT").

Category-specific required fields: see the list provided to you for the
resolved category — ask about whichever of those are still missing, in
whatever order feels most natural given what the client already said.

Merge new information into known_fields — never discard a known value unless
the client's new message clearly changes it. Resolve relative dates
("tomorrow", "မနက်ဖြန်", "this weekend") against today's date, {TODAY}.
Never invent a value the client didn't state or clearly imply.

Once EVERY always-required field and EVERY category-specific required field
is filled (or the client has explicitly said one doesn't apply), set
`ready: true` and, instead of a question, write a short natural-language
recap of the task and ask the client to confirm it's correct.

Respond with ONLY a JSON object of this exact shape:
{
  "category": string|null,
  "title": string|null,
  "description": string|null,
  "township": string|null,
  "address": string|null,
  "date": string|null,
  "time": string|null,
  "urgency": "NORMAL"|"URGENT"|null,
  "category_fields": { <category-specific keys and values, only ones you've
    collected> },
  "reply": string,
  "ready": boolean
}
```

### 6.2 Why this shape

- `reply` carries BOTH the follow-up question and (once `ready`) the confirmation recap — the
  Flutter side doesn't need to distinguish them structurally, it just renders `reply` as the
  next assistant bubble and switches its own input affordance (free text vs. Yes/No chips)
  based on `ready`.
- `category_fields` is an open dict rather than a fixed field list, because the required set
  is genuinely different per category (§7) — a fixed flat schema (like today's `analyze_task`)
  can't express "square footage" for Cleaning and "subject + grade level" for Tutoring in the
  same shape without a pile of always-null fields.
- Passing `category_fields`' *required key list* to the model per-request (rather than baking
  10 categories into the system prompt permanently) keeps the prompt shorter and the required
  set easy to tune later without touching the prompt text — see §8 for exactly what gets sent.

### 6.3 Voice input — RESOLVED, no real STT of any kind

**Decision: voice stays exactly as hardcoded/demo as it is today. Only text is dynamic.**
Neither the on-device `speech_to_text` package nor the backend's Whisper endpoint is used here.
The mic button keeps the same decorative "listening" pulse animation the current scripted screen
already has, then inserts ONE fixed canned line —

> "ရေပိုက် ယိုနေလို့ ပြင်ချင်ပါတယ်" ("My pipe is leaking, I'd like it fixed")

— as if the user had typed it. That line then flows into the SAME real (or fallback) text
pipeline as anything actually typed — the backend/fallback engine never knows or cares whether a
message came from the mic or the keyboard. No audio is ever captured or sent anywhere.
`TranscribeAudioView`/`transcribe_audio` stay unused (per §11 Q2 — confirmed, leave them).

This is a deliberate simplification, not a placeholder for future real STT: text is the one real,
dynamic input surface for this feature; voice is a fixed demo affordance, same spirit as the
mic buttons already used elsewhere in this app (`voice_task_chat_screen.dart`'s existing mock
mic, the onboarding voice-auth demo). If real speech input is wanted later, that's a separate,
explicitly-requested piece of work — not assumed here.

### 6.4 Why media is NOT in the JSON contract

Deliberately kept out of the model's turn-taking entirely. If it were a model-decided "ask about
photos when it feels right" instruction, a demo run could have the model forget, ask too early,
or ask twice. Instead: the **Flutter client** deterministically inserts one fixed chat turn
right after the user confirms (Yes) in the Confirming stage — "Would you like to add a photo or
video? You can also skip this." — using the same quick-reply-chip pattern, and on tap opens the
**existing** `TaskMediaPicker`. This is 100% reliable and reuses code that already works.

## 7. Category-specific required-info checklists

Always-required (every category, not repeated below): category, title, description, township,
date/time-or-flexible, urgency.

| Category (skill) | Category-specific required info |
|---|---|
| **Plumber** (repair) | What's broken/leaking (fixture: sink, toilet, pipe, water heater…); how severe (dripping vs. actively flooding) |
| **Electrician** (repair) | What needs fixing/installing (device/wiring/outlet/breaker); is the power currently on or off at that point |
| **Cleaner** (cleaning) | Approximate home size (number of rooms, or sqft if given); type of clean (regular tidy vs. deep-clean/move-out) |
| **AC Technician** (repair) | Number of units; the symptom (not cooling, leaking water, making noise, won't turn on) |
| **Carpenter** (repair/installation) | Type of work (repair existing / build new / install purchased item); rough size or material if the client mentions one |
| **Tutor** (tutoring) | Subject; student's grade/level; one-time session or recurring; online or in-person |
| **Delivery** | BOTH pickup location and drop-off location (a single "location" isn't enough here); what's being delivered; fragile/oversized? |
| **Gardener** | Yard/area size (rough); task type (mowing, trimming, planting, general cleanup); one-time or recurring |
| **Handyman** (catch-all — also covers Moving/Installation/Beauty/Event-shaped requests, per §3) | A specific description of what needs doing — since this is the fallback category, the assistant should push a little harder here than elsewhere to avoid a vague listing. For a move specifically: pickup + destination address, rough size (studio/1BR/house), floor/elevator access. For an installation: what's being installed, whether the item is already on-site. For beauty/event-shaped requests: service type, headcount, and (for events) push on the date early since it's unusually load-bearing there. |

## 8. Backend request/response format

**Recommendation: refactor `analyze_task` in place** (same endpoint, same URL) rather than add a
parallel one, per your instruction not to duplicate. Changes needed:

- `REQUIRED_FIELDS` expands from `[category, title, date, time, urgency]` to include
  `description`, `township`, `address`.
- New `CATEGORY_REQUIRED_FIELDS: dict[str, list[str]]` (Python) mirroring §7 — passed into the
  prompt per-request based on the resolved category, not hardcoded into the system prompt text.
- System prompt rewritten per §6.1 (multilingual response, `category_fields`, no forced Burmese).
- Response shape changes from `{fields, question, ready}` to include `reply` (question OR
  confirmation recap — see §6.2) instead of the narrower `question`, and adds `category_fields`.
- **No-auth for now** (Q7): drop `IsAuthenticated, IsClient` from this one view only — every
  other endpoint in `apps/tasks` keeps its current permissions. This is explicitly temporary;
  I'd suggest a one-line `# TODO(security): re-add auth before real launch` so it isn't
  forgotten silently.

Request:
```json
{
  "message": "my kitchen sink is leaking",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ],
  "known_fields": {
    "category": "Plumber",
    "title": null,
    "description": null,
    "township": null,
    "address": null,
    "date": null,
    "time": null,
    "urgency": null,
    "category_fields": {}
  }
}
```

Response:
```json
{
  "fields": { "...merged known_fields, same shape as request..." },
  "reply": "When did the leak start — just now, or has it been going on a while?",
  "ready": false
}
```

On the ready turn, `reply` is the confirmation recap instead of a question, and `ready: true`.

## 9. Flutter UI flow

Repurposing `voice_task_chat_screen.dart` (route unchanged: `Routes.postTaskVoice`):

1. **Open**: same chat shell as today (chat bubbles, Pho Wa Yoke avatar on AI lines, typing
   dots, input bar with mic + text + send). First AI bubble is the greeting question.
2. **Per turn**: user types, or taps the mic (fixed canned line, §6.3 — no real recognition) →
   bubble appears → typing indicator → backend call (with timeout, see §10) → AI bubble with
   `reply`. Quick-reply chips shown only where they make sense (e.g., urgency yes/no, township
   picks) — same `_QuickReplies` widget already built.
3. **Confirming**: input bar hides, two large chips appear: "Yes, that's right" / "No, let me
   change something."
4. **Media step**: one more assistant bubble + the existing `TaskMediaPicker`, Skip or Continue.
5. **Handoff**: brief "Preparing your summary…" beat (reuse the existing wrap-up
   Timer/PhoWaYoke-thinking pattern from today's script), then `context.push(Routes.postTaskReview)`
   — exactly like the current scripted flow does today, just fed by real fields instead of the
   fixed script's fields.
6. **Restart**: keep today's restart button — clears `known_fields`/history and starts over.

No new screens, no new routes. The AppBar, restart button, and read-aloud button stay as-is.

## 10. The fallback engine (Q12 — must be seamless)

The Flutter side tries the backend with a short timeout (proposed: 6-8s). On **any** failure —
timeout, non-2xx, malformed JSON, no network — it flips one boolean, **`_usingFallback`**, and
stays in fallback for the rest of that conversation (no per-turn retries; flapping between live
and fallback mid-conversation would risk an inconsistent tone/question order, which is worse for
a demo than just being consistently local).

The fallback is **not** a replay of today's fixed 5-question script. It's a small local decision
engine that follows the exact same rules as §5/§7 — same always-required fields, same
category-specific checklists, same one-question-at-a-time behavior, same 8-question ceiling —
using deterministic keyword extraction (extending the existing `ai_mock.dart` functions:
`_skillForQuery` for category, `voiceTaskPlace`, `voiceTaskSchedule`, `voiceTaskUrgent`, plus new
matching logic for description/title and the category-specific fields). This means live and
fallback conversations should feel like the *same product* even though one is a real model and
the other is pattern-matching — which also means whatever canned "personality" phrasing goes
into the fallback engine's questions should read as good as the live prompt's output, not
noticeably worse (ties into Part 2's "improve canned responses" work).

The user is never told which mode they're in — no "offline" badge, no error toast, nothing.
This mirrors the `AiSource.demo` pattern already used elsewhere in the app for exactly this
"looks live either way" reason.

## 11. Design decisions — status

All six original questions are now resolved. Recap:

1. **Category taxonomy** — RESOLVED §3: constrain to the existing 9 skills.
2. **`extract_task`/`ExtractTaskView`/`TranscribeAudioView`** — RESOLVED: leave unused, don't
   delete.
3. **Voice input** — RESOLVED §6.3: no real STT of any kind (not on-device, not Whisper). Mic
   tap = fixed canned line → real text pipeline. Text is the only dynamic input surface.
4. **Confirmation UX** — RESOLVED §4: Yes/No quick-reply chips.
5. **Timeout value** — proposed default, not yet explicitly confirmed: **7 seconds**. This is a
   small, easily-changed constant (not an architectural fork), so I'm proceeding with it unless
   told otherwise rather than blocking on it.
6. **Rule-based off-topic guard** — proposed default: **prompt-only**, no separate rule-based
   gate in front of the model. Reasoning: the chatbot's hard gate exists because that bot is
   general-purpose and must never let the model decide when to refuse; this assistant is already
   single-purpose (it only ever sees task-posting-shaped conversations, never a public "ask me
   anything" surface), so the risk profile is lower and a second gate would mostly add complexity
   for edge cases the system prompt's redirect instruction already covers (see §12's off-topic
   row). Flag if you'd rather have the belt-and-suspenders version.

## 12. Edge cases

| Case | Behavior |
|---|---|
| User gives everything in the first message | Zero follow-up questions — straight to confirmation. Merge logic already supports this naturally. |
| User contradicts an earlier answer | New value overwrites the old one (system prompt: "never discard unless clearly changed"); confirmation recap always shows the FINAL merged state, so the client double-checks it either way. |
| Category never resolves (too vague after 2 tries) | Falls to Handyman + asks the client to describe the job in their own words as the "category-specific" question, same as the Handyman row in §7. |
| User asks something off-topic ("what is TOLY MOLY", "are you ChatGPT", weather, jokes) | One short redirect line back to the last pending question — never answered, never explained. |
| User tries to end early ("just post it") with fields still missing | One line acknowledging the request, but names the one field still needed ("Almost there — where in Yangon is this?") rather than accepting an incomplete task silently. |
| No location ever given after being asked directly | After one direct ask, if still missing, proceeds without it (falls through to §5's 8-question ceiling behavior) rather than looping — Summary shows "-" for location like it does today for any missing field. |
| Multiple distinct jobs in one message ("fix my sink AND mow my lawn") | Out of scope for a single task listing — assistant asks the client to pick ONE to post now (the flow only produces one `TaskDraft`), the same constraint Manual posting already has. |
| Message is extremely long / rambling | Model still extracts what it can; `reply` should ask about only the single most important gap, not overwhelm back. |
| Network flaps mid-conversation (times out once, recovers) | Fallback is sticky per §10 — no mid-conversation flip-flopping even if connectivity returns. |
| Media step: user attaches something, then removes it before Summary | Handled entirely by the existing `TaskMediaPicker`/`TaskDraft.media` state — unaffected by this feature. |
| App backgrounded/killed mid-conversation | Out of scope for MVP — same as today's scripted flow, which also has no conversation-resume; restarting the screen restarts the conversation. Flag if you want persistence later. |
| Backend returns malformed JSON / missing `reply` | Treated identically to a network failure — triggers fallback per §10, not shown to the user as an error. |
| Client sends a message with no task-relevant content at all (e.g. just emoji) | Model asks the client to describe what they need in their own words — same handling as an unresolved category. |

## 13. Conversation examples (10 categories)

Each shown as: user message → AI reply, ending at the confirmation recap. Burmese/English mixed
per Q10's "match the user's language" rule — these examples lean English for readability here,
but the live system must mirror whatever the user actually types.

**1. Plumber (repair)**
> U: My kitchen sink is leaking.
> AI: Sorry to hear that — is it dripping steadily or is water actively flooding the floor?
> U: Just dripping under the sink, near the pipe.
> AI: Got it. Which township are you in?
> U: Hledan.
> AI: When would you like someone to come by?
> U: Tomorrow morning if possible.
> AI: So: fix a dripping pipe under the kitchen sink in Hledan, tomorrow morning, not urgent — did I get that right?

**2. Electrician (repair)**
> U: My living room outlet stopped working.
> AI: Got it — is the power to that outlet currently on, or did you switch it off at the breaker?
> U: Still on, just that one outlet doesn't work.
> AI: Where in Yangon should the tasker come to?
> U: Sanchaung.
> AI: Any particular day/time, or are you flexible?
> U: Flexible, whenever.
> AI: Is this urgent, or can it wait a few days?
> U: No rush.
> AI: So: fix a dead living-room outlet in Sanchaung, flexible timing, not urgent — sound right?

**3. Cleaner (cleaning)**
> U: I need my apartment cleaned before guests arrive.
> AI: How many rooms are we talking about, roughly?
> U: Two bedrooms and a living room.
> AI: Is this a regular tidy-up, or more of a deep clean?
> U: Deep clean please, it's been a while.
> AI: Which township, and when do your guests arrive?
> U: Kamayut, this Saturday.
> AI: So: deep clean a 2-bedroom apartment in Kamayut before Saturday — did I get that right?

**4. AC Technician (repair)**
> U: My AC isn't cooling anymore.
> AI: How many units are affected — just the one, or more?
> U: Just my bedroom unit.
> AI: Is it blowing warm air, leaking water, or making unusual noise?
> U: Blowing warm air only.
> AI: Where should the tasker come to, and is this urgent?
> U: Yankin, and yes it's pretty hot in there — urgent please.
> AI: So: bedroom AC unit blowing warm air in Yankin, urgent — sound right?

**5. Carpenter (repair/installation)**
> U: I bought a wardrobe that needs assembling.
> AI: Got it — is this assembling something you already have, or building/repairing an
> existing piece?
> U: Assembling, it's flat-packed, still in the boxes.
> AI: Where should the tasker come, and when works for you?
> U: Tarmwe, this weekend.
> AI: So: assemble a flat-pack wardrobe in Tarmwe this weekend — did I get that right?

**6. Tutor (tutoring)**
> U: Looking for a math tutor for my son.
> AI: What grade or level is he in?
> U: Grade 9.
> AI: Would you like one-time help or regular sessions?
> U: Regular, maybe twice a week.
> AI: In-person or online, and which township if in-person?
> U: In-person, Bahan.
> AI: So: regular Grade 9 math tutoring, twice a week, in-person in Bahan — sound right?

**7. Delivery**
> U: I need something picked up and delivered today.
> AI: What needs to be delivered?
> U: A birthday cake, needs to stay upright.
> AI: Where should it be picked up from, and where's it going?
> U: Pickup in Sanchaung, drop-off in Insein.
> AI: Since it's today, should I mark this as urgent?
> U: Yes please.
> AI: So: deliver a birthday cake (handle with care) from Sanchaung to Insein, today, urgent —
> did I get that right?

**8. Gardener**
> U: My yard needs some work.
> AI: What kind of work — mowing, trimming, planting, general cleanup?
> U: Mostly overgrown grass and some trimming.
> AI: Roughly how big is the yard?
> U: Medium size, small house yard.
> AI: Which township, and is this one-time or something you'd like regularly?
> U: Mayangone, just one-time for now.
> AI: So: one-time mowing and trimming for a small yard in Mayangone — sound right?

**9. Handyman (catch-all)**
> U: A few small things need fixing around my apartment.
> AI: No problem — can you tell me specifically what needs fixing?
> U: A loose door hinge and a wobbly shelf.
> AI: Which township, and when would you like this done?
> U: Botahtaung, anytime this week.
> AI: So: fix a loose door hinge and a wobbly shelf in Botahtaung, sometime this week — did I get
> that right?

**10. Moving** *(resolved per §3 — collapses into a Handyman listing; category label shown to
the client stays whatever `effectiveCategory`/`kOtherCategory` conventions the Manual flow
already uses for an off-list request, not a literal "Moving" category)*
> U: I'm moving to a new apartment next month.
> AI: Got it — what size is the move, roughly? Studio, 1-bedroom, a whole house?
> U: 1-bedroom.
> AI: What are the pickup and destination addresses (township is enough for now)?
> U: Moving from Hlaing to Thingangyun.
> AI: Do either building have stairs-only access, or is there an elevator?
> U: Both have elevators, thankfully.
> AI: What date are you targeting?
> U: The 15th of next month.
> AI: So: 1-bedroom move from Hlaing to Thingangyun (elevator access both ends) on the 15th —
> sound right?

## 14. Status

Design is **locked** on every point that changes architecture: category taxonomy (§3), old
endpoints (§2/§11), voice input (§6.3), confirmation UX (§4). Two small parameters (timeout
value, off-topic guard) are proceeding on a stated default per §11 rather than blocking further —
flag either if you want them changed.

**Next step, per your instruction not to write implementation code yet:** I'll write an
implementation plan (concrete file-by-file changes, Flutter + Django, no code) for your review
before touching anything. Separately: Parts 1 (Firebase removal) and 2 (demo-ify the other 5 AI
features) already have final, unconditional answers from you and don't depend on anything in
this document — let me know if you want those executed now, in parallel with the Part 3
implementation plan, or held until everything (including Part 3) is fully signed off.
