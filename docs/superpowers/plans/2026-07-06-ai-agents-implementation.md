# AI Agents (Pho Wa Yoke) — Implementation Prompt for Claude Code

> Hand this file to Claude Code. It references the design spec at
> `docs/superpowers/specs/2026-07-06-ai-agents-design.md` — read that spec in
> full before writing any code. This plan is the *how to execute*; the spec is
> the *what/why*.

---

## Prompt (paste into Claude Code)

Read `docs/superpowers/specs/2026-07-06-ai-agents-design.md` in full, then
implement the AI agent modes it describes. Pho Wa Yoke is ONE agent with
context modes — do not build nine separate mascots.

**Non-negotiable guardrails (from the spec + CLAUDE.md):**

1. **Reuse the existing AI seam.** Every network AI feature = a Cloud Function
   in `functions/index.js` (proxying OpenAI via `openai.askJson`, key from the
   existing `OPENAI_API_KEY` secret) + a method in
   `lib/core/utils/ai_service.dart` + a synchronous offline fallback in
   `lib/core/utils/ai_mock.dart`. Follow the exact shape of `suggestCategory`
   / `analyzePrice`. Never ship an OpenAI key in the Flutter app.
2. **LLM ranks and explains; it never invents.** For any list of real entities
   (taskers, tasks), pre-filter and score in Dart from app/backend data, pass
   the candidates in, and constrain the model to return only `id`s from that
   set (drop any id not in the set), exactly like `suggestCategory` constrains
   to its list.
3. **Prepare + preview, user confirms.** No agent action creates, submits,
   pays, or edits account data without a visible preview and an explicit user
   confirm. Never auto-submit.
4. **Never hang.** Every live call uses `AiConfig.timeout` and falls back to
   the mock. The app must stay fully usable offline.
5. **Style only via theme tokens** (`core/theme/*`), navigate only via
   `Routes.*` constants, and keep new local UI state in-screen. The one
   allowed shared provider is the agent session/mode state
   (`agentSessionProvider` / `agentModeProvider`) — see spec §3.
6. **Accessibility:** every agent surface has a read-aloud (`flutter_tts`) and
   a microphone (`speech_to_text`, Burmese locale) control; reasons/summaries
   are Burmese-first and short.
7. `flutter analyze` must be clean and `flutter test` must pass before any
   slice is considered done. For backend functions, keep the response shapes
   in the spec so the Flutter fallback contract holds.

**Work in slices, in this order (spec §7). Complete, verify, and stop for
review after EACH slice — do not build all nine at once:**

- **Slice 1 — Tasker-Finding shortlist (spec §4.3).** Add the `matchTaskers`
  Cloud Function, `AiService.matchTaskers` + `TaskerMatch` model, the
  `_mockMatchTaskers` deterministic weighted-sort fallback, and the shortlist
  UI (≤3 cards with real rating/tier/distance + spoken reason, user picks one)
  on `worker_list_screen.dart` with Pho Wa Yoke `thinking → success`.
- **Slice 2 — Onboarding voice mode (spec §4.1 / §4.6).** `extractOnboarding`
  function + service method; pre-fill `onboarding_state.dart` and the
  tasker skills screen; read filled form back aloud; confirm before submit;
  manual entry fallback intact.
- **Slice 3 — Overall navigation/chat (spec §4.5).** Extend the existing
  `chatAssistant` action/intent contract with an intent → `Routes.*` map;
  navigation is a suggested button the user taps, not an auto-jump.
- **Slice 4 — Task-Handling (spec §4.4) and tasker-side handling (§4.8).**
  Stale-post nudge + ops flag, completion summary + *suggested* tier delta
  (rules/reviews decide the real tier), tasker reminders + per-task brief.
- **Agent shell (do first, lightweight):** the sleep / wakie / active session
  state (spec §3), reusing/extending `core/widgets/chatbot_fab.dart` and the
  `core/widgets/mascot/` system, so each slice above plugs into it.

For each slice: implement, run `flutter analyze` + `flutter test` (and the
relevant backend tests if a function changed), then summarise what changed and
pause for my review before starting the next slice.

---

## Notes for the human

- Two items are still open in the spec (§8): mode nicknames and proactivity
  thresholds. Decide these before Slice 4; Slices 1–3 don't depend on them.
- Slice 1 is the flagship demo — prioritise it if time is short.
