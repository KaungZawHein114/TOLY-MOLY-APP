# TOLY MOLY — Technical Documentation

> **Read time: ~10–15 minutes.** This is the single source of truth for the
> architecture. Read it before touching the codebase.

---

## 1. Project overview

**TOLY MOLY** is an on-demand service marketplace for Myanmar (Yangon-first,
Burmese-friendly). It connects **customers** who need a task done (plumbing,
cleaning, electrical, AC repair, tutoring, delivery, …) with local **workers**
("taskers") who accept bookings.

> Core philosophy: *"Hire for the task, pay for the work, done in a day."*

### Current phase — Phase 1: Flutter-only offline MVP

The app is a **fully clickable, 100% offline demo** built for presentation.
Stability and smooth navigation are the priority.

**What IS included:**
- A complete Flutter UI (Android + iOS), ~20 screens — a multi-step,
  Burmese-first onboarding flow (account creation → role choice → personal
  info → phone OTP mock → skills/profile → rules → completion) plus the
  customer journey, worker dashboard, and chatbot.
- Hardcoded demo data (compile-time Dart constants).
- A synchronous **mock** AI layer (keyword matching, no network).
- GoRouter navigation with a centralized, fail-safe back-button system.
- A design-system theme layer (light + dark) plus a shared Pho Wa Yoke mascot
  system used throughout onboarding.

**What is NOT included (by design, in Phase 1):**
- ❌ No backend (no Django/Node/REST/Firebase).
- ❌ No database (no SQLite/PostgreSQL/persistence).
- ❌ No real AI (no OpenAI/Gemini, no API keys).
- ❌ No network calls of any kind (no HTTP/WebSocket).
- ❌ No runtime file/JSON loading.
- ❌ No `async`/`await` in app logic, data, or UI flow (framework async only).
- ❌ No native splash screen — the app boots directly into the onboarding
  Welcome screen, which renders fully on the first frame.

These are intentionally deferred to later phases (see §9).

---

## 2. Full architecture explanation

### 2.1 Folder structure (every folder, and why it exists)

```
assets/
├── logo.png                   # Source image for app icons (flutter_launcher_icons).
│                               # NOT a runtime Flutter asset — nothing in lib/ loads it.
└── mascot/                    # Pho Wa Yoke PNGs (idle/happy/thinking/pointing/success),
                                # transparent background (no white backdrop).
lib/
├── main.dart                  # App entry point. Wires theme + router. Nothing else.
│
├── core/                      # Cross-cutting infrastructure shared by all features.
│   ├── constants/
│   │   ├── app_strings.dart       # Static UI text (EN + Burmese), non-onboarding screens.
│   │   ├── onboarding_strings.dart # Burmese-first copy for the whole onboarding flow.
│   │   └── demo_mode.dart         # const DEMO_MODE = true (phase switch).
│   │
│   ├── data/
│   │   └── demo_data.dart     # ★ CORE 1: the ONLY data source (const lists). Swappable.
│   │
│   ├── utils/
│   │   └── ai_mock.dart       # ★ CORE 2: the ONLY AI source (sync mocks). Swappable.
│   │
│   ├── routing/
│   │   └── app_router.dart    # GoRouter config + centralized back-button handler.
│   │
│   ├── theme/                 # Design system. The ONLY place styling values live.
│   │   ├── app_colors.dart    # Color tokens, gradients, shared shadow tokens.
│   │   ├── app_text_styles.dart # Typography tokens (sizes/weights, no color).
│   │   ├── app_spacing.dart   # Spacing / radius / size tokens.
│   │   └── app_theme.dart     # Builds ThemeData (light + dark) from the tokens.
│   │
│   └── widgets/               # Reusable, theme-driven UI building blocks.
│       ├── large_button.dart  # Primary button (filled gradient or outlined).
│       ├── skill_tile.dart    # Square category/skill tile (customer home grid).
│       ├── demo_card.dart     # WorkerCard + StatusBadge.
│       ├── mascot/            # Shared Pho Wa Yoke mascot system.
│       │   ├── mascot_state.dart        # PhoWaYokeState enum + asset-path mapping.
│       │   ├── pho_wa_yoke.dart         # Animated (idle-breathing) mascot image.
│       │   └── mascot_message_card.dart # Mascot + short guidance message bubble.
│       └── onboarding/         # Shared chrome/inputs reused across every onboarding step.
│           ├── onboarding_scaffold.dart      # Shared screen shell (header, mascot, progress, body, bottom bar).
│           ├── onboarding_progress_header.dart # Step label + progress bar.
│           ├── onboarding_selection_card.dart  # Selectable card (role/gender/skill/etc).
│           ├── choice_wrap.dart                # Wrap of selection cards for single-choice questions.
│           ├── phone_otp_form.dart             # Phone + mock OTP (demo code 12345).
│           ├── profile_picture_picker.dart     # Mock camera/gallery picker.
│           ├── read_aloud_button.dart          # Mock text-to-speech control.
│           └── speech_to_text_button.dart      # Mock speech-to-text control.
│
└── features/                  # One folder per product area. UI + local state only.
    ├── onboarding/             # Entry point + full account-creation flow.
    │   ├── welcome_screen.dart        # First screen the app shows (app entry point).
    │   ├── create_account_screen.dart # Sign up/Log in tab + role choice (client/tasker).
    │   ├── basic_info_screen.dart     # Name/phone/password (after role is chosen).
    │   ├── onboarding_models.dart     # Shared enums + ClientProfileDraft/TaskerProfileDraft.
    │   ├── onboarding_state.dart      # Shared Riverpod draft providers for this flow.
    │   ├── client/                    # Client-specific remaining steps.
    │   └── tasker/                    # Tasker-specific remaining steps.
    ├── customer/               # Customer journey: home, list, profile, booking.
    ├── worker/                 # Worker journey: dashboard only (onboarding lives above).
    └── chatbot/                # Mock AI assistant.
```

**Guiding principle:** *Data and AI access is centralized into exactly two files*
(`demo_data.dart`, `ai_mock.dart`). Everything in `features/` is UI + routing +
local UI state. Everything visual reads from `core/theme/`. This separation is
what makes the UI redesignable and the data layer backend-swappable later.

### 2.2 Role of each core system

| System | File(s) | Responsibility |
|---|---|---|
| **Routing** | `core/routing/app_router.dart` | Declares all routes (grouped by feature), the fail-safe fallback, and the single global Android back-button handler. The only place navigation logic lives. |
| **Theme** | `core/theme/*` | Defines all colors, typography, spacing, and the `ThemeData` for light/dark. Screens never hardcode style values. Borders/radius are not a rigid per-component contract — cards prefer fill + shadow over `Border.all` (see `onboarding_selection_card.dart`, `skill_tile.dart`). |
| **Data** | `core/data/demo_data.dart` | All app data as compile-time `const` lists + the model classes. No I/O, no async. |
| **AI mock** | `core/utils/ai_mock.dart` | Synchronous, hardcoded "AI" responses derived from keyword matching over the demo data. No network, instant. |
| **Feature UI** | `features/*` | Screens that consume data + AI + theme and wire navigation. Hold their own *local* UI state via Riverpod. |
| **Mascot** | `core/widgets/mascot/*` | Pho Wa Yoke, the shared onboarding/AI guide. Screens select a `PhoWaYokeState`; they never reference PNG paths directly. |

---

## 3. File-by-file explanation

### Core files

#### `lib/main.dart`
- **Purpose:** App entry point.
- **Contains:** `main()` → `runApp(ProviderScope(child: TolyMolyApp()))`;
  `TolyMolyApp` builds `MaterialApp.router` with `AppTheme.light`,
  `AppTheme.dark`, `ThemeMode.system`, and `routerConfig: appRouter`.
- **Used by:** the Flutter runtime.
- **Must NOT:** contain business logic, build themes inline (use `AppTheme`),
  do any async setup, or reference data/AI directly.

#### `lib/core/routing/app_router.dart`
- **Purpose:** Single source of navigation truth + centralized back handling.
- **Contains:**
  - `Routes` — route-name constants grouped by feature (`onboarding`, `customer`, `worker`, `chatbot`).
  - `_onboardingRoutes`, `_customerRoutes`, `_workerRoutes`, `_chatbotRoutes` — route
    group lists.
  - `appRouter` — the `GoRouter`, with one `ShellRoute` wrapping all groups, an
    `errorBuilder` fallback to the onboarding `WelcomeScreen`, and
    `initialLocation = Routes.onboardingWelcome` (there is no splash screen).
  - `_findWorker(id)` — always returns a valid `Worker` (falls back).
  - `_RootBackHandler` — the global `PopScope` enforcing back-button rules.
  - `_confirmExit()` — the "Exit app?" dialog (re-entrancy guarded).
- **Used by:** `main.dart` (router config); every screen (via `Routes.*` and
  `context.push/go/pop`).
- **Must NOT:** let any route return null/blank; allow accidental app exit;
  hardcode path strings outside `Routes`; contain UI styling.

#### `lib/core/data/demo_data.dart`  ★ CORE FILE 1
- **Purpose:** The only data source in Phase 1.
- **Contains:** model classes `Worker`, `Category`, `Booking`, `ChatMessage`;
  `const` lists `workers` (16), `categories` (10), `skillBadges` (10),
  `bookings` (5); `categoryToSkills` map; fallbacks `fallbackWorker`,
  `fallbackWorkers`, `fallbackCategories`.
- **Used by:** every screen that shows data; `app_router.dart` (`_findWorker`);
  `ai_mock.dart` (to ground its responses).
- **Note:** `skillBadges` is currently unreferenced by any screen — it predates
  the `TaskerSkill` enum (`features/onboarding/onboarding_models.dart`) that
  `TaskerSkillsScreen` actually uses for the tasker skill picker today.
- **Must NOT:** read files, decode JSON, do async, or make network calls.
  Everything must stay `const`.

#### `lib/core/utils/ai_mock.dart`  ★ CORE FILE 2
- **Purpose:** The only "AI" in Phase 1 — a synchronous placeholder.
- **Contains:** `suggestService(query)`, `categorizeJob(text)`,
  `extractVoiceData(spoken)`, `extractNrcData(image)`, `chatbotReply(message)`;
  private helpers `_skillForQuery`, `_isGreeting`, `_firstNumber`.
- **Used by:** `chatbot_screen.dart` (`chatbotReply`) — this is currently the
  **only** function actually called. `suggestService`, `categorizeJob`,
  `extractVoiceData`, and `extractNrcData` are unused leftovers from an
  earlier worker-onboarding flow that has since been replaced by the
  multi-step `features/onboarding/` flow (which uses mocked widgets like
  `SpeechToTextButton` directly instead of calling into `ai_mock.dart`).
- **Must NOT:** be async, use API keys, make HTTP calls, or throw blocking
  errors. Every function returns instantly (<100 ms).

### Theme system

#### `lib/core/theme/app_colors.dart`
- **Purpose:** The only place raw color values (hex) live.
- **Contains:** brand colors (`teal*`, `orange*`), the canonical onboarding
  palette (`purple900`…`purple100`, `blue500`/`blue300`/`blue100`,
  `warning`, `error`), `onBrand`/`onBrandMuted` (text on gradients), light/dark
  neutrals, semantic colors (`star`, `success`, `danger`), shadow tokens
  (`shadow`, `cardShadow`, `selectedCardShadow`), and
  `tealGradient`/`orangeGradient`/`purpleGradient`.
- **Used by:** `app_theme.dart`, every widget/screen (via tokens or
  `Theme.of(context)`).
- **Must NOT:** contain layout/spacing or text-size values.

#### `lib/core/theme/app_text_styles.dart`
- **Purpose:** Typography tokens (sizes/weights only — **no color**).
- **Contains:** `AppTextStyles` ramp (`displayLarge` … `bodySmall`, `label`,
  `button`) and `themed(color)` which builds a Material `TextTheme`.
- **Used by:** `app_theme.dart` (to build `textTheme`); screens for on-gradient
  text via `.copyWith(color:)`.
- **Must NOT:** bake in colors (color comes from the theme or `onBrand`).

#### `lib/core/theme/app_spacing.dart`
- **Purpose:** The only place layout magic-numbers live.
- **Contains:** `AppSpacing` (xxs…huge, `screen`, `card`), `AppRadius`
  (sm…xl, `pill`), `AppSizes` (`buttonHeight`, `avatarSm`, `avatar`,
  `avatarLarge`, icon sizes).
- **Used by:** every widget/screen for padding, gaps, radius, fixed sizes.
- **Must NOT:** contain colors or text styles.

#### `lib/core/theme/app_theme.dart`
- **Purpose:** Assembles `ThemeData` for light and dark from the tokens.
- **Contains:** `AppTheme.light`, `AppTheme.dark`, `_build(brightness)` (sets
  scaffold/card/divider/hint colors, `colorScheme`, `textTheme`, app-bar/card/
  chip themes).
- **Used by:** `main.dart`.
- **Must NOT:** be referenced for one-off widget styling — screens read
  `Theme.of(context)` instead.

### Widgets

#### `lib/core/widgets/large_button.dart`
- **Purpose:** The standard primary button (haptic, gradient or outlined).
- **Contains:** `LargeButton(label, onTap, icon?, filled, gradient, outlineColor)`.
- **Used by:** onboarding (every step's continue button), customer (booking,
  worker profile), worker dashboard.
- **Must NOT:** know about navigation or data — caller passes `onTap`.

#### `lib/core/widgets/skill_tile.dart`
- **Purpose:** Square emoji + label tile for the customer home category grid.
- **Contains:** `SkillTile(emoji, label, sublabel?, selected, onTap)`. Borderless
  (fill + shadow communicate selection); wraps content in a `FittedBox` so it
  never overflows on small screens or large text scale.
- **Used by:** `features/customer/home_screen.dart` (categories grid) only.
- **Must NOT:** embed selection/business logic — caller controls `selected`.

#### `lib/core/widgets/demo_card.dart`
- **Purpose:** Worker list/row card + booking status badge.
- **Contains:** `WorkerCard(worker, onTap)` and `StatusBadge(status)` (with
  `StatusBadge.colorFor(status)` mapping status → color).
- **Used by:** customer home, worker list, worker dashboard.
- **Must NOT:** fetch data or navigate — it renders a passed `Worker`/status and
  delegates taps.

#### `lib/core/widgets/mascot/*`
- **Purpose:** Pho Wa Yoke (ဖိုးဝရုပ်), the shared visual guide used across
  onboarding, AI features, and empty states.
- **Contains:** `PhoWaYokeState` enum (`idle`, `happy`, `thinking`, `pointing`,
  `success`) + asset-path/semantic-label mapping (`mascot_state.dart`);
  `PhoWaYoke(state, size, fit, decorative, animationDuration)` — a continuously
  "breathing" animated image with a cross-fade/pop on state change
  (`pho_wa_yoke.dart`); `MascotMessageCard(state, message, mascotSize,
  mascotOnRight)` — mascot + a short guidance bubble (`mascot_message_card.dart`).
- **Used by:** `welcome_screen.dart` (large, centered, "greeting" pose),
  `onboarding_scaffold.dart` (every onboarding step's header), client/tasker
  welcome (completion) screens (`success` state).
- **Must NOT:** reference its own PNG paths from feature code — screens only
  ever pass a `PhoWaYokeState`.

#### `lib/core/widgets/onboarding/*`
Shared chrome and mock-input widgets reused by every step of the onboarding
flow, so behavior (and demo constants like the OTP code) lives in one place:
- **`onboarding_scaffold.dart`** — `OnboardingScaffold(mascotState, mascotMessage,
  body, bottomBar, progress?, title?, subtitle?, onBack?, readAloudText?)`. The
  shared shell: branded header, mascot + message, optional progress bar/title,
  a scrolling body, and a pinned bottom action bar. Every onboarding screen
  supplies only content — never its own chrome.
- **`onboarding_progress_header.dart`** — `OnboardingProgressHeader(progress)`:
  step label ("အဆင့် X / Y") + a linear progress bar from `OnboardingProgress`.
- **`onboarding_selection_card.dart`** — `OnboardingSelectionCard(emoji, label,
  sublabel?, selected, onTap, semanticLabel?)`: the selectable tile used for
  role/gender/skill/hear-about-us choices. Borderless (fill + shadow only) with
  a `FittedBox` overflow-safety net, mirroring `skill_tile.dart`.
- **`choice_wrap.dart`** — `ChoiceWrap<T>(values, selected, labelOf, emojiOf,
  onSelect, cardWidth)`: lays out `OnboardingSelectionCard`s in a `Wrap` for
  single-choice questions (experience level, hear-about-us).
- **`phone_otp_form.dart`** — `PhoneOtpForm(initialPhone, initiallyVerified,
  onPhoneChanged, onVerified)`: phone field + "Send OTP" + a 5-digit code field.
  The demo OTP is always `OnboardingStrings.demoOtp` (`"12345"`).
- **`profile_picture_picker.dart`** — `ProfilePicturePicker(pickedPath, onPicked)`:
  mock camera/gallery buttons that just store a `mock://profile-photo/...`
  reference string — no real camera/file-system access.
- **`read_aloud_button.dart`** — `ReadAloudButton(textToRead)`: mock
  text-to-speech; shows a snackbar instead of speaking (no TTS engine wired up).
- **`speech_to_text_button.dart`** — `SpeechToTextButton(semanticPrompt,
  onResult, mockTranscript, large)`: mock speech-to-text; immediately calls
  `onResult(mockTranscript)` instead of recording real audio.

### Constants

| File | Purpose | Must NOT |
|---|---|---|
| `core/constants/app_strings.dart` | Static UI copy (EN + Burmese) for the non-onboarding screens. | Hold styling or data. |
| `core/constants/onboarding_strings.dart` | All Burmese-first copy for the onboarding flow (Welcome through completion). | Hold styling or data. |
| `core/constants/demo_mode.dart` | `const DEMO_MODE = true` phase flag. | Be flipped to enable network in Phase 1. |

---

## 4. Feature module explanation

### `features/onboarding/`  — entry point + account creation
- **`welcome_screen.dart`** — **Entry point of the app** (`initialLocation`).
  Renders fully on the first frame: a large, centered, "greeting" Pho Wa Yoke
  (`happy` state), the app name, a welcome message, and a single "Get started"
  action that pushes the create-account screen. Also the global fallback for
  unknown/errored routes.
- **`create_account_screen.dart`** — Step 1 of signup. A Sign-up/Log-in tab
  toggle. The sign-up tab shows the role choice (Client vs Tasker, via
  `OnboardingSelectionCard`s) and writes the choice to `selectedRoleProvider`;
  continuing pushes `basic_info_screen.dart`. The log-in tab and the "Sign up
  with Google" button are presentational only — both show a "not supported in
  this demo" snackbar instead of navigating.
- **`basic_info_screen.dart`** — Step 2 of signup. Name/phone/password fields
  (only reachable once a role is chosen). Saves into `clientDraftProvider` or
  `taskerDraftProvider` depending on the chosen role, then pushes that role's
  first personal-info step.
- **`onboarding_models.dart`** — Shared enums (`UserRole`, `Gender`,
  `VerificationStatus`, `HearAboutSource`, `TaskerSkill`, `ExperienceLevel`)
  with Burmese `label`/`emoji` extensions; `OnboardingProgress(step, totalSteps)`;
  mutable-by-replacement `ClientProfileDraft` / `TaskerProfileDraft` (with
  `copyWith`) that accumulate answers across the whole flow.
- **`onboarding_state.dart`** — The Riverpod draft providers for this flow:
  `selectedRoleProvider`, `clientDraftProvider`, `taskerDraftProvider`. These
  are intentionally **shared across many routed screens** within the
  onboarding feature (an explicit, scoped exception to the "provider lives in
  the screen file" rule — see §7) because the flow spans many screens that all
  need to read/write the same in-progress draft.

#### `features/onboarding/client/` — client-only remaining steps
1. **`client_personal_info_screen.dart`** — Name, gender (`OnboardingSelectionCard`
   row), age. → `clientPhone`.
2. **`client_phone_verification_screen.dart`** — Wraps `PhoneOtpForm`. → `clientProfile`
   once verified (demo OTP `12345`).
3. **`client_basic_profile_screen.dart`** — `ProfilePicturePicker` (mock) +
   "How did you hear about us" `ChoiceWrap`. → `clientRules`.
4. **`client_rules_screen.dart`** — `RulesAgreementPanel` (read-aloud + required
   checkbox). → `clientWelcome`.
5. **`client_welcome_screen.dart`** — Completion screen (`success` mascot) with
   an unverified-items checklist (NRC, address, face). "Use it now" → `go`
   `customerHome` (stack reset); "Continue profile" is not implemented (snackbar).

#### `features/onboarding/tasker/` — tasker-only remaining steps
1. **`tasker_personal_info_screen.dart`** — Name (text field **and** a large
   standalone mic button), gender, age. → `taskerPhone`.
2. **`tasker_phone_verification_screen.dart`** — Same `PhoneOtpForm` as the
   client flow. → `taskerSkills`.
3. **`tasker_skills_screen.dart`** — 3-column grid of `TaskerSkill`
   `OnboardingSelectionCard`s (multi-select), an experience-level `ChoiceWrap`,
   and a free-text "other skill" field with a mic button. → `taskerProfile`.
4. **`tasker_basic_profile_screen.dart`** — Same shape as the client basic
   profile step. → `taskerRules`.
5. **`tasker_rules_screen.dart`** — Same `RulesAgreementPanel`. → `taskerWelcome`.
6. **`tasker_welcome_screen.dart`** — Completion screen; checklist adds a
   "introduction video" item. "Use it now" → `go` `dashboard` (stack reset).

### `features/customer/`
- **`home_screen.dart`** — Category grid (data-driven from `categories`,
  rendered with `SkillTile`) + nearby workers (sorted by distance from
  `workers`). Search bar and "switch role" action (→ `go` onboarding Welcome).
  Tapping a category pushes the worker list filtered by skill.
- **`worker_list_screen.dart`** — Browse/search workers. Skill filter chips
  (derived from data), sort dropdown (Nearest / Top rated / Lowest price), and
  an "Available now" toggle. Local state via Riverpod (`workerSortProvider`,
  `availableOnlyProvider`); the skill filter is seeded from the route's
  `?skill=` query param.
- **`worker_profile_screen.dart`** — Worker detail: rating, distance,
  experience, availability, bio, hourly rate, "Book Now". Receives a non-null
  `Worker` from the router (fallback-guaranteed).
- **`booking_screen.dart`** — Date/time chips, hours stepper, live price
  estimate (`hours × rate`), confirm → success dialog. Local state via Riverpod
  (`bookingHoursProvider`, `bookingDateProvider`, `bookingTimeProvider`).

### `features/worker/`
- **`dashboard_screen.dart`** — "Available for bookings" toggle
  (`availableToggleProvider`), today's earnings, mini-stats, and pending request
  cards (derived from `bookings`). Offline hint shown when toggle is off.
  "Switch role" action (→ `go` onboarding Welcome).

> There is no `features/worker/onboarding_screen.dart` anymore — tasker
> registration is the full `features/onboarding/tasker/` flow described above.

### `features/chatbot/`
- **`chatbot_screen.dart`** — Message list + input + quick-prompt chips.
  Messages are local state (`chatMessagesProvider`, seeded with a welcome
  message). Sending appends the user message **and** the synchronous
  `chatbotReply(text)` response at once — instant, no typing delay, no async.

---

## 5. Routing system documentation

### 5.1 Structure
All routes live inside **one `ShellRoute`** whose builder wraps every screen in
`_RootBackHandler`. This gives a single, centralized place to govern the Android
back button. Routes are split into feature group lists that compose into the
shell:

```
GoRouter(
  initialLocation: Routes.onboardingWelcome,
  errorBuilder: (_, __) => _RootBackHandler(child: WelcomeScreen()),
  routes: [
    ShellRoute(
      builder: (ctx, state, child) => _RootBackHandler(child: child),
      routes: [ ..._onboardingRoutes, ..._customerRoutes, ..._workerRoutes, ..._chatbotRoutes ],
    ),
  ],
)
```

There is **no splash route**. The onboarding `WelcomeScreen` is both the app's
entry point and its global fallback.

### 5.2 Route grouping strategy
Routes are namespaced by feature so each area can grow independently:
`/onboarding/*`, `/customer/*`, `/worker/*`, `/chatbot`. To add a screen you add
it to the matching group list — nothing else changes (see the checklist in
`TEAM_PLAN.md`).

### 5.3 Full route table (actual paths)

| Route (`Routes.*`) | Path | Screen | Purpose |
|---|---|---|---|
| `onboardingWelcome` | `/onboarding/welcome` | `WelcomeScreen` | **Entry point + global fallback** |
| `onboardingCreateAccount` | `/onboarding/create-account` | `CreateAccountScreen` | Sign up/Log in tab + role choice |
| `onboardingBasicInfo` | `/onboarding/basic-info` | `BasicInfoScreen` | Name/phone/password |
| `clientPersonal` | `/onboarding/client/personal` | `ClientPersonalInfoScreen` | Client name/gender/age |
| `clientPhone` | `/onboarding/client/phone` | `ClientPhoneVerificationScreen` | Client phone + mock OTP |
| `clientProfile` | `/onboarding/client/profile` | `ClientBasicProfileScreen` | Client photo + hear-about-us |
| `clientRules` | `/onboarding/client/rules` | `ClientRulesScreen` | Client rules agreement |
| `clientWelcome` | `/onboarding/client/welcome` | `ClientWelcomeScreen` | Client completion → Customer Home |
| `taskerPersonal` | `/onboarding/tasker/personal` | `TaskerPersonalInfoScreen` | Tasker name/gender/age |
| `taskerPhone` | `/onboarding/tasker/phone` | `TaskerPhoneVerificationScreen` | Tasker phone + mock OTP |
| `taskerSkills` | `/onboarding/tasker/skills` | `TaskerSkillsScreen` | Tasker skills + experience |
| `taskerProfile` | `/onboarding/tasker/profile` | `TaskerBasicProfileScreen` | Tasker photo + hear-about-us |
| `taskerRules` | `/onboarding/tasker/rules` | `TaskerRulesScreen` | Tasker rules agreement |
| `taskerWelcome` | `/onboarding/tasker/welcome` | `TaskerWelcomeScreen` | Tasker completion → Dashboard |
| `customerHome` | `/customer/home` | `CustomerHomeScreen` | Customer landing (categories + nearby) |
| `workerList` | `/customer/workers` | `WorkerListScreen` | Browse/search/filter workers (`?skill=` optional) |
| `workerProfile` | `/customer/worker/:id` | `WorkerProfileScreen` | Worker details |
| `booking` | `/customer/booking/:id` | `BookingScreen` | Booking flow |
| `dashboard` | `/worker/dashboard` | `WorkerDashboardScreen` | Worker availability + requests |
| `chatbot` | `/chatbot` | `ChatbotScreen` | Mock AI assistant |

> Note: paths are feature-namespaced (`/onboarding/*`, `/customer/*`, …).
> Screens always reference `Routes.*` constants, never raw strings.

### 5.4 Fallback route
`errorBuilder` renders the onboarding `WelcomeScreen` (wrapped in
`_RootBackHandler`) for any unknown/errored route. No route ever returns null
or a blank `Scaffold`.

### 5.5 Navigation stack rules (push vs go vs pop)

| Verb | When | Effect |
|---|---|---|
| `context.push(route)` | **All forward navigation** | Adds a page → back returns to the previous screen |
| system/AppBar back, `context.pop()` | Going back | Pops one page |
| `context.go(route)` | **Only intentional resets** | Replaces the stack |

The only sanctioned `go()` calls (verified): "Switch role" buttons (Home/
Dashboard) → onboarding Welcome; Client/Tasker completion "Use it now" →
Customer Home / Dashboard; Booking "Done" → Customer Home.

### 5.6 Back-button handling logic
`_RootBackHandler` wraps the whole app once via the ShellRoute builder. No screen
overrides back itself.

```dart
PopScope(
  canPop: false,                       // system back never auto-closes the app
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    final router = GoRouter.of(context);
    if (router.canPop()) { router.pop(); return; } // mid-stack: normal back
    _confirmExit(context);                          // stack root: "Exit app?" dialog
  },
)
```

| Screen type | Back behavior |
|---|---|
| Stack root (onboarding Welcome / any reset root) | "Exit TOLY MOLY?" dialog → Stay / Exit |
| Any other screen | Normal back navigation (pops) |

`_confirmExit` is guarded by `_exitDialogVisible` so rapid presses can't stack
dialogs; "Exit" calls `SystemNavigator.pop()`.

---

## 6. Data flow explanation

- **UI → data:** screens `import 'core/data/demo_data.dart'` and read the
  `const` lists directly (e.g., `workers`, `categories`, `bookings`). No
  service, repository, or provider sits in between.
- **No runtime loading:** all data is compile-time `const`, so it is available
  on the first frame with zero I/O, zero async, and zero failure modes. Every
  list also has a fallback constant the screen uses if it is ever empty.
- **AI mock simulation:** `ai_mock.dart`'s `chatbotReply` takes a string, runs
  simple keyword matching (`_skillForQuery`) against the demo data, and
  returns a plausible result synchronously. Example: `chatbotReply("fix my
  sink")` → detects "sink" → `Plumber` → recommends the nearest available
  plumber from `workers`.
- **Later replacement (Phase 2):** the UI keeps reading the same shapes
  (`Worker`, `Category`, …). Only the *source* changes — `demo_data.dart` is
  backed by an API/repository, and `ai_mock.dart` is backed by a real model —
  ideally behind the same names/signatures so screens don't change. See §9.

---

## 7. State management explanation

- **Library:** Riverpod (`flutter_riverpod`), wrapped once at the root via
  `ProviderScope` in `main.dart`.
- **Local-only rule:** every provider is a `StateProvider` (or `Provider`)
  **declared inside the screen file that uses it**. There are **no global/shared
  provider files** and no repository/notifier architecture, with one explicit,
  scoped exception:
- **The onboarding draft exception:** `features/onboarding/onboarding_state.dart`
  holds `selectedRoleProvider`, `clientDraftProvider`, and `taskerDraftProvider`.
  These are shared across the ~14 routed screens of the onboarding flow (it is
  one continuous, multi-step form), so the draft lives once at the feature
  level instead of being duplicated or threaded through route params on every
  screen. This is still *feature-local*, not a global/app-wide provider file.
- **Why local-only otherwise:** keeps state obvious and co-located — you can
  understand a screen by reading one file. It also prevents accidental
  cross-screen coupling.
- **Inventory of local providers (outside onboarding):**
  - `create_account_screen.dart`: `_isLoginTabProvider` (private, UI-only tab state)
  - `worker_list_screen.dart`: `workerSortProvider`, `availableOnlyProvider` (+ `WorkerSort` enum)
  - `booking_screen.dart`: `bookingHoursProvider`, `bookingDateProvider`, `bookingTimeProvider`
  - `dashboard_screen.dart`: `availableToggleProvider`
  - `chatbot_screen.dart`: `chatMessagesProvider`
- **Rules:** no `FutureProvider`, no `AsyncNotifier`, no `FutureBuilder`, no
  async `initState`. The UI never depends on provider state to render its first
  frame — providers only drive interactive updates.

---

## 8. Navigation lifecycle explanation

**App launch → entry**
1. App starts at `/onboarding/welcome`. `WelcomeScreen` renders instantly (no
   timer, no splash) with a large, centered, greeting Pho Wa Yoke.
2. "Get started" `push`es `CreateAccountScreen` → role choice → `push`
   `BasicInfoScreen` → branches into the chosen role's step sequence.

**Onboarding flow**
`Welcome` → `push` Create Account (role choice) → `push` Basic Info → `push`
[Client|Tasker] Personal Info → `push` Phone Verification → `push`
[Profile|Skills+Profile] → `push` Rules → `push` Welcome (completion) → `go`
Customer Home (client) or Dashboard (tasker) — a deliberate stack reset so the
user can't "back" into the onboarding flow once they've started using the app.

**Customer flow**
`Customer Home` → `push` Worker List (optionally `?skill=`) → `push`
Worker Profile → `push` Booking → confirm dialog → "Done" `go` Home (fresh
start) or "Message" `push` Chatbot. Back pops each pushed screen.

**Worker flow**
`Dashboard` is reached only via the tasker onboarding completion (`go`) or app
restart (`initialLocation` always re-enters onboarding — there is no persisted
session in Phase 1). "Switch role" `go`es back to onboarding Welcome.

**Chatbot flow**
`push` Chatbot from Home/List/Profile/Dashboard/Booking-dialog. Back pops to
wherever it was opened from.

**Back navigation behavior**

| On this screen | Back press does |
|---|---|
| Onboarding Welcome (root) | "Exit TOLY MOLY?" dialog |
| Reset roots (Home after booking, Dashboard, post-onboarding) | "Exit TOLY MOLY?" dialog |
| Any pushed screen (onboarding steps, list, profile, booking, chatbot) | Pops to previous screen |

**Why the app never crashes or exits unexpectedly:**
- `canPop: false` means the system can never auto-close the app; `_RootBackHandler` decides every time.
- Unknown routes fall back to the onboarding Welcome screen (no null/blank screens).
- All data is `const` with fallbacks, so no screen can fail to render.
- No async in UI flow, so there are no pending-future or error states to get stuck in.

---

## 9. Future extension plan

### Phase 2 — Backend + real AI integration
- Replace the **source** behind `demo_data.dart` with an API/repository layer
  that returns the **same model shapes** (`Worker`, `Category`, `Booking`).
- Replace `ai_mock.dart` internals with a real AI service (e.g., Claude/Gemini)
  behind the **same function names/signatures**.
- **No UI changes required** if shapes/signatures are preserved. (If async
  becomes necessary, introduce it only at this seam; screens can adopt loading
  states locally without touching the theme or routing.)

### Phase 3 — Feature expansion
- Add new screens inside the correct `features/*` folder.
- Register new routes in `app_router.dart` only (correct group list).
- The theme system and existing screens remain unchanged.
- Add local `StateProvider`s inside the new screen file only (or, for a new
  onboarding-style multi-step flow, inside that flow's own `*_state.dart`).

### Phase 4 — Production scaling
- Add a real authentication backend (the current sign-up/log-in tab is
  presentational only; log-in and Google sign-up are not implemented).
- Add a database for persistence (bookings, profiles, history, onboarding
  drafts across app restarts).
- Add real-time updates (worker availability, live booking status, chat).
- Introduce architecture layers (repository/service/domain) **only at Phase 4**,
  behind the data/AI seam — the feature UI and theme stay stable.

---

### Quick reference: invariants that must always hold
1. Data + AI access stays in exactly two files in Phase 1.
2. No screen hardcodes colors, text styles, or spacing — all from `core/theme/`.
3. All navigation goes through GoRouter; `push` forward, `pop`/system back,
   `go` only for sanctioned resets.
4. No screen overrides the back button; the global handler owns it.
5. No async in UI/data/business logic in Phase 1 (framework async only).
6. Every screen returns a valid `Scaffold`; unknown routes → onboarding Welcome.
7. There is no splash screen — the app must render valid content on the very
   first frame of `WelcomeScreen`.
