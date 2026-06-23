# Tasker Explore & Discovery — Design Spec

> Source: user-provided "Tasker Explore & Discovery Logic Document" (MVP
> 1.0) and "TOLY MOLY — 7-Tier Trust System Logic Document" (MVP 1.0). This
> design replaces the existing hourly-pricing worker browsing flow
> (`worker_list_screen.dart` → `worker_profile_screen.dart` →
> `booking_screen.dart`) with the spec's task-based one. The full Trust
> Point formula/progression system is **not** built here — see §8.

## 1. Scope

This redesign touches the existing worker-browsing flow only. It does not
touch the Task Posting Flow (already shipped) or Activity (still a
placeholder). Two adjacent concerns are explicitly deferred:

- **Trust Point formula + tier progression** (base points, complexity
  modifiers, reliability bonus, urgency multiplier, tier-up triggers,
  rewards/benefits) — display-only this slice. See §8.
- **Activity tab content** — `TaskRequest`s are held in an in-memory
  provider that nothing reads yet, same pattern as `postedTasksProvider`.

## 2. Goals / Non-goals

**Goals**
- Replace hourly pricing everywhere in this flow: `Worker.hourlyRateMmk` is
  removed; no screen shows a rate or computes hours × rate.
- `WorkerListScreen` becomes Tasker Explore: category/trust-tier/rating/
  township filters, 4 sort options, and a default Matching Score ranking.
- `WorkerCard` shows trust badge, rating, completed tasks, distance (km),
  verification, availability — no price.
- `WorkerProfileScreen` drops the rate row and hourly Book CTA; adds trust
  badge + completed tasks; "Book Now" becomes "အလုပ်အပ်မည်" → Schedule
  Worker screen.
- `BookingScreen` is repurposed into the Schedule Worker screen: category
  (locked to the worker's skill), location, date, time, description
  (text + voice) → submits a `TaskRequest` (`status: pending`).
- Migrate this flow's colors off the legacy `teal`/`onBrand` tokens onto
  the canonical palette (`purple700` primary, `indigo700` for AI-adjacent
  bits) per `CLAUDE.md`'s color system — these screens predate it.

**Non-goals**
- No Trust Point formula, no tier-up logic, no rewards/benefits unlocking.
- No real matching engine / worker ranking beyond the MVP formula's display
  ordering — no persistence, no backend scoring.
- No Activity tab changes — `TaskRequest`s sit in an unread provider.
- No certificates field/display (not in the data model; spec lists it as
  optional profile content, dropped to avoid adding a fake data source for
  one line of UI).
- No multi-category-per-worker model — `Worker.skill` (singular) stays the
  category match field.

## 3. Resolved scope decisions

| Open question | Decision |
|---|---|
| Hourly pricing flow | Replaced entirely — no parallel/legacy path kept. |
| Trust System scope | Display-only: `currentTier` + derived badge. No point formula. |
| Schedule Worker UI | Full routed screen (existing `Routes.booking/:id`), not a modal. |
| Category field in Schedule Worker | Pre-filled and locked to `worker.skill`, not editable. |
| `TaskRequest` vs reusing `TaskPost` | New, smaller model — `TaskPost`'s `workersNeeded`/`workerTier`/`urgent` don't apply to a direct single-worker request. |
| Distance unit | Keep storing `distanceMiles`; format as km only at display time (spec's copy is "X km Away"). |

## 4. Data model

`lib/core/data/demo_data.dart` — extend `Worker`:

```dart
class Worker {
  final int id;
  final String name;
  final String skill;
  final String emoji;
  final double rating;
  final int reviews;
  final String experience;
  final double distanceMiles;
  final bool isAvailableNow;
  final String bio;
  final int currentTier;        // 1-7, static demo value — drives the badge only
  final String township;        // one of the 4 demo townships below
  final int completedTasks;
  final bool isVerified;
  // hourlyRateMmk REMOVED
  ...
}
```

Demo townships (matching the spec's examples), distributed across the 16
existing workers: လှိုင်၊ ကမာရွတ်၊ မရမ်းကုန်း၊ အင်းစိန်. `currentTier`/
`completedTasks`/`isVerified` get plausible static values per worker
(higher-rated workers get higher tiers — no formula, just consistent demo
data).

`WorkerTierLabel`-style extension for the badge (new, in `demo_data.dart`
next to `Worker`, since it's a pure derivation from `currentTier`):

```dart
String trustBadgeFor(int tier) {
  if (tier <= 2) return "Community Helper";
  if (tier <= 5) return "Verified Professional";
  return "Community Ambassador";
}
```

(English badge names match the Trust System doc's exact tier-band labels;
Burmese label added to `app_strings.dart` per band for the read-aloud copy.)

New model, `lib/core/data/demo_data.dart` (alongside `TaskPost`):

```dart
class TaskRequest {
  final int id;
  final int workerId;
  final String category;     // == the worker's skill, locked
  final String township;
  final String address;
  final DateTime date;
  final String timeSlot;
  final String description;
  final DateTime createdAt;
  // status is always "pending" this slice — no enum needed yet,
  // matching TaskPost's precedent of not modeling unreachable states
  const TaskRequest({ ...required fields... });
}
```

`lib/features/customer/task_request_state.dart` (new, mirrors
`task_posting_state.dart`):

```dart
final postedTaskRequestsProvider = StateProvider<List<TaskRequest>>((ref) => []);
```

## 5. Filtering, sorting, ranking (`worker_list_screen.dart`)

**Filters** (combinable, all optional):
- Category — existing skill chip row, unchanged mechanic.
- Trust level — 3 chips (Basic/Trusted/Expert) mapping to tier ranges 1-2 /
  3-5 / 6-7, same friendly labels as Task Posting's `WorkerTier`. Reuses
  the `WorkerTier` enum from `task_posting_models.dart` for the tier-range
  values only (no cross-feature state coupling — just the enum).
- Rating — chips: 4.0+, 4.5+, 4.8+.
- Township — chips from the 4 demo townships.

**Sort** (`WorkerSort` enum, replaces today's `distance/rating/priceLow`):
`distance | rating | tier | completedTasks`. Dropdown unchanged in
mechanic, options/labels updated; `priceLow` removed.

**Default ranking** (when the user hasn't picked an explicit sort): Matching
Score, descending —

```text
score = trustScore*0.4 + ratingScore*0.3 + distanceScore*0.2 + completionScore*0.1
```

Demo-deterministic normalization (no randomness): `trustScore = tier/7*100`,
`ratingScore = rating/5*100`, `distanceScore = max(0, 100 - distanceMiles*1.609*10)`,
`completionScore = min(100, completedTasks/2)`. Picking an explicit sort
overrides this — same precedence the spec implies ("Sorting Logic" as a
user action distinct from the ranking the system applies by default).

## 6. `WorkerCard` (`lib/core/widgets/demo_card.dart`)

Row layout, replacing the price row:
- Avatar (unchanged: emoji + green availability dot).
- Name + trust badge (small pill, e.g. "🏅 Verified Professional").
- Rating (★ rating) + "✓ Verified" if `isVerified`.
- Distance in km + completed-tasks count ("📍 2 km · 84 Tasks").
- No price anywhere on the card.

Colors migrated to canonical tokens: badge pill uses `AppColors.purple100`
background / `purple700` text (trust = purple, per `CLAUDE.md`); availability
dot stays `success`/green semantic color (already canonical).

## 7. `WorkerProfileScreen` + Schedule Worker screen

**Profile** (`worker_profile_screen.dart`): drop `_RateRow` and the
rate-suffixed Book CTA label entirely. Add a trust badge row near the name
(reuses the same badge widget as the card) and a "📋 N Tasks Completed"
stat alongside rating/distance/experience. Primary CTA becomes
`"အလုပ်အပ်မည်"` (no rate suffix), still pushes to
`'${Routes.booking}/${worker.id}'` (route path unchanged — only its screen
content changes, so no router edit needed beyond the builder).

**Schedule Worker** (`booking_screen.dart`, content fully replaced): reuses
the visual language already established by the Task Posting Flow —
`WorkerStrip` header kept as-is (it already has no price reference), then:
- Category — read-only display of `worker.skill` (locked, per §3).
- Location — township + address text fields (reuse the exact pattern from
  `task_type_location_screen.dart`).
- Date/time — reuse `ChoiceWrap`/native picker pattern already in this
  file today (no need to import the Task Posting screens directly — same
  shape, screen-local).
- Description — `TextField` + `SpeechToTextButton`, same as
  `task_description_screen.dart`'s pattern.
- Submit ("ပြန်လည်အတည်ပြုမည်" or similar confirm label) validates
  date/time/description non-empty, builds a `TaskRequest`, appends to
  `postedTaskRequestsProvider`, shows a confirmation dialog (reuse the
  existing dialog shell, new copy: "Task Request Sent!" — no price line).

## 8. Future slice: full 7-Tier Trust System

Not built now — listed for continuity, per the Trust System doc:
- `WorkerTrustProfile` (trustPoints, completionRate, disputeCount) and the
  full point formula (base points by category, complexity modifiers,
  reliability bonus, urgency multiplier).
- Tier-up triggers, reward unlocking (commission %, badges, bonuses),
  retention requirements (Tier 7's 4.9+/15-tasks-per-month).
- Matching Engine integration beyond the MVP display-ranking formula in §5
  (this slice's formula is for sort order only — it does not feed back
  into `currentTier` or persist anywhere).
- This is a large, separate data + (eventually) backend feature — explicit
  Phase 4+ territory per `CLAUDE.md`, not sequenced here.

## 9. Testing

- Update/replace whatever `worker_list_screen`/`booking_screen` widget
  tests exist today (check `test/` for current coverage before editing —
  not yet confirmed) to match new filter/sort/no-price assertions.
- New test: Schedule Worker happy path (profile → schedule screen →
  submit → confirmation, `TaskRequest` appended).
- `flutter analyze` clean, full `flutter test` passing, no git actions
  (standing instruction).
