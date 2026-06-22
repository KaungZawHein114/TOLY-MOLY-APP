# Onboarding Redesign — Slice 1 (Welcome, Create Account, Basic Info) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the motion/visual/copy pieces of
`docs/superpowers/specs/2026-06-22-onboarding-redesign-design.md` needed for
exactly 3 screens — `WelcomeScreen`, `CreateAccountScreen`, `BasicInfoScreen`
— as a preview slice the user can react to before the rest of the flow.

**Architecture:** Add new theme tokens (motion durations/curves, gradients,
shadow tiers) and a new `StaggeredEntrance` widget; extend existing shared
widgets (`OnboardingScaffold`, `OnboardingSelectionCard`, `LargeButton`,
`PhoWaYoke`, `MascotMessageCard`) with additive, backward-compatible
parameters; add an onboarding-only custom transition in the router; adopt all
of the above in the 3 target screens; add draft (flagged) warmer Burmese copy
for those 3 screens only.

**Tech Stack:** Flutter (vanilla animation APIs only — `AnimationController`,
`AnimatedScale`, `AnimatedContainer`, `CustomTransitionPage`). No new pubspec
dependencies. Riverpod/GoRouter usage unchanged.

## Global Constraints
- No new pubspec dependencies (spec §"Goals").
- No changes to routes, step order/count, or `onboarding_state.dart`/`onboarding_models.dart` (spec "Non-goals").
- Do not touch `client/*`, `tasker/*` onboarding screens, or customer/worker/chatbot screens in this slice.
- Every new animation must check `MediaQuery.of(context).disableAnimations` and collapse to instant/no-op when true (spec §8).
- No animation may gate the first frame on async work; all animations start in `initState`/interaction callbacks (spec §8, Phase 1 invariant).
- Press-feedback transforms must not shrink hit-test targets below 48px (spec §8).
- `flutter analyze` must stay clean; `test/widget_test.dart` and `test/onboarding_scaffold_overflow_test.dart` must keep passing.
- Existing `OnboardingStrings` constants are never deleted — new copy is additive with a `// TODO(native-speaker-review):` comment (spec §7).

---

### Task 1: `AppMotion` tokens

**Files:**
- Modify: `lib/core/theme/app_spacing.dart`
- Test: manual (`flutter analyze`) — this is a pure-constants file, no behavior to unit test yet.

**Interfaces:**
- Produces: `AppMotion.fast` (`Duration`, 150ms), `AppMotion.medium` (250ms), `AppMotion.slow` (400ms), `AppMotion.enter` (`Curve`, `Curves.easeOutCubic`), `AppMotion.press` (`Curve`, `Curves.easeOut`). Later tasks import these instead of inline `Duration`/`Curves` literals.

- [ ] **Step 1: Add the `AppMotion` class**

Append to the end of `lib/core/theme/app_spacing.dart`:

```dart

/// Motion tokens — the ONLY place animation durations/curves live, so every
/// onboarding animation speaks the same timing language instead of ad-hoc
/// literals scattered through widget files.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
}
```

Add the missing import at the top of the file (it currently has no imports):

```dart
import 'package:flutter/animation.dart';
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no new errors/warnings introduced by this file.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_spacing.dart
git commit -m "feat(onboarding): add AppMotion animation duration/curve tokens"
```

---

### Task 2: Gradient + shadow-tier color tokens

**Files:**
- Modify: `lib/core/theme/app_colors.dart`

**Interfaces:**
- Consumes: nothing new (uses existing `purple100`, `purple300`, `blue100`, `blue300`, `brandPurple`).
- Produces: `AppColors.cardFillGradient` (`LinearGradient`), `AppColors.guidanceSurfaceGradient` (`LinearGradient`), `AppColors.shadowSm`/`shadowMd`/`shadowLg` (`Color`), `AppColors.selectedShadowMd` (`Color`). Later tasks (3, 4) consume these.

- [ ] **Step 1: Add the new tokens**

In `lib/core/theme/app_colors.dart`, immediately after the existing
`selectedCardShadow` line (inside the shadow comment block), add:

```dart
  // Soft depth tiers — replaces flat single-shadow cards with a small
  // elevation scale. cardShadow/selectedCardShadow above are kept for any
  // existing call sites; new onboarding widgets use these tiers instead.
  static Color shadowSm = const Color(0xFF000000).withValues(alpha: 0.04);
  static Color shadowMd = const Color(0xFF000000).withValues(alpha: 0.08);
  static Color shadowLg = const Color(0xFF000000).withValues(alpha: 0.14);
  static Color selectedShadowMd = brandPurple.withValues(alpha: 0.22);
```

Immediately after the existing `purpleGradient` definition, add the two new
gradients:

```dart
  // Soft card-fill gradients (selected/elevated surfaces) — derived strictly
  // from the existing purple/blue scale, not new hues.
  static const LinearGradient cardFillGradient = LinearGradient(
    colors: [purple100, purple300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient guidanceSurfaceGradient = LinearGradient(
    colors: [blue100, blue300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no new errors/warnings.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(onboarding): add soft-depth gradient and shadow-tier tokens"
```

---

### Task 3: `StaggeredEntrance` widget

**Files:**
- Create: `lib/core/widgets/onboarding/staggered_entrance.dart`
- Test: `test/staggered_entrance_test.dart`

**Interfaces:**
- Consumes: `AppMotion.medium`, `AppMotion.enter` (Task 1).
- Produces: `StaggeredEntrance({Key? key, required List<Widget> children, Duration staggerDelay = const Duration(milliseconds: 60)})` — a `StatefulWidget` whose `build` returns a `Column` of the given children, each wrapped in a fade+slide-up transition. Task 6 (`OnboardingScaffold`) wraps its body's direct children in this.

- [ ] **Step 1: Write the failing test**

Create `test/staggered_entrance_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/widgets/onboarding/staggered_entrance.dart';

void main() {
  testWidgets('StaggeredEntrance renders all children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StaggeredEntrance(
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
  });

  testWidgets('StaggeredEntrance skips animation when disableAnimations is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StaggeredEntrance(children: [Text('instant')]),
        ),
      ),
    );
    // No pump-forward needed — content should be visible on the very first
    // frame when animations are disabled, with no Opacity/Transform wrapper
    // (the child is returned directly, not animated).
    await tester.pump();
    expect(find.text('instant'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('instant'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/staggered_entrance_test.dart`
Expected: FAIL — `Error: Target of URI doesn't exist: 'package:toly_moly/core/widgets/onboarding/staggered_entrance.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/core/widgets/onboarding/staggered_entrance.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Fades + slides a list of children in with a per-child stagger delay.
/// Used by [OnboardingScaffold] so every onboarding screen gets entrance
/// motion for free. Honors the OS "reduce motion" accessibility setting —
/// when [MediaQuery.disableAnimations] is true, children appear instantly.
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // MediaQuery.of(context) is not safe to call before the first build
    // completes — read the platform's accessibility flag directly instead.
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : AppMotion.medium,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final count = widget.children.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (i) {
        if (reduceMotion) {
          return widget.children[i];
        }
        // Each child's own slice of the shared controller's timeline,
        // offset by its stagger position, clamped to [0, 1].
        final start = (i * widget.staggerDelay.inMilliseconds) /
            AppMotion.medium.inMilliseconds;
        final clampedStart = start.clamp(0.0, 0.9);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(clampedStart, 1.0, curve: AppMotion.enter),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, (1 - animation.value) * 16),
                child: child,
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/staggered_entrance_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/onboarding/staggered_entrance.dart test/staggered_entrance_test.dart
git commit -m "feat(onboarding): add StaggeredEntrance widget with reduce-motion support"
```

---

### Task 4: `PhoWaYoke` entrance animation

**Files:**
- Modify: `lib/core/widgets/mascot/pho_wa_yoke.dart`

**Interfaces:**
- Consumes: `AppMotion.slow`, `AppMotion.enter` (Task 1).
- Produces: no change to the public `PhoWaYoke` constructor/API — entrance animation is automatic on first mount. Task 7/screens require no changes to call sites.

- [ ] **Step 1: Add a one-time entrance animation**

In `lib/core/widgets/mascot/pho_wa_yoke.dart`, add the import:

```dart
import '../../theme/app_spacing.dart';
```

This adds a *second* `AnimationController` to `_PhoWaYokeState`. Change its
class declaration from `with SingleTickerProviderStateMixin` to
`with TickerProviderStateMixin` (singular only permits one ticker — creating
a second `AnimationController` on a `SingleTickerProviderStateMixin` throws
"multiple tickers were created" at runtime, not at analyze-time, so this is
easy to miss until you actually run the widget).

Add a second controller + animation alongside the existing `_idleController`/`_float`.
`MediaQuery.of(context)` cannot be called from a `late final` field
initializer, and is also unsafe to call directly from `initState`
(`dependOnInheritedWidgetOfExactType` throws if called before the first
build completes) — read the platform's accessibility flag directly via
`WidgetsBinding.instance.platformDispatcher` instead:

```dart
  late final AnimationController _entranceController;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _entranceController = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : AppMotion.slow,
    );
    _entrance = CurvedAnimation(parent: _entranceController, curve: AppMotion.enter);
    _entranceController.forward();
  }
```

The existing `_idleController`/`_float` field initializers
(`late final AnimationController _idleController = AnimationController(...)..repeat(reverse: true);`
and `late final Animation<double> _float = CurvedAnimation(...)`) are
unaffected — they don't need `context`, so they stay exactly as field
initializers. Only `_entranceController`/`_entrance` move into `initState`.

Update `dispose()` to also dispose the new controller:

```dart
  @override
  void dispose() {
    _idleController.dispose();
    _entranceController.dispose();
    super.dispose();
  }
```

Wrap the existing `AnimatedBuilder`-for-`_float` return value with the
entrance transform. Change the `build` method's `return SizedBox(...)` so the
outermost widget is:

```dart
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) {
        return Opacity(
          opacity: _entrance.value,
          child: Transform.scale(
            scale: 0.8 + (_entrance.value * 0.2),
            child: Transform.translate(
              offset: Offset(0, (1 - _entrance.value) * 12),
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size + 10,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, child) {
            final lift = _float.value * 8;
            final scale = 1 + _float.value * 0.03;
            return Transform.translate(
              offset: Offset(0, -lift),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: AnimatedSwitcher(
            duration: widget.animationDuration,
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: image,
          ),
        ),
      ),
    );
```

(The `final image = Image.asset(...)` line above stays exactly as-is.)

- [ ] **Step 2: Verify it compiles and the existing mascot tests still pass**

Run: `flutter analyze && flutter test test/widget_test.dart`
Expected: no analyzer errors; both existing tests still PASS (the mascot's
idle animation already required the special bounded-pump handling documented
in `test/widget_test.dart` — this entrance animation does not change that,
since it runs once and settles).

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/mascot/pho_wa_yoke.dart
git commit -m "feat(onboarding): add PhoWaYoke one-time entrance animation"
```

---

### Task 5: `MascotMessageCard` stagger timing + `OnboardingSelectionCard` press/gradient polish

**Files:**
- Modify: `lib/core/widgets/mascot/mascot_message_card.dart`
- Modify: `lib/core/widgets/onboarding/onboarding_selection_card.dart`

**Interfaces:**
- Consumes: `AppMotion.fast`/`press` (Task 1), `AppColors.cardFillGradient`, `AppColors.shadowMd`/`shadowLg`/`selectedShadowMd` (Task 2).
- Produces: no public API changes to either widget — both keep their existing constructors. `CreateAccountScreen` (Task 11) and `BasicInfoScreen` (Task 12) need no call-site changes for this task.

- [ ] **Step 1: Delay the message bubble in `MascotMessageCard`**

In `lib/core/widgets/mascot/mascot_message_card.dart`, wrap the
`messageBubble`'s `Container` child in a small fade-in with a delayed start.
Add the import:

```dart
import 'package:flutter/scheduler.dart';

import '../../theme/app_spacing.dart';
```

Convert `MascotMessageCard` from `StatelessWidget` to a small
`StatefulWidget` so it can run a delayed fade:

```dart
class MascotMessageCard extends StatefulWidget {
  final PhoWaYokeState state;
  final String message;
  final double mascotSize;
  final bool mascotOnRight;

  const MascotMessageCard({
    super.key,
    required this.state,
    required this.message,
    this.mascotSize = AppSizes.avatarLarge,
    this.mascotOnRight = false,
  });

  @override
  State<MascotMessageCard> createState() => _MascotMessageCardState();
}

class _MascotMessageCardState extends State<MascotMessageCard>
    with SingleTickerProviderStateMixin {
  // The bubble's fade is the back ~70% of a slightly longer timeline than
  // AppMotion.fast, so it visibly trails the mascot's own entrance instead of
  // popping in simultaneously. This is baked into one controller's Interval
  // rather than using a separate Future.delayed Timer — a bare Timer set up
  // in initState/didChangeDependencies is not reliably cancelled if the
  // widget is disposed first, and flutter_test's FakeAsync harness fails the
  // test with "Pending timers" if one outlives the test's pump cycle.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: AppMotion.enter),
  );
  bool _appliedReduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedReduceMotion) return;
    _appliedReduceMotion = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascot = PhoWaYoke(state: widget.state, size: widget.mascotSize);
    final messageBubble = Expanded(
      child: FadeTransition(
        opacity: _opacity,
        child: Semantics(
          liveRegion: widget.state == PhoWaYokeState.thinking,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.guidanceSurfaceGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              widget.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widget.mascotOnRight
          ? [messageBubble, const SizedBox(width: AppSpacing.md), mascot]
          : [mascot, const SizedBox(width: AppSpacing.md), messageBubble],
    );
  }
}
```

Note this also switches the bubble's flat `AppColors.communityBlue` fill to
the new `AppColors.guidanceSurfaceGradient` (Task 2) for the soft-depth look.

- [ ] **Step 2: Add press feedback + gradient fill to `OnboardingSelectionCard`**

In `lib/core/widgets/onboarding/onboarding_selection_card.dart`, add the
import:

```dart
import '../../theme/app_spacing.dart';
```

(It's likely already imported — check before duplicating.)

Convert the `InkWell`'s tap handling to track press state for the scale
effect. Change the `build` method's `Semantics > Material > InkWell` subtree
so `InkWell` becomes a `GestureDetector` wrapping an `AnimatedScale`, keeping
`Material`/`InkWell` for the ripple but adding the scale layer outside it:

```dart
    return Semantics(
      label: semanticLabel ?? label,
      selected: selected,
      button: true,
      image: true,
      child: _PressableScale(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.cardFillGradient : null,
              color: selected ? null : AppColors.lightSurface,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: selected ? AppColors.selectedShadowMd : AppColors.shadowMd,
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: AppSizes.avatarSm,
                      height: AppSizes.avatarSm,
                      decoration: const BoxDecoration(
                        color: AppColors.blue100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      sublabel!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (selected) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    const Icon(Icons.check_circle,
                        color: AppColors.purple700, size: AppSizes.iconSm + 2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
```

Add the shared `_PressableScale` helper at the bottom of the same file (it
will be reused by Task 6's `LargeButton` change is a *separate* small private
widget in that file instead — do not import private widgets across files;
each file gets its own copy since it's ~15 lines):

```dart
/// Wraps [child] with a subtle scale-down while pressed. Visual-only — the
/// hit-test area (and thus the 48px minimum touch target) is unchanged,
/// since the GestureDetector/Material below still own the actual tap area.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

(The `borderRadius` on `InkWell` clips the ripple to the card's rounded
corners — without it the ripple would bleed past the rounded edges.)

Remove the now-redundant outer `Material`/`InkWell` that used to wrap the
card directly under `Semantics` (it's now nested inside `_PressableScale`,
which provides its own `Material`/`InkWell` for the ripple) — make sure there
is exactly one `Material`/`InkWell` pair in the final file, not two stacked
ones. The `radius` local variable (`BorderRadius.circular(AppRadius.lg)`) is
still used by the `AnimatedContainer`'s `borderRadius:` — keep that line.

- [ ] **Step 3: Run analyzer + existing onboarding overflow test**

Run: `flutter analyze && flutter test test/onboarding_scaffold_overflow_test.dart`
Expected: no analyzer errors; existing overflow test still PASSES (the
`FittedBox` safety net is untouched by this change).

- [ ] **Step 4: Commit**

```bash
git add lib/core/widgets/mascot/mascot_message_card.dart lib/core/widgets/onboarding/onboarding_selection_card.dart
git commit -m "feat(onboarding): add press feedback to selection cards, delayed message bubble fade-in"
```

---

### Task 6: `LargeButton` press-scale + `celebratory` flag

**Files:**
- Modify: `lib/core/widgets/large_button.dart`

**Interfaces:**
- Consumes: `AppMotion.fast`/`press` (Task 1).
- Produces: `LargeButton(..., celebratory = false)` — new optional named
  parameter, default `false`, fully backward-compatible. When `true`, the
  button plays a one-shot checkmark "pop" on first mount. Task 9
  (`BasicInfoScreen`) does not use `celebratory` (it's reserved for the
  client/tasker completion screens in a later slice) — this task only adds
  the capability, no screen in this slice sets it to `true`.

- [ ] **Step 1: Convert `LargeButton` to a `StatefulWidget` with press-scale + celebratory pop**

Replace the full contents of `lib/core/widgets/large_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A big, tappable primary button with haptic feedback. Pure presentation —
/// it takes a label + callback and pulls all styling from the theme tokens.
class LargeButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool filled;
  final Gradient gradient;
  final Color outlineColor;
  final bool celebratory;

  const LargeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.gradient = AppColors.tealGradient,
    this.outlineColor = AppColors.teal,
    this.celebratory = false,
  });

  @override
  State<LargeButton> createState() => _LargeButtonState();
}

class _LargeButtonState extends State<LargeButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _popController = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : AppMotion.slow,
    );
    if (widget.celebratory) {
      _popController.forward();
    } else {
      _popController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final fg = widget.filled ? AppColors.onBrand : widget.outlineColor;
    final popScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: AppMotion.enter),
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: ScaleTransition(
          scale: popScale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: widget.filled ? widget.gradient : null,
                  borderRadius: radius,
                  border: widget.filled
                      ? null
                      : Border.all(color: widget.outlineColor, width: 2),
                  boxShadow: widget.filled
                      ? [
                          BoxShadow(
                            color: widget.gradient.colors.first.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Container(
                  height: AppSizes.buttonHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: fg, size: AppSizes.iconMd),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer + full test suite**

Run: `flutter analyze && flutter test`
Expected: no analyzer errors; all existing tests (`test/widget_test.dart`,
`test/onboarding_scaffold_overflow_test.dart`, `test/staggered_entrance_test.dart`)
PASS. `LargeButton`'s hit area is unchanged (still the full `InkWell` area at
`AppSizes.buttonHeight` = 58px tall, above the 48px minimum).

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/large_button.dart
git commit -m "feat(onboarding): add LargeButton press-scale and celebratory pop"
```

---

### Task 7: `OnboardingScaffold` layout mode + stagger adoption

**Files:**
- Modify: `lib/core/widgets/onboarding/onboarding_scaffold.dart`

**Interfaces:**
- Consumes: `StaggeredEntrance` (Task 3), `AppColors.guidanceSurfaceGradient` (Task 2).
- Produces: `OnboardingLayoutMode` enum (`form`, `moment`); `OnboardingScaffold(..., layout = OnboardingLayoutMode.form)` — new optional named parameter, default preserves current visual shape exactly. `WelcomeScreen` (Task 10) doesn't use `OnboardingScaffold` at all (it has its own bespoke layout) so it's unaffected by this task. `CreateAccountScreen` (Task 11) and `BasicInfoScreen` (Task 12) rely on the default `form` mode and don't need to pass `layout` explicitly.

- [ ] **Step 1: Read the current file**

Open `lib/core/widgets/onboarding/onboarding_scaffold.dart` (already read in
this session — 158 lines, the `OnboardingScaffold` `StatelessWidget` with a
`Scaffold > SafeArea > Column` of [header row, white rounded panel containing
a scrollable column of progress/mascot/title/body, then a pinned bottomBar]).

- [ ] **Step 2: Add the `OnboardingLayoutMode` enum and parameter**

Add above the `OnboardingScaffold` class:

```dart
/// Distinguishes celebratory/greeting screens (Welcome, completion) from
/// ordinary form steps. `moment` gives the mascot more room and drops the
/// progress chrome; `form` keeps today's shape.
enum OnboardingLayoutMode { form, moment }
```

Add a new field + constructor parameter:

```dart
  final OnboardingLayoutMode layout;
```

```dart
    this.layout = OnboardingLayoutMode.form,
```

(insert both in their respective existing field-list / constructor-parameter
list positions, alongside the other optional named parameters.)

- [ ] **Step 3: Wrap the scrollable body content in `StaggeredEntrance` and branch mascot sizing on `layout`**

Add the import:

```dart
import 'staggered_entrance.dart';
```

In the `build` method, find the `SingleChildScrollView`'s child `Column`'s
`children:` list (today: `[if (progress != null) ..., MascotMessageCard(...),
if (title != null || readAloudText != null) ..., body]`). Replace that
`Column` with:

```dart
                        child: StaggeredEntrance(
                          children: [
                            if (progress != null && layout == OnboardingLayoutMode.form)
                              OnboardingProgressHeader(progress: progress!),
                            MascotMessageCard(
                              state: mascotState,
                              message: mascotMessage,
                              mascotSize: layout == OnboardingLayoutMode.moment ? 96 : 64,
                            ),
                            if (title != null || readAloudText != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (title != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title!, style: theme.textTheme.headlineSmall),
                                          if (subtitle != null) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              subtitle!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (readAloudText != null)
                                    ReadAloudButton(textToRead: readAloudText!),
                                ],
                              ),
                            body,
                          ],
                        ),
```

> Note: `StaggeredEntrance` renders its children in a plain `Column` (it does
> not add its own spacing), so the existing `SizedBox(height: ...)` gap
> widgets that used to sit *between* list items in the old `children:` array
> are gone in the snippet above. Re-add them as their own list entries
> (non-animated spacer rows render fine inside `StaggeredEntrance` — they're
> just zero-opacity-at-time-0 empty boxes, invisible either way) — i.e. insert
> `const SizedBox(height: AppSpacing.lg)` between each conditional block,
> matching the original file's exact spacing values at each of those three
> gaps before `body`.

- [ ] **Step 4: Run analyzer + onboarding overflow test**

Run: `flutter analyze && flutter test test/onboarding_scaffold_overflow_test.dart`
Expected: no analyzer errors; overflow test still PASSES.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/onboarding/onboarding_scaffold.dart
git commit -m "feat(onboarding): add OnboardingLayoutMode and staggered body entrance to OnboardingScaffold"
```

---

### Task 8: Onboarding-only route transitions

**Files:**
- Modify: `lib/core/routing/app_router.dart`

**Interfaces:**
- Consumes: `AppMotion.medium`, `AppMotion.enter` (Task 1).
- Produces: `_onboardingTransitionPage(path, builder)` — a private helper
  returning a `CustomTransitionPage`. Used only inside `_onboardingRoutes`;
  no other route group changes.

- [ ] **Step 1: Add the transition helper**

Add the import:

```dart
import '../theme/app_spacing.dart';
```

Add this private helper above `_onboardingRoutes`. It takes the already-built
screen `child` rather than a builder function — each `GoRoute` entry calls it
from its own `pageBuilder`, where `GoRouterState` is already in scope:

```dart
Page<void> _onboardingTransitionPage({required String path, required Widget child}) {
  return CustomTransitionPage<void>(
    key: ValueKey(path),
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, transitionChild) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      return FadeTransition(
        opacity: curved,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: transitionChild,
        ),
      );
    },
  );
}
```

- [ ] **Step 2: Apply it to the 3 in-scope routes**

In `_onboardingRoutes`, change exactly these 3 entries from `builder:` to
`pageBuilder:`. The first one (`onboardingWelcome`):

```dart
  GoRoute(
    path: Routes.onboardingWelcome,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingWelcome,
      child: const WelcomeScreen(),
    ),
  ),
```

The second (`onboardingCreateAccount`):

```dart
  GoRoute(
    path: Routes.onboardingCreateAccount,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingCreateAccount,
      child: const CreateAccountScreen(),
    ),
  ),
```

The third (`onboardingBasicInfo`):

```dart
  GoRoute(
    path: Routes.onboardingBasicInfo,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingBasicInfo,
      child: const BasicInfoScreen(),
    ),
  ),
```

Leave every other route in `_onboardingRoutes` (and all of
`_customerRoutes`/`_workerRoutes`/`_chatbotRoutes`) using plain `builder:` —
unchanged, per the spec's "only needs to visibly apply to these 3 routes for
this slice" scoping.

- [ ] **Step 3: Run analyzer + full test suite**

Run: `flutter analyze && flutter test`
Expected: no analyzer errors. `test/widget_test.dart`'s "Forward navigation
builds a back stack" test pumps a fixed `Duration(milliseconds: 400)` after
each navigation — confirm this is still ≥ `AppMotion.medium` (250ms) so the
transition has settled by the time the test asserts; it is (400 > 250), so no
test changes needed.

- [ ] **Step 4: Commit**

```bash
git add lib/core/routing/app_router.dart
git commit -m "feat(onboarding): add fade+slide-up transition for Welcome, Create Account, Basic Info routes"
```

---

### Task 9: Draft warmer copy for the 3 screens

**Files:**
- Modify: `lib/core/constants/onboarding_strings.dart`

**Interfaces:**
- Produces: 3 new additive constants — `welcomeMessageV2`, `chooseRolePromptV2`, `basicInfoMascotMessageV2`. Existing constants (`welcomeMessage`, `chooseRolePrompt`, `basicInfoMascotMessage`) are untouched. Task 10/11/12 (screen updates) reference the `V2` constants.

- [ ] **Step 1: Add the draft strings**

In `lib/core/constants/onboarding_strings.dart`, immediately after
`welcomeMessage`'s definition, add:

```dart
  // TODO(native-speaker-review): drafted warmer copy for the redesign slice
  // in docs/superpowers/specs/2026-06-22-onboarding-redesign-design.md §7.
  // Needs a Burmese speaker to review tone/wording before this replaces
  // welcomeMessage above.
  static const String welcomeMessageV2 =
      "မင်္ဂလာပါနော်! ကျွန်တော် ဖိုးဝရုပ် ပါ။ သင့်အတွက် အကောင်းဆုံး လုပ်သားလေးတွေကို ရှာပေးမှာပါ — လက်ဆွဲပြီး လမ်းညွှန်ပေးမယ်နော်။";
```

Immediately after `chooseRolePrompt`'s definition, add:

```dart
  // TODO(native-speaker-review): see welcomeMessageV2 above for context.
  static const String chooseRolePromptV2 =
      "ကိစ္စမရှိပါ — ဘယ်လိုစလိုလဲ ပြောပြပါ။ အကူအညီ လိုချင်လား၊ ဝန်ဆောင်မှု ပေးချင်လား။";
```

Immediately after `basicInfoMascotMessage`'s definition, add:

```dart
  // TODO(native-speaker-review): see welcomeMessageV2 above for context.
  static const String basicInfoMascotMessageV2 =
      "နီးနီးကပ်ကပ်ပါ! အမည်လေးနှင့် ဆက်သွယ်ရန် အချက်အလက်လေး ပေးလိုက်ရင် ပြီးပါပြီနော်။";
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no new errors (unused-field warnings won't fire since these are
`static const` class members, not local variables).

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/onboarding_strings.dart
git commit -m "feat(onboarding): draft warmer Burmese copy for Welcome/CreateAccount/BasicInfo (needs native-speaker review)"
```

---

### Task 10: Adopt everything in `WelcomeScreen`

**Files:**
- Modify: `lib/features/onboarding/welcome_screen.dart`

**Interfaces:**
- Consumes: `OnboardingStrings.welcomeMessageV2` (Task 9), `LargeButton.celebratory` is NOT used here (Welcome's button is the entrance action, not a celebration). `PhoWaYoke`'s entrance animation (Task 4) applies automatically — no call-site change needed for that.

- [ ] **Step 1: Switch the welcome message to the drafted copy**

In `lib/features/onboarding/welcome_screen.dart`, change:

```dart
                          OnboardingStrings.welcomeMessage,
```

to:

```dart
                          OnboardingStrings.welcomeMessageV2,
```

(This is the `Text` inside the white message-bubble `Container`, not the
`OnboardingStrings.welcomeHeadline` text above it — leave the headline
unchanged, it's not in scope for this task's copy list.)

- [ ] **Step 2: Verify it compiles and renders**

Run: `flutter analyze`
Expected: no errors.

Run: `flutter test test/widget_test.dart`
Expected: PASS — note the first test asserts `find.text('TOLY MOLY')`
(unaffected) and the second test asserts `find.text(OnboardingStrings.getStarted)`
(unaffected); neither test reads `welcomeMessage`/`welcomeMessageV2`, so no
test changes are needed here.

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/welcome_screen.dart
git commit -m "feat(onboarding): adopt drafted welcome copy on WelcomeScreen"
```

---

### Task 11: Adopt everything in `CreateAccountScreen`

**Files:**
- Modify: `lib/features/onboarding/create_account_screen.dart`

**Interfaces:**
- Consumes: `OnboardingLayoutMode` (Task 7, used implicitly via default —
  no change needed since `form` is the default), `OnboardingStrings.chooseRolePromptV2`
  (Task 9). The animated tab indicator is new UI built entirely within this
  file's existing `_TabToggle`/`_TabButton` private widgets.

- [ ] **Step 1: Switch the mascot message to the drafted copy**

Change:

```dart
      mascotMessage: OnboardingStrings.chooseRolePrompt,
```

to:

```dart
      mascotMessage: OnboardingStrings.chooseRolePromptV2,
```

Leave the `Text(OnboardingStrings.chooseRolePrompt, ...)` line inside
`_roleFields` (the section heading above the role cards) unchanged — that's
a UI label, not the mascot's spoken line, and is out of this task's copy
scope.

- [ ] **Step 2: Animate the tab toggle's selected pill**

Replace the `_TabToggle` class with a version that animates the selected
background instead of swapping `_TabButton`'s own `Material.color` instantly.
Replace the full `_TabToggle` and `_TabButton` classes at the bottom of the
file with:

```dart
class _TabToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _TabToggle({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: AppMotion.fast,
            curve: AppMotion.press,
            alignment: isLogin ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.purple700,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: OnboardingStrings.createAccountTab,
                  selected: !isLogin,
                  onTap: () => onChanged(false),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: OnboardingStrings.loginTab,
                  selected: isLogin,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onBrand : AppColors.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
```

Add the import for `AppMotion` if not already present via `app_spacing.dart`
(it already imports `app_spacing.dart` for `AppSpacing`/`AppRadius` — `AppMotion`
lives in the same file, so no new import line is needed).

- [ ] **Step 3: Verify it compiles and the existing navigation test still passes**

Run: `flutter analyze && flutter test`
Expected: no analyzer errors; all tests PASS. The "Forward navigation builds a
back stack" test in `test/widget_test.dart` taps `find.text(OnboardingStrings.getStarted)`
then asserts `find.text(OnboardingStrings.chooseRolePrompt)` — note this
asserts the *unchanged* `chooseRolePrompt` (the role-cards section heading,
which this task left as-is), not `chooseRolePromptV2` (the mascot message) —
so this existing assertion still passes unmodified.

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/create_account_screen.dart
git commit -m "feat(onboarding): animated tab indicator and drafted mascot copy on CreateAccountScreen"
```

---

### Task 12: Adopt everything in `BasicInfoScreen`

**Files:**
- Modify: `lib/features/onboarding/basic_info_screen.dart`

**Interfaces:**
- Consumes: `OnboardingStrings.basicInfoMascotMessageV2` (Task 9).

- [ ] **Step 1: Switch the mascot message to the drafted copy**

Change:

```dart
      mascotMessage: OnboardingStrings.basicInfoMascotMessage,
```

to:

```dart
      mascotMessage: OnboardingStrings.basicInfoMascotMessageV2,
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/basic_info_screen.dart
git commit -m "feat(onboarding): adopt drafted mascot copy on BasicInfoScreen"
```

---

### Task 13: Full verification pass

**Files:** none (verification only).

- [ ] **Step 1: Run the full analyzer**

Run: `flutter analyze`
Expected: only the 2 pre-existing, unrelated `activeColor` deprecation infos
in `worker_list_screen.dart`/`dashboard_screen.dart` — zero new issues.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests PASS — `test/widget_test.dart` (2 tests),
`test/onboarding_scaffold_overflow_test.dart` (1 test),
`test/staggered_entrance_test.dart` (2 tests).

- [ ] **Step 3: Manual emulator walkthrough**

Run the app on the Android emulator (or any connected device):
`flutter run`. Navigate Welcome → tap "Get started" → toggle the Sign
up/Log in tab back and forth (confirm the pill slides) → pick a role (confirm
press feedback + the mascot's reactive moment) → continue → Basic Info
(confirm fields stagger in, mascot entrance plays). Confirm no visual
overflow/jank at default text scale.

- [ ] **Step 4: Final commit (if any uncommitted changes remain)**

```bash
git status
```

Expected: clean working tree (everything was committed per-task in Tasks 1–12).
