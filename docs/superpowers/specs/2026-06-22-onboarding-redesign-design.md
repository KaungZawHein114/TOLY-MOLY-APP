# Onboarding UI/UX Redesign — Design Spec

> Branch: `shun` (isolated from `main`). Goal: make the existing onboarding
> flow feel alive and polished instead of static/demo-like, without changing
> its information architecture, routes, or brand palette.

## 1. Problem

The onboarding flow (`features/onboarding/**`, 14 routes from `WelcomeScreen`
through the client/tasker completion screens) is functionally complete but
visually and motion-wise flat:

- **No motion** — screens cut instantly; only `PhoWaYoke` animates (idle
  breathing + state cross-fade). Buttons/cards have no feedback beyond the
  default `InkWell` ripple.
- **Flat, generic visuals** — `OnboardingSelectionCard`/`SkillTile` use a
  single flat fill + one shadow value; nothing reads as "designed."
- **Rigid layout & pacing** — every step uses the identical
  `OnboardingScaffold` shape (header → mascot strip → progress → form →
  button) regardless of whether the step is a celebratory moment or a form,
  so steps feel interchangeable.
- **Lifeless copy** — mascot messages are functional but uniformly
  instructional; nothing varies in tone for celebratory vs. reassuring vs.
  encouraging moments.

## 2. Goals / Non-goals

**Goals**
- Add motion (entrances, transitions, press feedback) using only vanilla
  Flutter animation APIs (no new pubspec dependency).
- Add visual depth ("soft modern depth": layered shadows, soft gradient
  fills) strictly derived from the existing canonical palette in CLAUDE.md —
  no new hues.
- Differentiate "moment" screens (Welcome, completion) from "form" screens
  structurally, via a mode on the existing shared scaffold — not bespoke
  per-screen layouts.
- Draft warmer Burmese micro-copy for key moments, as a clearly-flagged
  best-effort pass pending native-speaker review.
- Preserve every existing invariant from `CLAUDE.md`/`docs/ARCHITECTURE.md`:
  no async gating the first frame, theme tokens are the only place styling
  lives, 48px minimum touch targets, accessibility (reduce-motion) respected.

**Non-goals**
- No change to routes, step order, step count, or the shared draft providers
  (`onboarding_state.dart`). Same 14 screens, same navigation.
- No new mascot artwork/states — the 5 existing PNGs are used as-is, just
  choreographed better.
- No new pubspec dependencies.
- No final/shippable Burmese copy — the copy in this pass is a draft for
  human review, not a finished translation.
- No changes outside `features/onboarding/**`, the onboarding-specific shared
  widgets in `core/widgets/onboarding/**` and `core/widgets/mascot/**`, and
  the theme token files. Customer/worker/chatbot screens are untouched.

## 3. Theme token additions

All additions are *new tokens only* — nothing existing is removed or
renamed, so nothing outside `features/onboarding/**` is affected.

### `lib/core/theme/app_colors.dart`
- `cardFillGradient` — soft `purple100` → `purple300`-tinted gradient for
  selected/elevated card surfaces (replacing a flat `purple100` fill).
- `guidanceSurfaceGradient` — soft `blue100` → `blue300` gradient for
  guidance/message surfaces (mascot message bubble background).
- Shadow tiers, replacing the single `cardShadow`/`selectedCardShadow` pair
  with a small scale: `shadowSm`, `shadowMd`, `shadowLg` (increasing
  blur/opacity), plus `selectedShadowMd` (brand-tinted, for selected cards).
  `cardShadow`/`selectedCardShadow` stay as-is (deprecated via doc comment,
  not deleted) so nothing outside onboarding breaks.

### `lib/core/theme/app_spacing.dart`
- New `AppMotion` token class: `fast` (150ms), `medium` (250ms), `slow`
  (400ms) durations; `enter` (`Curves.easeOutCubic`) and `press`
  (`Curves.easeOut`) curves. Every new animation in this redesign references
  these instead of inline `Duration`/`Curves` literals.

## 4. Shared widget enhancements

All changes are **additive/backward-compatible** — existing call sites
outside onboarding (e.g. `SkillTile` on Customer Home) keep working
unchanged unless explicitly noted.

- **`core/widgets/onboarding/onboarding_scaffold.dart`** — new
  `OnboardingLayoutMode { form, moment }` parameter (default `form`, so
  nothing breaks if omitted). `moment` mode: larger centered mascot, no/minimal
  progress chrome. `form` mode: today's shape, restyled with the new shadow
  tiers/gradients.
- **`core/widgets/onboarding/staggered_entrance.dart`** *(new file)* — a small
  widget that fades+slides a list of children in with a per-child stagger
  delay, built on `AnimationController` + `Interval`. Honors
  `MediaQuery.of(context).disableAnimations` (instant, no animation, when
  true). `OnboardingScaffold`'s body wraps its direct children in this
  automatically.
- **`core/widgets/onboarding/onboarding_selection_card.dart`** — press
  feedback via `AnimatedScale` (subtle scale-down on tap-down using
  `AppMotion.fast`/`press`); selected-state fill switches to
  `AppColors.cardFillGradient`; shadow uses the new tier tokens. No change to
  its public API (`emoji`, `label`, `sublabel`, `selected`, `onTap`,
  `semanticLabel`) — every call site keeps working.
- **`core/widgets/large_button.dart`** — same press-scale treatment (gated by
  `disableAnimations`); add an optional `celebratory` flag (default `false`)
  that triggers a one-shot checkmark "pop" on first mount, used only by the
  two completion screens' "Use it now" buttons.
- **`core/widgets/mascot/pho_wa_yoke.dart`** — add a one-time entrance
  animation (slide-up + scale 0.8→1.0) on first mount, in addition to the
  existing continuous idle-breathing and cross-fade-on-state-change. Gated by
  `disableAnimations`.
- **`core/widgets/mascot/mascot_message_card.dart`** — message bubble enters
  ~80ms after the mascot (via the stagger wrapper) instead of simultaneously.

## 5. Screen transitions

- `lib/core/routing/app_router.dart`: add a `_onboardingTransitionPage`
  helper (`CustomTransitionPage` wrapping `GoRoute.pageBuilder`) used by every
  route in `_onboardingRoutes` for `push` navigation — combined fade + subtle
  slide-up (`AppMotion.medium`/`enter`), replacing the platform-default
  horizontal slide for this flow only. Other route groups
  (`_customerRoutes`/`_workerRoutes`/`_chatbotRoutes`) are untouched.
- The two `go()` resets (`clientWelcome`→`customerHome`,
  `taskerWelcome`→`dashboard`) use a plain fade — a reset should feel calm,
  not energetic.
- This is entirely route-config-only; no onboarding screen file needs to
  change for this.

## 6. Per-step treatment

Same 14 routes; mapping the new toolkit onto each by *purpose*:

| Step(s) | Layout mode | Key motion/visual additions |
|---|---|---|
| `WelcomeScreen` | `moment` | Mascot entrance animation; "Get started" button gets a slow, gentle pulsing outline (only action on screen) |
| `CreateAccountScreen` (tab + role choice) | `form` | Animated sliding-pill tab indicator (replacing instant color swap); role cards get press/lift; picking a role replays the mascot's reactive "nod" (re-trigger entrance animation) instead of a flat cross-fade |
| `BasicInfoScreen`, `*PersonalInfoScreen` | `form` | Fields stagger in top-to-bottom via `StaggeredEntrance`; validation errors fade/shake in instead of snapping into place |
| `*PhoneVerificationScreen` (`PhoneOtpForm`) | `form` | OTP-verified success container scale-pops in; mascot briefly flashes to `success` state before settling, instead of a silent state flip |
| `TaskerSkillsScreen`, `*BasicProfileScreen` (`ChoiceWrap`/grid) | `form` | Selection cards get press/lift bounce paired with the existing haptic feedback (visible motion now matches the haptic, which today fires with no visual cue) |
| `*RulesScreen` (`RulesAgreementPanel`) | `form` | Checkbox-agree fill/border transition is animated, not instant; read-aloud button pulses while its mock "reading aloud" snackbar is showing |
| `ClientWelcomeScreen`, `TaskerWelcomeScreen` | `moment` | Biggest moment in the flow: full mascot entrance + a 2–3 cycle celebratory bounce loop; checklist rows stagger in one-by-one; "Use it now" button uses the new `celebratory` pop |

## 7. Copy/content warmth pass

Add new, additive Burmese strings to `lib/core/constants/onboarding_strings.dart`
for the highest-impact moments (welcome headline/message, completion title,
and the mascot message per step-type category), each immediately preceded by
a `// TODO(native-speaker-review): drafted copy, needs Burmese review` comment
referencing this spec section. **Existing strings are not deleted** — screens
switch to the new strings as part of implementation, so a revert is a
one-line change back to the old constant if review rejects a draft.

Tone targets per moment category (exact Burmese wording to be drafted during
implementation, not finalized here):
- **Welcome**: personal/inviting rather than a generic tagline restatement.
- **Form steps**: encouraging, never clinical ("we just need a couple of
  things from you" tone vs. "ဖြည့်ပေးပါ" instruction-only tone).
- **OTP/Rules**: reassuring (trust-building, since these are the two steps
  most likely to make a low-digital-literacy user anxious).
- **Completion**: specific and celebratory, not the current generic
  "ကြိုဆိုပါသည် 🎉".

## 8. Testing, accessibility & risk guardrails

- `flutter analyze` stays clean; `test/widget_test.dart` and
  `test/onboarding_scaffold_overflow_test.dart` keep passing as-is (the
  overflow-safety work already in place — `FittedBox` on selection
  cards/tiles — must still hold once shadows/gradients/motion are layered on).
- Add new widget-test coverage re-running the existing overflow probe pattern
  (narrow width × 1.6x text scale) against at least one `moment`-mode and one
  `form`-mode onboarding screen post-redesign, since layout modes are new.
- Every new animation is gated by
  `MediaQuery.of(context).disableAnimations` — when the OS "reduce motion"
  setting is on, entrances/press-scale/pulses collapse to instant/no-op.
- All animations start from `initState`/interaction callbacks — never from
  `FutureBuilder`/async — first frame remains synchronous (Phase 1 invariant).
- Press-scale transforms are purely visual; hit-test targets stay at their
  current size (no shrinking below the 48px CLAUDE.md minimum).
- Manual walkthrough of the full flow for both roles (client and tasker) on
  the Android emulator before considering the work done.

## 9. Files touched (expected)

```
lib/core/theme/app_colors.dart                          (additive tokens)
lib/core/theme/app_spacing.dart                          (new AppMotion class)
lib/core/widgets/onboarding/onboarding_scaffold.dart      (layout mode param)
lib/core/widgets/onboarding/onboarding_selection_card.dart (press/gradient/shadow)
lib/core/widgets/onboarding/staggered_entrance.dart       (new file)
lib/core/widgets/large_button.dart                        (press scale + celebratory flag)
lib/core/widgets/mascot/pho_wa_yoke.dart                  (entrance animation)
lib/core/widgets/mascot/mascot_message_card.dart          (stagger timing)
lib/core/routing/app_router.dart                          (onboarding transition pages)
lib/core/constants/onboarding_strings.dart                (additive draft copy)
lib/features/onboarding/**                                (adopt layout modes / new strings; no route/provider changes)
test/onboarding_scaffold_overflow_test.dart               (extend coverage)
```

`core/widgets/skill_tile.dart` (Customer Home) may optionally pick up the new
shadow tiers for visual consistency, but this is not required by this spec
and customer-flow files are otherwise out of scope.

## 10. Open items for native-speaker review (tracked, not blocking the design)

The drafted Burmese copy in §7 must be reviewed by a Burmese speaker before
this work is considered mergeable toward `main`. This is explicitly a
follow-up gate, not part of this spec's approval.
