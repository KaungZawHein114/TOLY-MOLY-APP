# AI Agents (Pho Wa Yoke) — Design Spec

> Source: user brainstorming session ("AI AGENTS IN TOLYMOLY") plus
> recommended fixes agreed in the 2026-07-06 Cowork session. This spec
> covers the in-app "AI agents": text/voice-analyzing LLM assistants that
> greet users, ask follow-up questions, fill forms, match taskers, guide
> navigation, and monitor task lifecycle. It builds directly on the existing
> AI seam (`lib/core/utils/ai_service.dart` + `functions/`) and the Task
> Posting flow already shipped. It is a **design spec for review** — nothing
> here is built yet.

---

## 1. The core reframe

Every hackathon app claims "we added AI." TOLY MOLY's defensible, judge-
winning angle is narrower and stronger: **voice-first agentic accessibility
for a low-literacy, Burmese-first market** — an assistant that lets someone
who cannot comfortably read or type still post a task, get matched, and hire,
by *talking*. The agents are the vehicle; the story is "technology made
usable for the people the industry ignores." The whole pitch should open
with that sentence.

---

## 2. Resolved decisions (from brainstorming)

| Question | Decision |
|---|---|
| How many agents / how embodied? | **One agent, many modes.** Pho Wa Yoke is the single character; the nine "agents" become context *modes* ("hats") of that one guide. Cute Burmese names, if used, label modes — not separate avatars. |
| How far do agents "execute" for the user? | **Prepare + preview, user confirms.** Agents parse voice/text, fill forms, pick matches, draft changes — then show a preview. The user taps confirm. Agents **never** auto-submit. Aligns with the trust-driven design system in `CLAUDE.md`. |
| How does the Task Handling agent affect tasker tier? | **AI recommends, rules + client reviews decide.** The agent *summarizes* completion evidence and *suggests* a 7-tier move; the actual tier change is driven by transparent rules + client ratings. Avoids fairness/bias critique. |
| Tasker matching output | **Ranked shortlist with reasons** (≤3), not a single silent auto-pick. The spoken "why I picked them" is the flagship demo moment. |
| Proactivity | **Gentle, non-blocking.** "Active-by-action" triggers are a soft Pho Wa Yoke nudge (mascot appears with a one-line offer), never an interrupting modal. The user can always ignore it. |

---

## 3. One agent, three session states

Pho Wa Yoke is always the same character (reusing the existing
`lib/core/widgets/mascot/` system and `PhoWaYokeState` art). What changes is
the **mode** (context) and the **session state** (how present it is):

| Session | Meaning | How entered |
|---|---|---|
| **Sleep** | Fully hidden. No nudges, no floating button. | User taps "sleep" — for users who find it annoying. |
| **Wakie** | Idle but available — a small floating Pho Wa Yoke button waits to be tapped. Default state. | Default; or waking from Sleep. |
| **Active** | Agent is engaged: listening, asking, filling, or explaining. | (a) User taps the button, or (b) a context trigger fires a *gentle* offer the user accepts. |

**Implementation:** a single shared Riverpod provider `agentSessionProvider`
(enum `AgentSession { sleep, wakie, active }`) plus `agentModeProvider`
(current context). This is a deliberate, documented exception to the
"providers live in one screen" rule, because agent state is app-wide. It is
the *only* new shared provider introduced.

The floating entry point can reuse / extend the existing
`lib/core/widgets/chatbot_fab.dart`.

---

## 4. The modes (agents)

Each mode below lists: **Purpose → Trigger → Behaviour (with the confirm
step) → Recommended fix → Tech**. "Tech" always follows the existing seam:
a Cloud Function in `functions/index.js` (proxying OpenAI, key server-side)
+ an `AiService` method + a synchronous offline fallback in `ai_mock.dart`,
so the demo never hangs.

### CLIENT SIDE

#### 4.1 Onboarding / Auth mode
- **Purpose:** Greet a first-time user, learn why they're here, and fill the
  onboarding forms *by voice* so non-readers/non-typers can still register.
- **Trigger:** App entry on the onboarding flow (`Routes.onboardingWelcome`
  and the client onboarding screens under `lib/features/onboarding/client/`).
- **Behaviour:** Greets → asks "what do you want to do here?" → **generates a
  sample script** so the user knows what to say and skips nothing → listens →
  extracts fields (name, gender, age, township, phone) → **fills the form and
  shows it for confirmation.** If voice fails or the user prefers, it hands
  off to the existing per-field manual entry (the `core/widgets/onboarding/`
  widgets already support per-field listen/speak).
- **Recommended fix:** Always land the user on the real form with fields
  pre-filled and editable — never submit blind. Read the filled form back
  aloud before "confirm."
- **Tech:** `speech_to_text` (on-device STT, Burmese locale, already wired) →
  new `extractOnboarding` Cloud Function (`askJson`, returns
  `{name, gender, age, township}` constrained/validated) → pre-fill
  `onboarding_state.dart`. Read-back via `flutter_tts`. Falls back to manual
  entry on any failure.

#### 4.2 Task-Posting mode
- **Purpose:** Turn a spoken/typed "my fan is broken" into a complete task.
- **Trigger:** User starts posting a task (`Routes.aiTaskPosting` /
  `Routes.voiceTaskPosting`). This mode largely **already exists** — this
  spec formalises it under the unified agent.
- **Behaviour:** Voice/text in → extract category, description, location,
  urgency → ask for the 1–2 missing details → **preview the task → user
  confirms → publish.** Manual multi-screen posting stays as the fallback
  path.
- **Recommended fix:** Keep the AI budget/attractiveness read-outs as
  *advice*, not gates. Preview must show every field the agent inferred.
- **Tech:** Existing `suggestCategory`, `rewriteDescription`, `analyzePrice`,
  `evaluateTask` functions + `AiService` methods. Voice via `speech_to_text`.
  Already has offline mock fallback.

#### 4.3 Tasker-Finding mode (matching)
- **Purpose:** Recommend the best taskers for a posted task, with reasons.
- **Trigger:** "Find a tasker" action on a task / `Routes.workerList`.
- **Behaviour:** Pre-filter + score candidates in Dart (real fields only) →
  LLM ranks the top and writes a one-line Burmese reason each → show a
  **ranked shortlist of ≤3** with real rating/tier/distance **plus the
  spoken reason** → **user picks one** (prepare-and-confirm holds: the agent
  recommends, the human chooses).
- **Recommended fix (critical):** The **LLM ranks and explains; it never
  invents.** It receives the app's own candidate list and may only return
  `id`s from it (same "constrain to the provided list" safety used in
  `suggestCategory`). Every displayed number is app data, not model output.
- **Tech:**
  - New Cloud Function `matchTaskers({ task, candidates }) -> { matches:
    [{ id, reason }] }`, ≤3, ids filtered against the candidate set.
  - New `AiService.matchTaskers({task, candidates})` returning
    `List<TaskerMatch>` (`workerId`, `reason`, `source`).
  - Offline fallback `_mockMatchTaskers`: deterministic weighted sort of
    `Worker` (`skill` match, `rating`, `distanceMiles`, `currentTier`,
    `completedTasks`, `isAvailableNow`, `isVerified`) + templated Burmese
    reasons from `TaskPostingStrings`.
  - UI: shortlist cards on `worker_list_screen.dart`; Pho Wa Yoke
    `thinking → success`; reason read aloud via `flutter_tts`.

#### 4.4 Task-Handling mode (three phases)
Maps onto the `TaskStatus` model scoped in
`2026-06-23-negotiation-status-data-model-scope.md`
(`pending → negotiating → confirmed → ongoing → completed`).

- **Phase 1 — Waiting (`pending`):** Agent watches how long a task has sat
  with no taker. After a threshold it *gently suggests* edits (raise budget,
  widen tier, clarify description) and can **flag a stale post to the ops
  team** for manual action.
  - *Tech:* time-since-post check in Dart; new `suggestTaskFixes({task,
    ageHours}) -> { tips: [...] }` Cloud Function for the wording; an
    ops-alert flag written to the backend (`backend/apps/tasks/`).
- **Phase 2 — Negotiation (`negotiating`/`confirmed`):** **Agent stays out of
  the way.** Client and tasker negotiate directly. (No AI here, by design.)
- **Phase 3 — Execution → completion (`ongoing`/`completed`):** Agent
  summarizes completion evidence (time taken vs. estimate, client review
  text/rating) and **recommends** a tier move with a plain-language reason.
  The **actual** tier change is applied by transparent rules + client rating,
  never by the model alone.
  - *Tech:* new `summarizeCompletion({task, timing, review}) -> { summary,
    suggestedTierDelta, rationale }` Cloud Function; the tier engine (rules)
    lives in the backend `taskers`/`tasks` apps and treats the AI output as an
    input signal only.

#### 4.5 Overall mode (navigation + chat)
- **Purpose:** Ask anything about the app; be taken to the right screen.
- **Trigger:** `Routes.chatbot` / the floating agent button.
- **Behaviour:** Answers app/FAQ questions and, on intent, **navigates** the
  user to the page that fulfils the request (post a task, edit details, find
  a tasker). Already partly built as the RAG chatbot.
- **Recommended fix:** Extend the existing `action`/`intent` contract from
  `{post_task, find_task}` to a small routing table mapping intents →
  `Routes.*` constants. Navigation is still a *suggested* button the user
  taps, not an automatic jump.
- **Tech:** Existing `chatAssistant` Cloud Function (OpenAI + Pinecone RAG) +
  `AiService.chatAssistant`. Add intents → `Routes.*` map in the chat UI.
  Offline mock already exists.

### TASKER SIDE

#### 4.6 Onboarding / Auth mode (tasker)
- Same as 4.1, on the tasker onboarding screens
  (`lib/features/onboarding/tasker/`), plus **skills capture by voice** →
  pre-fills `tasker_skills_screen.dart`, mapped to the backend `Skill` model
  (`backend/apps/taskers/models.py`). Confirm before submit.
- **Tech:** `speech_to_text` + `extractOnboarding` (extended to return a
  `skills[]` list constrained to the app's known skill/category list).

#### 4.7 Task-Analyzing mode (tasker)
- **Purpose:** Find the most suitable *open tasks* for this tasker.
- **Trigger:** Tasker asks "find me work" on the dashboard
  (`Routes.dashboard`).
- **Behaviour:** Same inverted matching as 4.3 — pre-filter open tasks in
  Dart by the tasker's skills/township/tier, LLM ranks + explains, returns a
  **shortlist of task links** (ids only) the tasker taps to open.
- **Tech:** reuse the `matchTaskers` function shape inverted
  (`matchTasks({tasker, candidateTasks}) -> {matches:[{id, reason}]}`), same
  id-constraint and offline sort fallback.

#### 4.8 Task-Handling mode (tasker)
- **Purpose:** After a tasker accepts, keep them on track and briefed.
- **Behaviour:** Frequent **gentle reminders** to do the task in its time
  window; and per task, a **summary of what the client wants + suggested
  prep/tools**. (Matching itself is already handled by 4.7.)
- **Tech:** local reminder scheduling in-app; new `briefTasker({task}) ->
  { summary, suggestions }` Cloud Function (`askJson`); read aloud via
  `flutter_tts`. Offline fallback = templated summary from task fields.

#### 4.9 Overall mode (tasker)
- Same as 4.5, scoped to tasker routes (dashboard, profile, task execution).

---

## 5. Technology stack (summary)

| Concern | Technology | Status |
|---|---|---|
| LLM reasoning | OpenAI (via Firebase Cloud Functions in `functions/`, `askJson` JSON-mode; key in Secret Manager, never in the app) | Wired; add new functions |
| App-side AI seam | `lib/core/utils/ai_service.dart` (live-with-fallback) | Wired; add new methods |
| Offline safety | `lib/core/utils/ai_mock.dart` synchronous mocks | Wired; add new fallbacks |
| Speech → text | `speech_to_text` (on-device, Burmese locale) | Wired |
| Text → speech (read-aloud) | `flutter_tts`; `audioplayers` for pre-recorded auth clips | Wired |
| Navigation intent | GoRouter `Routes.*` constants | Wired |
| Knowledge/FAQ | Pinecone RAG (in `chatAssistant`) | Wired |
| Agent session/mode state | new shared Riverpod `agentSessionProvider` / `agentModeProvider` | New |
| Mascot presence | `lib/core/widgets/mascot/` + `chatbot_fab.dart` | Wired; extend |
| Backend signals (ops alert, tier engine, skills) | Django REST (`backend/apps/tasks`, `taskers`) | Partial |

**Rule reaffirmed:** every network AI call goes through a Cloud Function.
No OpenAI key ships in the Flutter app, even though a key is now available —
a key inside an APK is extractable. New functions reuse the existing
`OPENAI_API_KEY` secret and `taskOptions`.

---

## 6. Cross-cutting requirements

- **Trust / confirm:** No agent action that creates, submits, pays, or
  changes account data executes without a visible preview + explicit user
  confirm. This is a hard rule, not a preference.
- **Accessibility:** Every agent surface has a read-aloud control and a
  microphone control; nothing is voice-only or text-only. Reasons and
  summaries are Burmese-first, short, and patient.
- **No hallucinated facts:** Any list of real entities (taskers, tasks) is
  produced by Dart from app/backend data; the LLM only orders and explains,
  constrained to ids from the provided set.
- **Never hangs:** Every function has an offline mock fallback and a timeout
  (`AiConfig.timeout`), mirroring the current Task Posting behaviour.
- **Non-blocking proactivity:** context triggers surface a dismissible nudge,
  never a modal that traps the user.

---

## 7. Suggested build order (for the pitch)

1. **Tasker-Finding shortlist (4.3)** — highest demo value, smallest new
   surface; reuses the proven function pattern.
2. **Onboarding voice mode (4.1)** — the accessibility headline.
3. **Overall navigation/chat (4.5)** — mostly wiring an intent→route map onto
   the existing chatbot.
4. **One flagship end-to-end voice demo** stitched from the above: elderly
   user says "my fan is broken" → agent asks two questions → fills the task →
   shows a matched tasker with a spoken reason → user confirms. This single
   60-second flow sells the app better than nine half-built agents.
5. Task-Handling (4.4) and tasker-side handling (4.8) after, as depth.

---

## 8. Open questions / non-goals

- **Mode nicknames:** whether to give each mode a cute Burmese label (e.g. a
  "finder" name, a "helper" name) or keep it all as one un-named Pho Wa Yoke.
  Placeholder: one character, un-named modes; revisit for branding polish.
- **Proactivity thresholds:** exact "task sat too long" hours and how often
  tasker reminders fire — tune with real/demo timings, keep gentle.
- **Tier engine rules:** the transparent rule set that consumes the AI's tier
  suggestion is out of scope here — it belongs with the 7-Tier Trust System
  work (`taskers` backend).
- **Not in scope:** real SMS, real GPS (task location is demo-fixed), audio
  upload/Whisper (replaced by on-device STT), full negotiation UI (its own
  slice), and auto-submission of anything.
