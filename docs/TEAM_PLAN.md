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
| **D4** | Routing + Architecture Owner |

---

## B. Task breakdown table

### D1 — Design System Owner
- **Responsibilities:** Own the visual language; keep all styling tokenized so
  the UI can be redesigned without touching screens. Maintain reusable widgets.
- **Files owned:** `core/theme/app_colors.dart`, `app_text_styles.dart`,
  `app_spacing.dart`, `app_theme.dart`; `core/widgets/large_button.dart`,
  `skill_tile.dart`, `demo_card.dart`.
- **Implements:** color/typography/spacing tokens, light/dark theme, shared
  widgets, future re-skins.
- **Depends on:** nothing (foundational). Others depend on D1.
- **Must NOT touch:** `demo_data.dart`, `ai_mock.dart`, `app_router.dart`,
  feature screen logic/navigation.

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
- **Responsibilities:** Build the worker journey and the mock assistant.
- **Files owned:** `features/worker/onboarding_screen.dart`,
  `dashboard_screen.dart`; `features/chatbot/chatbot_screen.dart`.
- **Implements:** 3-step onboarding (voice autofill, skill picker,
  slide-to-accept), dashboard (availability, earnings, requests), chatbot
  (instant mock replies).
- **Depends on:** D1 (theme/widgets), D4 (routes), `demo_data.dart` + `ai_mock.dart`
  (read-only / call-only).
- **Must NOT touch:** `core/theme/*`, data/AI internals, routing internals.

### D4 — Routing + Architecture Owner
- **Responsibilities:** Own navigation, the data/AI seam, and overall structure.
  **Navigation system hardening:** maintain the global `_RootBackHandler`,
  enforce push/pop/go rules, keep route-stack integrity, ensure new screens add
  without modifying existing ones.
- **Files owned:** `core/routing/app_router.dart`, `core/data/demo_data.dart`,
  `core/utils/ai_mock.dart`, `core/constants/*`, `main.dart`.
- **Implements:** route groups, fallback route, back-button policy, demo data,
  AI mocks; later the backend/AI integration seam.
- **Depends on:** feature screens existing (for route registration).
- **Must NOT touch:** `core/theme/*` styling decisions (that's D1); feature
  screen UI internals (that's D2/D3).

---

## C. Sprint plan

| Sprint | Goal | Key tasks | Owners |
|---|---|---|---|
| **Sprint 1 — Foundation** | Project boots, navigates, themed | Flutter setup; GoRouter + groups + fallback + back handler; theme system (colors/text/spacing/theme); finalize `demo_data.dart` + `ai_mock.dart` | D4 (routing/data/ai), D1 (theme) |
| **Sprint 2 — Customer flow** | Full customer journey clickable | Home, worker list (filter/sort/availability), profile, booking + confirmation | D2 (lead), D1 (widgets/theme support) |
| **Sprint 3 — Worker + Chatbot** | Worker journey + assistant complete | Onboarding (3 steps + voice mock + slide-to-accept), dashboard, chatbot | D3 (lead), D1 (support) |
| **Sprint 4 — Integration + polish** | Demo-ready | End-to-end flow wiring, transitions/haptics, light+dark pass, overflow/responsiveness, demo speed/UX optimization, run-through of the 15-step demo script | All (D4 coordinates) |

> Current status: **Sprints 1–3 are implemented; the app is in late Sprint 4
> (polish/optimization).** See the matrix below.

---

## D. Feature ownership matrix

| Feature | Owner | Files | Status |
|---|---|---|---|
| Splash | D4 | `features/auth/splash_screen.dart` | ✅ done |
| Role Selection (+ fallback) | D4 | `features/auth/role_selection_screen.dart` | ✅ done |
| Customer Home | D2 | `features/customer/home_screen.dart` | ✅ done |
| Worker List / Search | D2 | `features/customer/worker_list_screen.dart` | ✅ done |
| Worker Profile | D2 | `features/customer/worker_profile_screen.dart` | ✅ done |
| Booking Flow | D2 | `features/customer/booking_screen.dart` | ✅ done |
| Worker Onboarding | D3 | `features/worker/onboarding_screen.dart` | ✅ done |
| Worker Dashboard | D3 | `features/worker/dashboard_screen.dart` | ✅ done |
| Chatbot (mock AI) | D3 | `features/chatbot/chatbot_screen.dart` | ✅ done |
| Theme system | D1 | `core/theme/*` | ✅ done |
| Shared widgets | D1 | `core/widgets/*` | ✅ done |
| Routing + back handling | D4 | `core/routing/app_router.dart` | ✅ done |
| Demo data | D4 | `core/data/demo_data.dart` | ✅ done |
| AI mock | D4 | `core/utils/ai_mock.dart` | ✅ done |
| Booking history (optional) | D2 | `features/customer/` (new) | ⏳ planned |

---

## E. Rules for future developers (strict)

1. **No backend inside UI.** No HTTP/DB/Firebase/SQLite in Phase 1. Data comes
   only from `demo_data.dart`; AI only from `ai_mock.dart`.
2. **No new architecture layers** in Phase 1–3 (no service/repository/domain,
   no global provider files). Local `StateProvider` inside the screen only.
3. **Never break the routing system.** All navigation via GoRouter; `push`
   forward, `pop`/system back, `go` only for sanctioned resets. Never add a
   per-screen back override or a custom `Navigator` stack.
4. **Always use the theme system.** No hardcoded colors, text styles, or spacing
   in screens — use `core/theme/` tokens and `Theme.of(context)`.
5. **Phase 1 = `demo_data` + `ai_mock` only.** Don't introduce async, network,
   or persistence until Phase 2, and only behind the data/AI seam.

---

## Future scaling guide (summary)

| Phase | What changes | What stays the same |
|---|---|---|
| **2 — Backend + AI** | `demo_data.dart` source → API/repository; `ai_mock.dart` → real model (same shapes/signatures) | UI screens, theme, routing |
| **3 — Feature expansion** | New screens in `features/*`; new routes in `app_router.dart` | Theme, existing screens, data seam |
| **4 — Production** | Auth backend, database, real-time updates; introduce repository/service layers behind the seam | Feature UI structure, theme, navigation model |

> Golden rule: changes flow **inward** (data/AI seam → backend) or **additively**
> (new feature folders + routes). The theme and navigation core stay stable.

---

## "How to add a new feature safely" checklist

> Touch **only** the new screen file and `app_router.dart`. Do not edit
> `core/theme`, `core/data`, or `core/utils`.

- [ ] **Create the screen** in the correct `features/<area>/` folder. Return a
      `Scaffold`. Read data from `demo_data.dart`; style only via
      `Theme.of(context)` + theme tokens.
- [ ] **Add a route name** to the matching group in `Routes` (`app_router.dart`),
      e.g. `static const String bookingHistory = '/customer/booking-history';`.
- [ ] **Register the route** in the correct group list (`_customerRoutes`,
      `_workerRoutes`, …) with a `GoRoute(path:..., builder:...)`. It is wrapped
      by the global back handler automatically.
- [ ] **Navigate to it** from an existing screen using
      `context.push(Routes.bookingHistory)` (so back works). Use `go()` only for
      a deliberate stack reset.
- [ ] **(Optional) local state:** declare `StateProvider`s **inside that screen
      file only**. No global/shared provider files.
- [ ] **Verify:** `flutter analyze` is clean; the unknown-route fallback still
      lands on Role Selection; back button behaves per the table in
      `ARCHITECTURE.md`. No existing screen was modified.
- [ ] **Phase check:** no async, no network, no persistence (Phase 1). If the
      feature needs data, it must come from `demo_data.dart`.
