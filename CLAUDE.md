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
lib/
├── main.dart              # entry point only: ProviderScope -> MaterialApp.router
├── core/
│   ├── constants/         # app_strings.dart (EN+Burmese copy), demo_mode.dart (phase flag)
│   ├── data/demo_data.dart    # ★ the ONLY data source — const models/lists, with fallbacks
│   ├── utils/ai_mock.dart     # ★ the ONLY "AI" source — synchronous keyword-matching mocks
│   ├── routing/app_router.dart # GoRouter config + the single global back-button handler
│   ├── theme/              # color/text/spacing tokens + ThemeData (light/dark)
│   └── widgets/             # theme-driven shared widgets (button, tile, card)
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
- `app_colors.dart` (raw hex values only), `app_text_styles.dart` (sizes/weights, no color), `app_spacing.dart` (spacing/radius/sizes), `app_theme.dart` (assembles light/dark `ThemeData` from the above).
- Screens must never hardcode colors, text styles, or spacing — use `Theme.of(context)` and the token classes.

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
