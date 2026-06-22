# TOLY MOLY — Team Collaboration Plan & Roadmap

> Companion to [`ARCHITECTURE.md`](./ARCHITECTURE.md). This file covers who owns
> what, the sprint timeline, feature status, and the rules for extending the
> project safely.

---

## A. Team structure (4 developers)

| Dev | Role |
|---|---|
| **D1** | Design System Owner |
| **D2** | Customer Flow Owner |
| **D3** | Worker + Chatbot Owner |
| **D4** | Routing + Architecture + Onboarding Owner |

---

## B. Task breakdown table

### D1 — Design System Owner
- **Responsibilities:** Own the visual language; keep all styling tokenized so
  the UI can be redesigned without touching screens. Maintain reusable widgets,
  including the shared Pho Wa Yoke mascot system and the onboarding chrome
  widgets (they are presentation, not feature logic).
- **Files owned:** `core/theme/app_colors.dart`, `app_text_styles.dart`,
  `app_spacing.dart`, `app_theme.dart`; `core/widgets/large_button.dart`,
  `skill_tile.dart`, `demo_card.dart`; `core/widgets/mascot/*`;
  `core/widgets/onboarding/*` (shared chrome/mock-input widgets only — not the
  routed onboarding screens themselves).
- **Implements:** color/typography/spacing tokens, light/dark theme, shared
  widgets, the mascot system, future re-skins.
- **Depends on:** nothing (foundational). Others depend on D1.
- **Must NOT touch:** `demo_data.dart`, `ai_mock.dart`, `app_router.dart`,
  feature screen logic/navigation, `onboarding_state.dart`/`onboarding_models.dart`.

### D2 — Customer Flow Owner
- **Responsibilities:** Build and maintain the customer journey screens (layout
  + data binding + local UI state only).
- **Files owned:** `features/customer/home_screen.dart`,
  `worker_list_screen.dart`, `worker_profile_screen.dart`, `booking_screen.dart`.
- **Implements:** home (categories + nearby), browse/search/filter/sort,
  profile, booking + price estimate + confirmation.
- **Depends on:** D1 (theme/widgets), D4 (routes + `Worker` model via router),
  `demo_data.dart` (read-only).
- **Must NOT touch:** `core/theme/*`, `demo_data.dart`/`ai_mock.dart` internals,
  the back-button handler. No custom navigators.

### D3 — Worker + Chatbot Owner
- **Responsibilities:** Build the worker dashboard and the mock assistant.
  (Tasker *registration* now lives in the onboarding flow — see D4 — not here.)
- **Files owned:** `features/worker/dashboard_screen.dart`;
  `features/chatbot/chatbot_screen.dart`.
- **Implements:** dashboard (availability, earnings, requests), chatbot
  (instant mock replies via `ai_mock.dart`'s `chatbotReply`).
- **Depends on:** D1 (theme/widgets), D4 (routes), `demo_data.dart` + `ai_mock.dart`
  (read-only / call-only).
- **Must NOT touch:** `core/theme/*`, data/AI internals, routing internals.

### D4 — Routing + Architecture + Onboarding Owner
- **Responsibilities:** Own navigation, the data/AI seam, overall structure,
  and the multi-step onboarding flow (account creation through role-specific
  completion). **Navigation system hardening:** maintain the global
  `_RootBackHandler`, enforce push/pop/go rules, keep route-stack integrity,
  ensure new screens add without modifying existing ones.
- **Files owned:** `core/routing/app_router.dart`, `core/data/demo_data.dart`,
  `core/utils/ai_mock.dart`, `core/constants/*`, `main.dart`;
  `features/onboarding/*` (welcome, create-account, basic-info, the
  `client/`/`tasker/` step screens, `onboarding_models.dart`,
  `onboarding_state.dart`).
- **Implements:** route groups, fallback route, back-button policy, demo data,
  AI mocks, the full onboarding flow and its shared draft providers; later the
  backend/AI integration seam.
- **Depends on:** D1 (theme + shared onboarding/mascot widgets).
- **Must NOT touch:** `core/theme/*` styling decisions (that's D1); feature
  screen UI internals outside onboarding (that's D2/D3).

---

## C. Sprint plan

| Sprint | Goal | Key tasks | Owners |
|---|---|---|---|
| **Sprint 1 — Foundation** | Project boots, navigates, themed | Flutter setup; GoRouter + groups + fallback + back handler; theme system (colors/text/spacing/theme); finalize `demo_data.dart` + `ai_mock.dart` | D4 (routing/data/ai), D1 (theme) |
| **Sprint 2 — Customer flow** | Full customer journey clickable | Home, worker list (filter/sort/availability), profile, booking + confirmation | D2 (lead), D1 (widgets/theme support) |
| **Sprint 3 — Worker + Chatbot** | Worker dashboard + assistant complete | Dashboard, chatbot | D3 (lead), D1 (support) |
| **Sprint 4 — Onboarding rebuild** | Replace the old splash + single-screen role pick with a full Burmese-first onboarding flow | Welcome (entry point) → create-account/role choice → basic info → per-role personal info/phone-OTP/skills-or-profile/rules/completion; shared mascot system; remove the old splash screen entirely | D4 (lead), D1 (mascot + shared onboarding widgets) |
| **Sprint 5 — Integration + polish** | Demo-ready | End-to-end flow wiring, transitions/haptics, light+dark pass, overflow/responsiveness, app icon + name + asset cleanup, demo speed/UX optimization, run-through of the full demo script | All (D4 coordinates) |

> Current status: **Sprints 1–4 are implemented; the app is in Sprint 5
> (polish/optimization).** See the matrix below.

---

## D. Feature ownership matrix

| Feature | Owner | Files | Status |
|---|---|---|---|
| Onboarding Welcome (entry point + fallback) | D4 | `features/onboarding/welcome_screen.dart` | ✅ done |
| Create Account (tab + role choice) | D4 | `features/onboarding/create_account_screen.dart` | ✅ done |
| Basic Info (name/phone/password) | D4 | `features/onboarding/basic_info_screen.dart` | ✅ done |
| Client onboarding steps (personal/phone/profile/rules/welcome) | D4 | `features/onboarding/client/*` | ✅ done |
| Tasker onboarding steps (personal/phone/skills/profile/rules/welcome) | D4 | `features/onboarding/tasker/*` | ✅ done |
| Shared onboarding chrome + mock inputs (scaffold, selection card, OTP, mic, TTS, photo picker) | D1 | `core/widgets/onboarding/*` | ✅ done |
| Mascot system (Pho Wa Yoke) | D1 | `core/widgets/mascot/*` | ✅ done |
| Customer Home | D2 | `features/customer/home_screen.dart` | ✅ done |
| Worker List / Search | D2 | `features/customer/worker_list_screen.dart` | ✅ done |
| Worker Profile | D2 | `features/customer/worker_profile_screen.dart` | ✅ done |
| Booking Flow | D2 | `features/customer/booking_screen.dart` | ✅ done |
| Worker Dashboard | D3 | `features/worker/dashboard_screen.dart` | ✅ done |
| Chatbot (mock AI) | D3 | `features/chatbot/chatbot_screen.dart` | ✅ done |
| Theme system | D1 | `core/theme/*` | ✅ done |
| Shared widgets (button/tile/card) | D1 | `core/widgets/large_button.dart`, `skill_tile.dart`, `demo_card.dart` | ✅ done |
| Routing + back handling | D4 | `core/routing/app_router.dart` | ✅ done |
| Demo data | D4 | `core/data/demo_data.dart` | ✅ done |
| AI mock | D4 | `core/utils/ai_mock.dart` | ✅ done (only `chatbotReply` is currently called; the rest predates the onboarding rebuild — see ARCHITECTURE.md §3) |
| App icon + name | D1/D4 | `pubspec.yaml` (`flutter_launcher_icons`), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | ✅ done |
| Real login / Google sign-up | D4 | `features/onboarding/create_account_screen.dart` | ⏳ planned (Phase 4 — needs a real auth backend) |
| Booking history (optional) | D2 | `features/customer/` (new) | ⏳ planned |

---

## E. Rules for future developers (strict)

1. **No backend inside UI.** No HTTP/DB/Firebase/SQLite in Phase 1. Data comes
   only from `demo_data.dart`; AI only from `ai_mock.dart`.
2. **No new architecture layers** in Phase 1–3 (no service/repository/domain,
   no global provider files). Local `StateProvider` inside the screen only —
   except the onboarding flow's shared draft providers in
   `features/onboarding/onboarding_state.dart`, which are feature-scoped, not
   global (see ARCHITECTURE.md §7).
3. **Never break the routing system.** All navigation via GoRouter; `push`
   forward, `pop`/system back, `go` only for sanctioned resets. Never add a
   per-screen back override or a custom `Navigator` stack.
4. **Always use the theme system.** No hardcoded colors, text styles, or spacing
   in screens — use `core/theme/` tokens and `Theme.of(context)`. Prefer
   fill + shadow over `Border.all` for selectable cards (see ARCHITECTURE.md §2.2).
5. **Phase 1 = `demo_data` + `ai_mock` only.** Don't introduce async, network,
   or persistence until Phase 2, and only behind the data/AI seam.
6. **No splash screen.** The app must render valid, useful content on the very
   first frame of `WelcomeScreen` — don't reintroduce a timer-gated splash.

---

## Future scaling guide (summary)

| Phase | What changes | What stays the same |
|---|---|---|
| **2 — Backend + AI** | `demo_data.dart` source → API/repository; `ai_mock.dart` → real model (same shapes/signatures); real login/Google sign-up | UI screens, theme, routing |
| **3 — Feature expansion** | New screens in `features/*`; new routes in `app_router.dart` | Theme, existing screens, data seam |
| **4 — Production** | Auth backend, database (incl. persisting onboarding drafts across restarts), real-time updates; introduce repository/service layers behind the seam | Feature UI structure, theme, navigation model |

> Golden rule: changes flow **inward** (data/AI seam → backend) or **additively**
> (new feature folders + routes). The theme and navigation core stay stable.

---

## "How to add a new feature safely" checklist

> Touch **only** the new screen file and `app_router.dart`. Do not edit
> `core/theme`, `core/data`, or `core/utils`.

- [ ] **Create the screen** in the correct `features/<area>/` folder. Return a
      `Scaffold` (or `OnboardingScaffold` if it's part of the onboarding flow).
      Read data from `demo_data.dart`; style only via `Theme.of(context)` +
      theme tokens.
- [ ] **Add a route name** to the matching group in `Routes` (`app_router.dart`),
      e.g. `static const String bookingHistory = '/customer/booking-history';`.
- [ ] **Register the route** in the correct group list (`_onboardingRoutes`,
      `_customerRoutes`, `_workerRoutes`, …) with a `GoRoute(path:..., builder:...)`.
      It is wrapped by the global back handler automatically.
- [ ] **Navigate to it** from an existing screen using
      `context.push(Routes.bookingHistory)` (so back works). Use `go()` only for
      a deliberate stack reset.
- [ ] **(Optional) local state:** declare `StateProvider`s **inside that screen
      file only**. No global/shared provider files (the onboarding draft
      providers are the one documented exception — see §E.2).
- [ ] **Verify:** `flutter analyze` is clean; the unknown-route fallback still
      lands on the onboarding Welcome screen; back button behaves per the table
      in `ARCHITECTURE.md`. No existing screen was modified.
- [ ] **Phase check:** no async, no network, no persistence (Phase 1). If the
      feature needs data, it must come from `demo_data.dart`.
