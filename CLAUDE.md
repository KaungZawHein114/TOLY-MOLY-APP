# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TOLY MOLY — an on-demand service marketplace for Myanmar (Yangon-first) connecting customers with local workers (plumbing, cleaning, electrical, etc.). Flutter app, currently **Phase 1: a fully offline MVP** — hardcoded data, synchronous mock AI, no backend/database/network. See `docs/ARCHITECTURE.md` (full technical reference) and `docs/TEAM_PLAN.md` (ownership/roadmap) for details beyond this file.

## Commands

```bash
flutter pub get      # install dependencies
flutter run           # run on a connected device/emulator
flutter test          # run the widget test suite (test/widget_test.dart)
flutter test test/widget_test.dart --name "App boots to splash screen"  # run a single test
flutter analyze       # static analysis — must be clean before considering work done
```

## Architecture

```
assets/
└── mascot/                  # Pho Wa Yoke PNG states: idle, happy, thinking, pointing, success
lib/
├── main.dart              # entry point only: ProviderScope -> MaterialApp.router
├── core/
│   ├── constants/         # app_strings.dart (EN+Burmese copy), demo_mode.dart (phase flag)
│   ├── data/demo_data.dart    # ★ the ONLY data source — const models/lists, with fallbacks
│   ├── utils/ai_mock.dart     # ★ the ONLY "AI" source — synchronous keyword-matching mocks
│   ├── routing/app_router.dart # GoRouter config + the single global back-button handler
│   ├── theme/              # color/text/spacing tokens + ThemeData (light/dark)
│   └── widgets/             # theme-driven shared widgets (button, tile, card)
│       └── mascot/          # shared PhoWaYoke state, renderer, and message card
└── features/                # one folder per area: auth, customer, worker, chatbot
                              # UI + routing + local Riverpod state only
```

**Guiding seam:** all data flows through `demo_data.dart` and all "AI" flows through `ai_mock.dart` — these are the two files Phase 2 (real backend/AI) will swap behind the same shapes/signatures. Everything in `features/` is presentation + local state; it must not contain its own data or AI logic.

### Routing (`core/routing/app_router.dart`)
- One `ShellRoute` wraps every route group (`_authRoutes`, `_customerRoutes`, `_workerRoutes`, `_chatbotRoutes`) in `_RootBackHandler`, which owns Android back-button behavior globally — **no screen overrides back itself**.
- Verb rules: `context.push()` for all forward navigation; `context.pop()`/system back to go back; `context.go()` only for sanctioned stack resets (Splash→Role, "switch role", onboarding-complete→Dashboard, booking-done→Home).
- Unknown/errored routes fall back to `RoleSelectionScreen` via `errorBuilder` — no route may ever render blank/null.
- Route paths are namespaced by feature (`/auth/*`, `/customer/*`, `/worker/*`, `/chatbot`) and always referenced via `Routes.*` constants, never raw strings.

### State management
- Riverpod, but **local-only**: every `StateProvider`/`Provider` is declared inside the screen file that uses it. There are no global/shared provider files and no repository/notifier layers in Phase 1.
- No `FutureProvider`/`AsyncNotifier`/`FutureBuilder`/async `initState` — first frame must never depend on async state.

### Theme (`core/theme/`)
- `app_colors.dart` (raw hex values only), `app_text_styles.dart` (sizes/weights, no color), `app_spacing.dart` (spacing/sizes), `app_theme.dart` (assembles light/dark `ThemeData` from the above).
- Screens must never hardcode colors or text styles — use `Theme.of(context)` and the token classes.
- Borders and corner radius are not a rigid per-component contract — cards prefer fill + shadow over `Border.all` so tight grid layouts (e.g. category/skill pickers) don't overflow when content is long or text scale is large.

## Product design system

TOLY MOLY is a Myanmar-first, trust-driven, hyper-local task marketplace. The
interface must feel trustworthy, friendly, local, simple, human, and
accessible. A first-time user should always feel: "I know what to do, and I
trust this platform."

### Human-centered UX rules

- Design around the user's goal ("fix my fan"), not internal system language
  ("submit a service request").
- Give each screen one obvious primary action, clear hierarchy, and minimal
  cognitive load.
- Prefer recognition over recall: category cards, icons with labels, images,
  and voice assistance instead of typing or memorization.
- Reveal complexity progressively. Multi-step workflows should introduce only
  the information needed for the current step.
- Keep primary actions reachable within three taps wherever practical.
- Make trust visible through ratings, reviews, verification badges, worker
  tiers, distance, clear status, and secure-payment indicators.
- Use Myanmar-friendly modern illustrations: rounded shapes, friendly
  expressions, clean lines, minimal detail, and culturally relevant cues.

### Canonical color system

All colors must come from `AppColors`; never place raw hex values in screens or
widgets.

| Role | Color | Intended use |
|---|---|---|
| Purple 900 | `#1F194D` | Dark-mode surfaces, pressed states, header backgrounds |
| Purple 700 | `#2E266D` | Primary brand color, CTAs, navigation, active states |
| Purple 500 | `#4A3FA8` | Charts, progress states, tier badges |
| Purple 100 | `#E8E5FF` | Selected cards, soft highlights, filter backgrounds |
| Indigo 700 | `#2B3990` | AI features, search, recommendations, progress, secondary actions |
| Indigo 500 | `#4C5CC7` | Secondary buttons, AI indicators, analytics |
| Indigo 100 | `#E4E8FF` | AI cards, smart suggestions, assistant backgrounds |
| Blue 500 | `#BDD7FF` | Guidance cards, information surfaces, onboarding highlights |
| Blue 300 | `#DCEAFF` | Speech bubbles, help cards, information backgrounds |
| Blue 100 | `#F3F8FF` | Soft sections, onboarding cards, educational screens |
| Success | `#22C55E` | Verified and completed states |
| Warning | `#F59E0B` | Pending or attention-required states |
| Error | `#EF4444` | Errors, failures, rejection, and invalid input |
| Background | `#FFFFFF` | Main screen background |
| Surface | `#F8F9FC` | Cards, containers, and modal surfaces |
| Text primary | `#1F1F1F` | Titles and important content |
| Text secondary | `#6B7280` | Labels, descriptions, and helper text |
| Divider | `#E5E7EB` | Dividers and separators |

Primary CTA buttons use Purple 700 with white text. Secondary CTA buttons use
Indigo 700 with white text. Community Blue is a surface color, not body text
on white. All text must meet a minimum 4.5:1 contrast ratio.

The palette communicates trust through Purple, intelligence and AI through
Indigo, and community support through Blue. Pho Wa Yoke uses Purple for
clothing, Indigo for accessories, Community Blue for speech bubbles, and Blue
100 for supporting cards.

### Typography and components

- Primary Burmese typeface: Myanmar Thuriya.
- Display: 32–36 px bold; screen heading: 24–28 px bold; section title:
  18–20 px semibold; body: minimum 16 px regular; helper text: 14–16 px.
- Primary buttons: Purple 700 background, white text, and optional icon support.
- Secondary CTA buttons: Indigo 700 background and white text.
- Voice actions: prominent circular microphone controls on key workflows.
- Bottom navigation remains simple and predictable: Home, Tasks, Messages,
  Profile. Icons must always have text labels.

### Accessibility and emotional goals

- Minimum touch target is 48 px; prefer 56 px or larger for primary controls.
- Support elderly users, domestic workers, Burmese-first users, and people with
  low digital literacy through large controls, image-assisted navigation,
  voice input, and read-aloud support on key workflows.
- Every screen and feature must provide an obvious read-aloud control using a
  sound/speaker icon so users who cannot read can hear important text,
  instructions, form labels, statuses, and next steps.
- Every task flow and applicable text-entry area must provide a speech-to-text
  control using a speak/microphone icon so users who cannot write can enter
  information by voice.
- Voice controls must be large, consistently placed, visually distinct, and
  accessible by semantic labels. Do not rely on an icon alone when a short
  Burmese label or tooltip can clarify its purpose.
- Every task, category, and major feature should use a recognizable picture or
  icon alongside text. Examples include illustrated category cards for
  plumbing, electrical work, cleaning, repairs, and delivery.
- Placeholder images are acceptable during MVP development, but they must use
  stable shared asset/component references so actual photography or
  illustrations can replace them later without rewriting feature screens.
- Pictures and icons supplement text; they must not be the only way essential
  information is communicated. Add semantic descriptions for assistive
  technology.
- Clients should feel they can find help quickly; workers should feel they can
  earn confidently; elderly users should understand the next step.
- The design succeeds when a first-time Myanmar user can create an account,
  post a task, and understand what happens next without assistance.

## Phase 1 constraints (do not violate without explicit instruction)

1. No backend, no database, no network calls of any kind.
2. No `async`/`await` in app/data/business logic (framework-internal async is fine).
3. All data comes from `demo_data.dart`; all AI responses come from `ai_mock.dart`. No new data/AI sources.
4. No new architecture layers (no service/repository/domain) — these are deferred to Phase 4.

## Adding a new feature safely

Touch only the new screen file and `app_router.dart`:
1. Create the screen in the correct `features/<area>/` folder; read data from `demo_data.dart`; style only via theme tokens.
2. Add a route constant to the matching group in `Routes`, then register a `GoRoute` in that group's list (it's auto-wrapped by the global back handler).
3. Navigate to it with `context.push(Routes.yourRoute)` (use `go()` only for a deliberate reset).
4. Any local state goes in `StateProvider`s declared inside that screen file only.
5. Verify `flutter analyze` is clean and the back-button table in `docs/ARCHITECTURE.md` §5.7/§8 still holds.

## Pho Wa Yoke mascot

Pho Wa Yoke (`ဖိုးဝရုပ်`) is TOLY MOLY's shared digital guide and community
helper. He supports navigation, onboarding, task creation, empty states, AI
feedback, and completion moments. He is a visual guide, not a chatbot.

### Architecture

Mascot code belongs in `lib/core/widgets/mascot/` because it is shared by the
customer, worker, AI, onboarding, and empty-state flows:

```text
lib/core/widgets/mascot/
├── mascot_state.dart          # state enum and only asset-path mapping
├── pho_wa_yoke.dart           # reusable image and animation renderer
└── mascot_message_card.dart   # mascot plus short guidance message
```

Screens must use the shared widget and never reference mascot PNG paths:

```dart
PhoWaYoke(state: PhoWaYokeState.happy)
```

For guidance copy:

```dart
MascotMessageCard(
  state: PhoWaYokeState.pointing,
  message: 'ဒီခလုတ်ကို နှိပ်ပါနော်',
)
```

`PhoWaYokeState` is the single source of truth:

- `idle` — home, dashboard, and empty states
- `happy` — splash, welcome, and onboarding
- `thinking` — AI search, budget suggestions, and recommendations
- `pointing` — forms, task posting, and tutorials
- `success` — posted tasks, confirmed bookings, and completed profiles

### Product and content rules

- Prioritize the mascot on splash/welcome, role selection, onboarding, AI task
  search, task posting, and success screens.
- Use it selectively for empty states, profile completion, and verification.
- Do not place it on worker cards, task cards, navigation bars, or every header;
  it should remain meaningful and helpful.
- Guidance is Burmese-first, short, patient, supportive, and easy to understand.
- Never blame users or use technical or complicated instructions.
- The mascot supports accessibility and low digital literacy by reducing fear
  and explaining one step at a time.
- Current implementation uses five static PNGs with simple Flutter transitions.
  Screens depend only on `PhoWaYoke`, allowing a future PNG → SVG → Rive
  migration without feature-level changes.
