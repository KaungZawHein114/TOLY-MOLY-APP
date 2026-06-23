# Task Posting Flow — Design Spec

> Source: user-provided detailed spec for the "Task Posting Flow" — the
> piece explicitly deferred from the Client Home Screen slice
> (`docs/superpowers/specs/2026-06-22-client-home-screen-design.md`), which
> shipped a `PostTaskPlaceholderScreen` at `Routes.postTask` as a stub for
> exactly this. This design replaces that placeholder.

## 1. Scope

Unlike the original mega-spec, this is one cohesive flow (like the
onboarding flow already shipped), not several independent subsystems — it
does not need further decomposition. Two adjacent concerns it touches are
explicitly scoped out:

- **Global AI Assistant** (floating Pho Wa Yoke button, "available on
  every screen") — deferred again, same call as the Home screen slice.
  This flow ships with no floating assistant button.
- **Activity tab content** — `ActivityPlaceholderScreen` stays untouched.
  The success modal's "လုပ်ဆောင်ချက်များ သို့ သွားမည်" button still navigates
  there; it still shows "coming soon." The created task is held in an
  in-memory provider that nothing currently reads.

## 2. Goals / Non-goals

**Goals**
- Build all 7 screens (AI/category select → task type+location → date/time
  → workers+tier+urgency → description → budget → review/publish) plus the
  success modal, replacing `PostTaskPlaceholderScreen`.
- Reuse existing shared widgets wherever the shape matches: `OnboardingScaffold`
  (header/back/title/progress/`StaggeredEntrance` body/bottom-bar slot),
  `OnboardingSelectionCard`, `ChoiceWrap`, `SpeechToTextButton`,
  `ReadAloudButton`, `ServiceCategoryCard`.
- Give `ai_mock.dart`'s currently-dead `categorizeJob`/`suggestService` a
  real caller (Screen 1); add `generateTaskDescription` and `suggestBudget`
  mock functions following the same synchronous, keyword/deterministic
  style as the rest of that file.
- Extend `_skillForQuery`'s keyword map with Burmese terms — the spec's own
  example input (`ရေယိုနေတယ်`) doesn't match any of the current English-only
  keywords, so AI category detection would silently fail on the spec's own
  worked example without this.
- Keep the visual/motion language identical to onboarding (same scaffold,
  same `AppMotion`/`StaggeredEntrance`, same fade+slide-up route transition).

**Non-goals**
- No Global AI Assistant (floating/shell-level) — see §1.
- No changes to `ActivityPlaceholderScreen` — see §1.
- No real map integration — the "📍 မြေပုံမှ ရွေးမည်" button is a mock
  (snackbar: "ဒီ Demo တွင် မြေပုံ မရှိသေးပါ"), consistent with this app's
  Phase 1 invariant (no network/backend of any kind).
- No persistence — `taskDraftProvider`/`postedTasksProvider` are in-memory
  only and reset on app restart, same as every other piece of state in this
  app today.
- No renaming of `OnboardingScaffold` to a generic name (considered and
  rejected for this slice — see §4).

## 3. Resolved scope decisions

| Open question | Decision |
|---|---|
| Global AI Assistant | Still deferred (own future slice). |
| Activity tab / created task data | Left untouched; task is held in an unread provider, not displayed anywhere yet. |
| Screen 1's "Previous" button | Not shown — header back arrow only (no prior step exists). Previous appears from Screen 2 onward. |
| Shared chrome | Reuse `OnboardingScaffold` directly (no rename/extraction this slice). |

## 4. Shared chrome: reusing `OnboardingScaffold`

No changes to `lib/core/widgets/onboarding/onboarding_scaffold.dart` itself.
Each task-posting screen passes:
- `progress: OnboardingProgress(step: N, totalSteps: 7)`
- `title:` the screen's Burmese title from the spec
- `bottomBar:` a `Row` of `[Previous (outlined LargeButton, screens 2-7 only), Continue (filled LargeButton)]`
- `onBack:` `context.pop()` on screens 2-7; on Screen 1, a confirm-dialog
  pop back to Home if any field in `taskDraftProvider` is non-empty
  (mirrors the existing onboarding `_confirmExit` pattern in spirit, but
  screen-local since this is a "discard draft?" confirmation, not the
  global app-exit dialog — it does not touch `_RootBackHandler`).

Accepted naming leak: this file lives under `core/widgets/onboarding/` and
this flow isn't onboarding. Several other widgets this flow reuses
verbatim live in the same folder for the same reason (`OnboardingSelectionCard`,
`ChoiceWrap`, `SpeechToTextButton`, `ReadAloudButton`, `StaggeredEntrance`).
Renaming that folder/these files to something generic is worth doing later,
as its own dedicated cleanup, not bundled into this feature's diff.

## 5. Data model + shared state

`lib/features/customer/task_posting/task_posting_models.dart`:

```dart
enum TaskType { onSite, remote }
enum WorkerTier { basic, trusted, expert } // friendly labels only in UI, never tier numbers

class TaskDraft {
  final String? category;            // internal skill name, e.g. "Plumber" — matches demo_data's Worker.skill strings
  final TaskType? taskType;
  final String township;
  final String address;
  final DateTime? date;
  final String? timeSlot;            // one of "မနက်"/"နေ့လည်"/"ညနေ"/"ည", or a custom "HH:mm" string
  final bool urgent;
  final int workersNeeded;           // default 1, range 1-10
  final WorkerTier? workerTier;
  final String description;
  final int? suggestedBudgetLowMmk;
  final int? suggestedBudgetHighMmk;
  final int? marketPercent;          // from suggestBudget's market-insight figure
  final int? customBudgetMmk;        // non-null only when useAiBudget == false
  final bool useAiBudget;            // default true

  const TaskDraft({
    this.category,
    this.taskType,
    this.township = "",
    this.address = "",
    this.date,
    this.timeSlot,
    this.urgent = false,
    this.workersNeeded = 1,
    this.workerTier,
    this.description = "",
    this.suggestedBudgetLowMmk,
    this.suggestedBudgetHighMmk,
    this.marketPercent,
    this.customBudgetMmk,
    this.useAiBudget = true,
  });

  factory TaskDraft.empty() => const TaskDraft();

  TaskDraft copyWith({ ...same-named optional params... }) => TaskDraft(
    category: category ?? this.category,
    // ...standard copyWith pattern matching ClientProfileDraft/TaskerProfileDraft
  );
}
```

`lib/features/customer/task_posting/task_posting_state.dart`:

```dart
final taskDraftProvider = StateProvider<TaskDraft>((ref) => TaskDraft.empty());

// Written by Screen 7 on publish; not read anywhere yet (Activity stays
// untouched per §1) — exists so the created task isn't silently discarded,
// and so Activity's future slice has an obvious place to start reading from.
final postedTasksProvider = StateProvider<List<TaskPost>>((ref) => []);
```

`TaskPost` (the published, immutable record) is added to
`lib/core/data/demo_data.dart` alongside `Booking`, since it's app data,
not flow-local UI state — but it is a distinct model from `Booking`
(`Booking` represents an already-matched job with a `workerName`; a fresh
task post has no worker yet):

```dart
class TaskPost {
  final int id;
  final String category;
  final TaskType taskType;
  final String township;
  final String address;
  final DateTime date;
  final String timeSlot;
  final bool urgent;
  final int workersNeeded;
  final WorkerTier workerTier;
  final String description;
  final int budgetMmk;        // resolved: either the AI suggestion's midpoint or customBudgetMmk
  final DateTime createdAt;
  const TaskPost({ ...required fields... });
}
```

(`TaskType`/`WorkerTier` enums live in `task_posting_models.dart` and are
imported by `demo_data.dart` — the one cross-import this introduces between
a feature folder and core data, justified because `TaskPost` needs them and
duplicating the enums would be worse.)

## 6. Screen-by-screen

### Screen 1 — `ai_category_screen.dart`
- `OnboardingScaffold(progress: 1/7, title: "ဘာအကူအညီ လိုအပ်ပါသလဲ")`, Continue-only bottom bar, back = confirm-discard-if-dirty.
- **Option A (AI):** multiline `TextField` + `SpeechToTextButton`. On text change, call `categorizeJob(text)` (live caller for previously-dead code) and show an `OnboardingSelectionCard`-styled suggestion ("ပိုက်ပြင်ခြင်း" for the spec's "ရေယိုနေတယ်" example) with an "အတည်ပြုမည်" confirm action that sets `taskDraftProvider.category`.
- **Option B (manual):** `GridView` of `ServiceCategoryCard` for the 8 categories; tapping sets `category` directly.
- Continue enabled only once `category` is non-null.

### Screen 2 — `task_type_location_screen.dart`
- Two `OnboardingSelectionCard`s (on-site / remote) → `taskType`.
- Township + address `TextField`s and a mock "📍 မြေပုံမှ ရွေးမည်" button,
  rendered only when `taskType == TaskType.onSite`.
- Continue requires `taskType` set, and if on-site, township+address non-empty.

### Screen 3 — `date_time_screen.dart`
- `showDatePicker` → `date`.
- 4 quick-pick time chips → `timeSlot`; "⏰ အချိန်ရွေးမည်" opens `showTimePicker`
  for a custom value, formatted into the same `timeSlot` field.
- "⚡ အခုချက်ချင်း" sets `urgent = true` and auto-fills `date`/`timeSlot` to
  "now" so the rest of the screen is satisfied immediately.
- Continue requires `date` and `timeSlot` both set.

### Screen 4 — `workers_tier_urgency_screen.dart`
- Stepper (min 1, max 10) → `workersNeeded`.
- 3 `OnboardingSelectionCard`s with the spec's exact friendly labels/descriptions
  (no tier numbers anywhere in the UI) → `workerTier`.
- `Switch` → `urgent` (same field Screen 3's shortcut may have already set —
  reflects whatever value is already in the draft, no duplicate state).
- Continue requires `workerTier` set.

### Screen 5 — `task_description_screen.dart`
- Multiline `TextField` + `SpeechToTextButton` → `description`, directly editable.
- "AI က ရေးပေးမည်" calls `generateTaskDescription(category, currentText)` and
  replaces the field's content; still editable afterward.
- Continue requires non-empty `description`.

### Screen 6 — `budget_screen.dart`
- Read-only "AI Analysis Card" summarizing category/location/urgency/tier/worker-count from `taskDraftProvider`.
- `suggestBudget(...)` populates `suggestedBudgetLow/HighMmk` + `marketPercent`.
- Two `OnboardingSelectionCard`s: AI suggestion (`useAiBudget = true`) vs.
  custom (`useAiBudget = false`, reveals a numeric `TextField` → `customBudgetMmk`).
- Continue requires `useAiBudget == true`, or a valid positive `customBudgetMmk`.

### Screen 7 — `review_publish_screen.dart` + success modal
- Summary card listing every draft field with per-row "Edit" links that
  `context.push` back to the owning screen (shared provider means no
  special edit-mode plumbing needed).
- "အလုပ်တင်မည်" (`celebratory: true` `LargeButton`) builds a `TaskPost`,
  appends to `postedTasksProvider`, shows the success modal.
- Success modal (`showDialog`, not a full screen): 🎉 + the two message
  lines + two buttons. Both reset `taskDraftProvider` to `.empty()` first.
  "လုပ်ဆောင်ချက်များ" → `context.go(Routes.customerHome)` then switches the
  shell's tab index to Activity (1). "ပင်မသို့ ပြန်မည်" → `context.go(Routes.customerHome)`
  (Home tab).

## 7. Routing

```dart
static const String postTask = '/customer/post-task';                       // Screen 1 (unchanged path/name)
static const String postTaskTypeLocation = '/customer/post-task/type-location';
static const String postTaskDateTime = '/customer/post-task/date-time';
static const String postTaskWorkersTier = '/customer/post-task/workers-tier';
static const String postTaskDescription = '/customer/post-task/description';
static const String postTaskBudget = '/customer/post-task/budget';
static const String postTaskReview = '/customer/post-task/review';
```

All 7 registered via `pageBuilder: (ctx, state) => _onboardingTransitionPage(...)`
(the existing fade+slide-up helper already used by the redesigned onboarding
routes) instead of plain `builder:`. `Routes.postTask`'s value is unchanged,
so the Home screen's quick-action button needs no edits.
`PostTaskPlaceholderScreen` and its route registration are deleted.

## 8. `ai_mock.dart` additions

- Burmese keywords merged into the existing `_skillForQuery` map (1-2 terms
  per existing category — e.g. `"Plumber": [..., "ရေယို", "ပိုက်", "ရေပိုက်"]`),
  not an exhaustive translation layer.
- `String generateTaskDescription(String category, String userInput)` —
  canned-per-category template, matching the spec's own worked example
  (`category == "Plumber"` → `"အိမ်တွင် ရေပိုက်ယိုနေပါသည်။ ပိုက်ပြင်ကျွမ်းကျင်သူ
  လိုအပ်ပါသည်။"`).
- `({int low, int high, int marketPercent}) suggestBudget(String category, bool urgent, WorkerTier tier, int workersNeeded)` —
  deterministic (no randomness): a base MMK range per category×tier, a fixed
  urgent surcharge, and a multiplier for `workersNeeded`, so the same inputs
  always reproduce the same numbers across a demo run.

## 9. Testing

- `task_posting_flow_test.dart`: full happy-path walk (Screen 1 manual
  category → ... → Screen 7 publish → success modal → back to Home),
  exercising every `context.push`/Continue-enablement gate along the way.
- Focused test for Screen 1's AI path: typing the spec's example text calls
  `categorizeJob` and the suggestion card reflects "Plumber"/"ပိုက်ပြင်ခြင်း".
- Overflow probe (narrow width × 1.6× text scale, the established pattern
  from `onboarding_scaffold_overflow_test.dart`) applied to Screen 4 (its
  stepper + 3 selection cards + switch make it the densest screen).
- `flutter analyze` clean (no new issues beyond the 2 pre-existing,
  unrelated `activeColor` deprecation infos); full `flutter test` passing.

## 10. Future slices (not built now, listed for continuity)

- Global AI Assistant (floating, app-shell-level).
- Real Activity tab content, reading from `postedTasksProvider`.
- Real map picker (replacing the mock "📍 မြေပုံမှ ရွေးမည်" snackbar).
- `core/widgets/onboarding/` → generic rename, now that a second feature
  (this one) depends on widgets in that folder for non-onboarding reasons.
