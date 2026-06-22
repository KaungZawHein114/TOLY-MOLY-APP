# Client Home Screen Redesign (Slice 1) — Design Spec

> Source: user-provided "TOLY MOLY — Client Home Screen Specification,
> Version: MVP 1.1". That spec bundles six pieces of work; this design
> covers only the first slice (see §1). Branch: `main` (continuing directly
> on main per current workflow — no feature branch requested this round).

## 1. Scope decomposition

The full spec describes:
1. **Bottom navigation shell** (Home/Activity/Profile) — doesn't exist yet.
2. **The Home screen itself** — app bar, quick actions, browse-services grid.
3. **Tasker Explore Page** — search/filter/compare worker browsing, richer
   than the existing `WorkerListScreen` (trust tiers, rating filter, etc).
4. **Schedule Worker Modal** — direct booking request to a specific worker.
5. **Task Posting Flow** — full multi-step task-creation wizard.
6. **Global AI Assistant** — floating, app-shell-level assistant.

**This slice covers #1 and #2 only.** #3–#6 are explicitly deferred to
future slices, each to get its own spec/plan/implementation cycle. Where
the Home screen needs to navigate toward one of the deferred features, it
either reuses an existing equivalent screen or lands on a placeholder —
see §3.

## 2. Goals / Non-goals

**Goals**
- Replace `CustomerHomeScreen`'s current shape (AppBar + search bar +
  category grid + nearby-workers list) with the spec's shape (custom app
  bar with greeting/logo/notification bell, two quick-action buttons,
  "browse services" category grid with per-card listen buttons).
- Introduce a 3-tab bottom navigation shell (Home/Activity/Profile) as the
  new entry point for the customer flow.
- Keep visual/motion language consistent with the onboarding redesign
  already shipped (`AppMotion`, `StaggeredEntrance`, `LargeButton` press
  feedback, borderless soft-shadow cards, `ReadAloudButton` mock TTS).
- Stay within this app's existing Phase 1 invariants (no backend, no
  async, theme-tokens-only styling, local-only Riverpod state).

**Non-goals**
- No Tasker Explore Page redesign — `WorkerListScreen` is reused as-is.
- No Schedule Worker Modal.
- No Task Posting Flow — a placeholder screen reserves the destination.
- No Global AI Assistant (floating/shell-level) — not added this slice.
- No changes to `demo_data.dart`'s `categories` list — reuse the existing
  10 categories as-is; only the *card widget* rendering them changes.
- No changes to `Routes.workerList`/`workerProfile`/`booking`, the
  `ShellRoute`, or `_RootBackHandler`.

## 3. Resolved scope decisions

| Spec item | Decision |
|---|---|
| "အလုပ်တင်မည်" (Post a task) button | New `PostTaskPlaceholderScreen` (`Routes.postTask`) — reserved stub, replaced when the Task Posting Flow slice lands. |
| "အလုပ်သမားရှာမည်" (Find a worker) button | Navigates to existing `WorkerListScreen`, unfiltered. |
| Category card tap | Navigates to existing `WorkerListScreen` with `?skill=` (same pattern `home_screen.dart` already uses today). |
| Activity / Profile tabs | Simple placeholder screens (mascot + "coming soon" message). |
| 🔔 Notification bell | Tappable; shows a snackbar ("no notifications yet"), matching the existing not-yet-wired-feature pattern (e.g. Google sign-up). |
| Greeting name | Hardcoded demo name (no persisted client session exists in Phase 1), per the spec's own example ("မအေးအေး"). |
| Search bar / Nearby Workers list | Dropped — not in the spec's screen structure for this redesign. |
| Global AI Assistant | Deferred entirely; no FAB added this slice. |
| Categories data | Keep `demo_data.dart`'s existing 10 categories unchanged; only the card widget rendering them is new. |

## 4. File structure

```
lib/features/customer/
├── customer_home_shell.dart           (new)
├── home_screen.dart                   (rewritten)
├── activity_placeholder_screen.dart   (new)
├── profile_placeholder_screen.dart    (new)
├── post_task_placeholder_screen.dart  (new)
├── worker_list_screen.dart            (unchanged)
├── worker_profile_screen.dart         (unchanged)
└── booking_screen.dart                (unchanged)

lib/core/widgets/
└── service_category_card.dart         (new)
```

`SkillTile` is left in place and unmodified; nothing else references it
after this change, but removing it is out of scope (no instruction to
delete working, independent code).

## 5. Routing changes (`lib/core/routing/app_router.dart`)

- `Routes.customerHome`'s `GoRoute` builder changes from
  `CustomerHomeScreen()` to `CustomerHomeShell()`.
- New constant: `static const String postTask = '/customer/post-task';`
- New `GoRoute` in `_customerRoutes`: `path: Routes.postTask, builder: (_, __) => const PostTaskPlaceholderScreen()`.
- No new routes for Activity/Profile — they are tab switches inside
  `CustomerHomeShell`'s local state, not GoRouter destinations.
- `ShellRoute`, `_RootBackHandler`, `errorBuilder`, `initialLocation`: all
  unchanged.

## 6. `CustomerHomeShell`

```dart
final _customerTabIndexProvider = StateProvider<int>((ref) => 0);

class CustomerHomeShell extends ConsumerWidget {
  const CustomerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_customerTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          CustomerHomeScreen(),
          ActivityPlaceholderScreen(),
          ProfilePlaceholderScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.purple700,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.lightSurface,
        onTap: (i) => ref.read(_customerTabIndexProvider.notifier).state = i,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "ပင်မ"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "လုပ်ဆောင်ချက်များ"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "ပရိုဖိုင်"),
        ],
      ),
    );
  }
}
```

`IndexedStack` (not a freshly-built widget per tap) so each tab keeps its
scroll position/local state when switching back. Local `StateProvider`
declared in this file only, per the existing local-state convention.

**Known trade-off:** pressing system/hardware back while on the Activity
or Profile tab triggers the global "Exit app?" dialog (same as today's
behavior at any stack root), rather than first returning to the Home tab.
Accepted for this slice since those two tabs are placeholders with no
content to lose; revisit if it's confusing once they have real content.

## 7. Home screen content (`home_screen.dart` rewrite)

- **App bar** (custom, not Flutter's `AppBar`, to fit this exact layout):
  - Left: two-line greeting — "မင်္ဂလာပါ 👋" then the hardcoded demo name.
  - Center: small logo badge — same `assets/logo_circle.png` + white
    circular backdrop treatment as the onboarding header, for visual
    consistency between flows.
  - Right: 🔔 `IconButton` → snackbar "notifications not available yet".
- **Quick actions**: two stacked `LargeButton`s, full-width, directly
  below the app bar (no scrolling needed to see them):
  - "အလုပ်တင်မည်" → `context.push(Routes.postTask)`
  - "အလုပ်သမားရှာမည်" → `context.push(Routes.workerList)`
- **Section title**: "ဝန်ဆောင်မှုများ ရှာဖွေမည်" — `theme.textTheme.titleLarge`,
  matching the existing section-heading convention.
- **Category grid**: `categories` from `demo_data.dart` (with
  `fallbackCategories` if empty, per existing convention), rendered via
  the new `ServiceCategoryCard`. Tapping the card body pushes
  `WorkerListScreen` with `?skill=` from `categoryToSkills` (identical
  logic to today's `home_screen.dart`); tapping the card's listen button
  triggers `ReadAloudButton`'s existing mock-speak behavior reading the
  category's Burmese name.
- **Motion**: the quick-actions block, section title, and grid are wrapped
  in the existing `StaggeredEntrance` widget so this screen cascades in
  the same way onboarding screens already do.
- No search bar, no "Nearby Workers" section (see §3).

## 8. `ServiceCategoryCard` (`core/widgets/service_category_card.dart`)

```dart
class ServiceCategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;       // navigates to WorkerListScreen
  const ServiceCategoryCard({super.key, required this.emoji, required this.label, required this.onTap});
  ...
}
```

Square card: emoji/icon centered top, name below, a small `ReadAloudButton`
in a corner (reuses the existing widget verbatim — no new TTS-mock logic).
Borderless fill + soft shadow (`AppColors.shadowMd`/`cardShadow` tier,
matching `SkillTile`/`OnboardingSelectionCard`'s established look), wrapped
in `FittedBox(fit: BoxFit.scaleDown)` as the same overflow-safety net those
two widgets already use, so it's a visual sibling, not a one-off.

## 9. Placeholder screens

`ActivityPlaceholderScreen`, `ProfilePlaceholderScreen`,
`PostTaskPlaceholderScreen`: each a `Scaffold` with a centered
`PhoWaYoke(state: PhoWaYokeState.idle)` and a short Burmese "coming soon"
message, styled from existing theme tokens only. No new visual language
invented for placeholders — they should look like an intentional, calm
"not yet" state, not a broken screen.

## 10. Testing & verification

- New widget test for `CustomerHomeShell`: tapping each
  `BottomNavigationBarItem` swaps the visible `IndexedStack` child;
  previously-active tabs remain mounted (not rebuilt) when switching back.
- New/extended widget test confirming the Home screen's two quick-action
  buttons navigate to `Routes.postTask` and `Routes.workerList`
  respectively, and that a category card tap navigates to `Routes.workerList`
  with the expected `?skill=` query value.
- Extend the existing overflow-probe pattern (narrow width × 1.6× text
  scale, as already applied to `OnboardingScaffold`) to the new app bar
  layout and `ServiceCategoryCard` grid.
- `flutter analyze` clean (no new issues beyond the 2 pre-existing,
  unrelated `activeColor` deprecation infos already present).
- Full `flutter test` passing.

## 11. Future slices (not built now, listed for continuity)

- Tasker Explore Page (search/filters/trust-tier labels, replacing/wrapping
  `WorkerListScreen`).
- Schedule Worker Modal (direct task request to a specific worker).
- Task Posting Flow (the multi-step wizard) — replaces
  `PostTaskPlaceholderScreen`.
- Global AI Assistant (floating, app-shell-level) — replaces the deferred
  FAB entirely; until then, the assistant remains reachable only via the
  existing push-navigated `ChatbotScreen` from wherever it's already linked.
- Real Activity/Profile screen content — replaces the two placeholders.
- Real notification content — replaces the snackbar stub.
