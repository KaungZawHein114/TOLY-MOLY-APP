# Negotiation + Status Data Model — Future Slice Scope

> Source: gap analysis against the user-provided "Task Posting System" logic
> spec, checked against the shipped Task Posting Flow
> (`docs/superpowers/specs/2026-06-22-task-posting-flow-design.md`). This
> document scopes a **future slice** — nothing here is implemented yet.

## 1. Why this is its own slice

The shipped flow collapses the AI budget straight into one `budgetMmk`
value at publish time, with no place to record a worker's counter-offer or
a task's lifecycle status. The full spec's negotiation/status model
(`aiSuggestedBudget` vs `finalBudget` vs `isNegotiated`, `TaskStatus`
pending→negotiating→confirmed→ongoing→completed) depends on a worker-side
accept/negotiate/decline UI and an in-app chat surface that don't exist yet
— building the data model without those screens would add fields nothing
reads or writes. This slice is **data-model only prep**; the chat/worker UI
that drives it is separate, larger, future work.

## 2. Goals / Non-goals

**Goals (this future slice, when picked up)**
- Extend `TaskPost` (`lib/core/data/demo_data.dart`) with the fields the
  spec's `Task` object requires for negotiation/status: `aiSuggestedBudget`,
  `finalBudget` (nullable), `isNegotiated`, `status` (new `TaskStatus` enum).
- Add `TaskStatus` enum: `pending`, `negotiating`, `confirmed`, `ongoing`,
  `completed` — mirrors the spec's status flow exactly.
- On publish (Screen 7), set `aiSuggestedBudget = draft.resolvedBudgetMmk`,
  `finalBudget = null`, `isNegotiated = false`, `status = TaskStatus.pending`
  — matches the spec's "Initial Budget State" / "Initial Status" rules.
- Keep `budgetMmk` removed/renamed to `aiSuggestedBudget` rather than kept
  alongside it — one source of truth for the AI number, not two.

**Non-goals (explicitly deferred past this slice)**
- No worker-side accept/negotiate/decline UI.
- No in-app chat surface (the spec's Scenario A/B negotiation examples).
- No code path that ever sets `finalBudget`/`isNegotiated`/advances `status`
  past `pending` — those mutations have no caller until the chat/worker UI
  exists, so adding them now would be dead code per this project's "no
  half-finished implementations" rule.
- No `taskId` string format (`"TM-2026-001"`), no `clientId`, no `title`
  field — these need a real ID scheme / auth concept respectively, both
  out of scope for Phase 1 (no backend).
- No Activity tab UI changes — `ActivityPlaceholderScreen` still doesn't
  read `postedTasksProvider`; that's its own future slice per §10 of the
  Task Posting Flow design doc.

## 3. Open question for whoever picks this up

Should `TaskStatus.pending` display anywhere before the Activity tab is
real? If not, this slice is purely a data-shape change with no visible UI
diff until Activity is built — worth sequencing *after* the Activity slice
rather than before, so the new fields have an actual reader as soon as
they land instead of sitting unread like `postedTasksProvider` does today.

## 4. Out of scope, permanently (per spec's own "Future" sections)

Matching Engine, Worker Ranking/Distance/Trust scoring, Task Creation
Agent, Budget Agent, Matching Agent, and the Domain/Data layer split
(`Task` entity, repository interfaces, Firestore/PostgreSQL repositories)
are explicitly Phase 4+ in the spec itself and in `CLAUDE.md`'s Phase 1
constraints (no backend, no new architecture layers). Not part of this
slice or its sequencing — listed here only so this doc doesn't get
mistaken for the full roadmap.
