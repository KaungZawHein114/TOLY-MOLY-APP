# TOLY MOLY — Technical Documentation

> **Read time: ~10–15 minutes.** This is the single source of truth for the
> architecture. Read it before touching the codebase.

---

## 1. Project overview

**TOLY MOLY** is an on-demand service marketplace for Myanmar (Yangon-first,
Burmese-friendly). It connects **customers** who need a task done (plumbing,
cleaning, electrical, AC repair, tutoring, delivery, …) with local **workers**
who accept bookings.

> Core philosophy: *"Hire for the task, pay for the work, done in a day."*

### Current phase — Phase 1: Flutter-only offline MVP

The app is a **fully clickable, 100% offline demo** built for presentation.
Stability and smooth navigation are the priority.

**What IS included:**
- A complete Flutter UI (Android + iOS), 9 screens.
- Hardcoded demo data (compile-time Dart constants).
- A synchronous **mock** AI layer (keyword matching, no network).
- GoRouter navigation with a centralized, fail-safe back-button system.
- A design-system theme layer (light + dark).

**What is NOT included (by design, in Phase 1):**
- ❌ No backend (no Django/Node/REST/Firebase).
- ❌ No database (no SQLite/PostgreSQL/persistence).
- ❌ No real AI (no OpenAI/Gemini, no API keys).
- ❌ No network calls of any kind (no HTTP/WebSocket).
- ❌ No runtime file/JSON loading.
- ❌ No `async`/`await` in app logic, data, or UI flow (framework async only).

These are intentionally deferred to later phases (see §9).

---

## 2. Full architecture explanation

### 2.1 Folder structure (every folder, and why it exists)

```
lib/
├── main.dart                  # App entry point. Wires theme + router. Nothing else.
│
├── core/                      # Cross-cutting infrastructure shared by all features.
│   ├── constants/
│   │   ├── app_strings.dart   # Static UI text (English + Burmese). NOT styling.
│   │   └── demo_mode.dart     # const DEMO_MODE = true (phase switch).
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
│   │   ├── app_colors.dart    # Color tokens + gradients.
│   │   ├── app_text_styles.dart # Typography tokens (sizes/weights, no color).
│   │   ├── app_spacing.dart   # Spacing / radius / size tokens.
│   │   └── app_theme.dart     # Builds ThemeData (light + dark) from the tokens.
│   │
│   └── widgets/               # Reusable, theme-driven UI building blocks.
│       ├── large_button.dart  # Primary button.
│       ├── skill_tile.dart    # Category / skill grid tile.
│       └── demo_card.dart     # WorkerCard + StatusBadge.
│
└── features/                  # One folder per product area. UI + local state only.
    ├── auth/                  # Entry: splash + role selection.
    ├── customer/              # Customer journey: home, list, profile, booking.
    ├── worker/                # Worker journey: onboarding, dashboard.
    └── chatbot/               # Mock AI assistant.
```

**Guiding principle:** *Data and AI access is centralized into exactly two files*
(`demo_data.dart`, `ai_mock.dart`). Everything in `features/` is UI + routing +
local UI state. Everything visual reads from `core/theme/`. This separation is
what makes the UI redesignable and the data layer backend-swappable later.

### 2.2 Role of each core system

| System | File(s) | Responsibility |
|---|---|---|
| **Routing** | `core/routing/app_router.dart` | Declares all routes (grouped by feature), the fail-safe fallback, and the single global Android back-button handler. The only place navigation logic lives. |
| **Theme** | `core/theme/*` | Defines all colors, typography, spacing, radius, and the `ThemeData` for light/dark. Screens never hardcode style values. |
| **Data** | `core/data/demo_data.dart` | All app data as compile-time `const` lists + the model classes. No I/O, no async. |
| **AI mock** | `core/utils/ai_mock.dart` | Synchronous, hardcoded "AI" responses derived from keyword matching over the demo data. No network, instant. |
| **Feature UI** | `features/*` | Screens that consume data + AI + theme and wire navigation. Hold their own *local* UI state via Riverpod. |

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
  - `Routes` — route-name constants grouped by feature.
  - `_authRoutes`, `_customerRoutes`, `_workerRoutes`, `_chatbotRoutes` — route
    group lists.
  - `appRouter` — the `GoRouter`, with one `ShellRoute` wrapping all groups, an
    `errorBuilder` fallback to Role Selection, and `initialLocation` = splash.
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
- **Must NOT:** read files, decode JSON, do async, or make network calls.
  Everything must stay `const`.

#### `lib/core/utils/ai_mock.dart`  ★ CORE FILE 2
- **Purpose:** The only "AI" in Phase 1 — a synchronous placeholder.
- **Contains:** `suggestService(query)`, `categorizeJob(text)`,
  `extractVoiceData(spoken)`, `extractNrcData(image)`, `chatbotReply(message)`;
  private helpers `_skillForQuery`, `_isGreeting`, `_firstNumber`.
- **Used by:** `chatbot_screen.dart` (`chatbotReply`), `onboarding_screen.dart`
  (`extractVoiceData`).
- **Must NOT:** be async, use API keys, make HTTP calls, or throw blocking
  errors. Every function returns instantly (<100 ms).

### Theme system

#### `lib/core/theme/app_colors.dart`
- **Purpose:** The only place raw color values (hex) live.
- **Contains:** brand colors (`teal*`, `orange*`), `onBrand`/`onBrandMuted`
  (text on gradients), light/dark neutrals, semantic colors (`star`, `success`,
  `danger`), `shadow`, and `tealGradient`/`orangeGradient`.
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
  (sm…xl, `pill`), `AppSizes` (button/avatar/icon sizes).
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
- **Contains:** `LargeButton(label, onTap, icon?, filled, gradient)`.
- **Used by:** role selection, profile, booking, onboarding, booking dialog.
- **Must NOT:** know about navigation or data — caller passes `onTap`.

#### `lib/core/widgets/skill_tile.dart`
- **Purpose:** Square emoji + label tile for category grids and skill badges.
- **Contains:** `SkillTile(emoji, label, sublabel?, selected, onTap)`. Wraps
  content in a `FittedBox` so it never overflows on small screens.
- **Used by:** customer home (categories), worker onboarding (skill badges).
- **Must NOT:** embed selection/business logic — caller controls `selected`.

#### `lib/core/widgets/demo_card.dart`
- **Purpose:** Worker list/row card + booking status badge.
- **Contains:** `WorkerCard(worker, onTap)` and `StatusBadge(status)` (with
  `StatusBadge.colorFor(status)` mapping status → color).
- **Used by:** customer home, worker list, worker dashboard.
- **Must NOT:** fetch data or navigate — it renders a passed `Worker` and
  delegates taps.

### Constants

| File | Purpose | Must NOT |
|---|---|---|
| `core/constants/app_strings.dart` | Static UI copy (EN + Burmese). | Hold styling or data. |
| `core/constants/demo_mode.dart` | `const DEMO_MODE = true` phase flag. | Be flipped to enable network in Phase 1. |

---

## 4. Feature module explanation

### `features/auth/`
- **`splash_screen.dart`** — Branded splash. Renders fully on the first frame;
  a plain `Timer` (not `Future.delayed`, not async) auto-navigates to Role
  Selection after 1.5 s. Tap-to-skip is supported. **Entry point of the app.**
- **`role_selection_screen.dart`** — Two giant tiles (🧑 Customer / 🛠️ Worker).
  This is the **navigation entry decision** *and* the universal fallback screen
  for unknown routes, so it must always render valid content. Customer →
  `push(/customer/home)`; Worker → `push(/worker/onboarding)`.

### `features/customer/`
- **`home_screen.dart`** — Category grid (data-driven from `categories`) +
  nearby workers (sorted by distance from `workers`). Search bar and "switch
  role" action. Tapping a category pushes the worker list filtered by skill.
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
- **`onboarding_screen.dart`** — 3 steps in one screen (step is local state,
  `onboardStepProvider`): **(1)** Name + age (mic button calls
  `extractVoiceData` to auto-fill; age slider) **(2)** pick 1–3 skill badges
  **(3)** slide-to-accept agreement → `go(/worker/dashboard)`.
- **`dashboard_screen.dart`** — "Available for bookings" toggle
  (`availableToggleProvider`), today's earnings, mini-stats, and pending request
  cards (derived from `bookings`). Offline hint shown when toggle is off.

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
  initialLocation: '/auth/splash',
  errorBuilder: (_, __) => _RootBackHandler(child: RoleSelectionScreen()),
  routes: [
    ShellRoute(
      builder: (ctx, state, child) => _RootBackHandler(child: child),
      routes: [ ..._authRoutes, ..._customerRoutes, ..._workerRoutes, ..._chatbotRoutes ],
    ),
  ],
)
```

### 5.2 Route grouping strategy
Routes are namespaced by feature so each area can grow independently:
`/auth/*`, `/customer/*`, `/worker/*`, `/chatbot`. To add a screen you add it to
the matching group list — nothing else changes (see the checklist in
`TEAM_PLAN.md`).

### 5.3 Full route table (actual paths)

| Route (`Routes.*`) | Path | Screen | Purpose |
|---|---|---|---|
| `splash` | `/auth/splash` | `SplashScreen` | Entry; auto-advances to role in 1.5 s |
| `role` | `/auth/role` | `RoleSelectionScreen` | Entry decision **+ global fallback** |
| `customerHome` | `/customer/home` | `CustomerHomeScreen` | Customer landing (categories + nearby) |
| `workerList` | `/customer/workers` | `WorkerListScreen` | Browse/search/filter workers (`?skill=` optional) |
| `workerProfile` | `/customer/worker/:id` | `WorkerProfileScreen` | Worker details |
| `booking` | `/customer/booking/:id` | `BookingScreen` | Booking flow |
| `onboarding` | `/worker/onboarding` | `WorkerOnboardingScreen` | Worker registration (3 steps) |
| `dashboard` | `/worker/dashboard` | `WorkerDashboardScreen` | Worker availability + requests |
| `chatbot` | `/chatbot` | `ChatbotScreen` | Mock AI assistant |

> Note: paths are feature-namespaced (`/auth/splash`, `/customer/workers`, …).
> Screens always reference `Routes.*` constants, never raw strings.

### 5.4 Fallback route
`errorBuilder` renders `RoleSelectionScreen` (wrapped in `_RootBackHandler`) for
any unknown/errored route. No route ever returns null or a blank `Scaffold`.

### 5.5 Splash auto-navigation
`SplashScreen` schedules a plain `Timer(1500ms)` in `initState` that calls
`context.go(Routes.role)`. This is **not** `Future.delayed` and not async — the
screen is fully drawn on the first frame; the timer only triggers navigation.

### 5.6 Navigation stack rules (push vs go vs pop)

| Verb | When | Effect |
|---|---|---|
| `context.push(route)` | **All forward navigation** | Adds a page → back returns to the previous screen |
| system/AppBar back, `context.pop()` | Going back | Pops one page |
| `context.go(route)` | **Only intentional resets** | Replaces the stack |

The only sanctioned `go()` calls (verified): Splash→Role; "Switch role" buttons
(Home/Dashboard)→Role; Onboarding-complete→Dashboard; Booking "Done"→Home.

### 5.7 Back-button handling logic
`_RootBackHandler` wraps the whole app once via the ShellRoute builder. No screen
overrides back itself.

```dart
PopScope(
  canPop: false,                       // system back never auto-closes the app
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    final router = GoRouter.of(context);
    final loc = router.routeInformationProvider.value.uri.path;
    if (loc == Routes.splash) return;              // Splash: swallow back
    if (router.canPop()) { router.pop(); return; } // mid-stack: normal back
    _confirmExit(context);                         // stack root: "Exit app?" dialog
  },
)
```

| Screen type | Back behavior |
|---|---|
| Splash | Ignored (swallowed) |
| Stack root (Role Selection / reset roots) | "Exit TOLY MOLY?" dialog → Stay / Exit |
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
- **AI mock simulation:** `ai_mock.dart` functions take a string, run simple
  keyword matching (`_skillForQuery`) against the demo data, and return a
  plausible result synchronously. Example: `chatbotReply("fix my sink")` →
  detects "sink" → `Plumber` → recommends the nearest available plumber from
  `workers`.
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
  provider files** and no repository/notifier architecture.
- **Why:** keeps state obvious and co-located — you can understand a screen by
  reading one file. It also prevents accidental cross-screen coupling.
- **Inventory of local providers:**
  - `worker_list_screen.dart`: `workerSortProvider`, `availableOnlyProvider` (+ `WorkerSort` enum)
  - `booking_screen.dart`: `bookingHoursProvider`, `bookingDateProvider`, `bookingTimeProvider`
  - `onboarding_screen.dart`: `onboardStepProvider`, `onboardAgeProvider`, `onboardSkillsProvider`
  - `dashboard_screen.dart`: `availableToggleProvider`
  - `chatbot_screen.dart`: `chatMessagesProvider`
- **Rules:** no `FutureProvider`, no `AsyncNotifier`, no `FutureBuilder`, no
  async `initState`. The UI never depends on provider state to render its first
  frame — providers only drive interactive updates.

---

## 8. Navigation lifecycle explanation

**App launch → entry**
1. App starts at `/auth/splash`. Splash renders instantly.
2. After 1.5 s (or tap), `go(/auth/role)` — Role Selection becomes the stack base.

**Customer flow**
`Role` → `push` Home → `push` Worker List (optionally `?skill=`) → `push`
Worker Profile → `push` Booking → confirm dialog → "Done" `go` Home (fresh
start) or "Message" `push` Chatbot. Back pops each pushed screen.

**Worker flow**
`Role` → `push` Onboarding (steps are in-screen state) → slide-to-accept `go`
Dashboard. "Switch role" `go` Role.

**Chatbot flow**
`push` Chatbot from Home/List/Profile/Dashboard/Booking-dialog. Back pops to
wherever it was opened from.

**Back navigation behavior**

| On this screen | Back press does |
|---|---|
| Splash | Nothing (swallowed) |
| Role Selection (root) | "Exit TOLY MOLY?" dialog |
| Reset roots (Home after booking, Dashboard) | "Exit TOLY MOLY?" dialog |
| Any pushed screen (list, profile, booking, chatbot, onboarding) | Pops to previous screen |

**Why the app never crashes or exits unexpectedly:**
- `canPop: false` means the system can never auto-close the app; `_RootBackHandler` decides every time.
- Unknown routes fall back to Role Selection (no null/blank screens).
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
- Add local `StateProvider`s inside the new screen file only.

### Phase 4 — Production scaling
- Add an authentication backend (replace the demo role selection with real auth).
- Add a database for persistence (bookings, profiles, history).
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
6. Every screen returns a valid `Scaffold`; unknown routes → Role Selection.
