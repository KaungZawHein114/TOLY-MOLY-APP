import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_mock.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/skill_tile.dart';

// LOCAL UI STATE (Riverpod), declared in this screen file.
final onboardStepProvider = StateProvider<int>((ref) => 0);
final onboardAgeProvider = StateProvider<double>((ref) => 28);
final onboardSkillsProvider = StateProvider<Set<String>>((ref) => {});

class WorkerOnboardingScreen extends ConsumerStatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  ConsumerState<WorkerOnboardingScreen> createState() =>
      _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState
    extends ConsumerState<WorkerOnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _experience = "";

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Synchronous mock voice capture — fills the form instantly.
  void _captureVoice() {
    HapticFeedback.mediumImpact();
    final data = extractVoiceData("I'm a plumber, 5 years");
    _nameController.text = data["name"] ?? "";
    _experience = data["experience"] ?? "";
    final skill = data["skill"];
    if (skill != null) {
      ref.read(onboardSkillsProvider.notifier).state = {skill};
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎙️ Voice captured: ${data['name']}, $skill, "
            "${data['experience']}"),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardStepProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Worker setup • Step ${step + 1}/3"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (step == 0) {
              // Step 1: leave onboarding — pop back to whatever pushed us
              // (Role Selection), or reset to it if this is the stack root.
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.role);
              }
            } else {
              // Later steps: just go back a step (in-screen state, no nav).
              ref.read(onboardStepProvider.notifier).state = step - 1;
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(step),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _stepOne();
      case 1:
        return _stepTwo();
      default:
        return _stepThree();
    }
  }

  // STEP 1 — Name + Age (voice button + slider)
  Widget _stepOne() {
    final theme = Theme.of(context);
    final age = ref.watch(onboardAgeProvider);
    return ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text("Tell us about you", style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text("Tap the mic to auto-fill with your voice.",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.hintColor)),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Full name",
            hintText: "e.g. Ko Aung",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        if (_experience.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text("Experience detected: $_experience",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.teal)),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: GestureDetector(
            onTap: _captureVoice,
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: AppColors.onBrand, size: 40),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Center(child: Text("Tap to speak")),
        const SizedBox(height: AppSpacing.xxl + 4),
        Text("Age: ${age.round()}", style: theme.textTheme.titleMedium),
        Slider(
          value: age,
          min: 18,
          max: 65,
          divisions: 47,
          activeColor: AppColors.teal,
          label: age.round().toString(),
          onChanged: (v) =>
              ref.read(onboardAgeProvider.notifier).state = v,
        ),
        const SizedBox(height: AppSpacing.md),
        LargeButton(
          label: "Continue",
          icon: Icons.arrow_forward,
          onTap: () => ref.read(onboardStepProvider.notifier).state = 1,
        ),
      ],
    );
  }

  // STEP 2 — Skills (badges, select 1–3)
  Widget _stepTwo() {
    final theme = Theme.of(context);
    final selected = ref.watch(onboardSkillsProvider);
    final badges = skillBadges.isNotEmpty ? skillBadges : fallbackCategories;
    return Column(
      key: const ValueKey(1),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("What can you do?", style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text("Pick 1–3 skills (${selected.length}/3 selected)",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final b = badges[i];
              final isSel = selected.contains(b.name);
              return SkillTile(
                emoji: b.icon,
                label: b.name,
                sublabel: b.burmese,
                selected: isSel,
                onTap: () => _toggleSkill(b.name, selected),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: LargeButton(
            label: selected.isEmpty ? "Select at least 1 skill" : "Continue",
            icon: Icons.arrow_forward,
            onTap: () {
              if (selected.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pick at least one skill")),
                );
                return;
              }
              ref.read(onboardStepProvider.notifier).state = 2;
            },
          ),
        ),
      ],
    );
  }

  void _toggleSkill(String name, Set<String> current) {
    final next = Set<String>.from(current);
    if (next.contains(name)) {
      next.remove(name);
    } else {
      if (next.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can pick up to 3 skills")),
        );
        return;
      }
      next.add(name);
    }
    ref.read(onboardSkillsProvider.notifier).state = next;
  }

  // STEP 3 — Slide to Accept Rules
  Widget _stepThree() {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Text("📜", style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppSpacing.md),
          Text("Worker agreement", style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                "By joining TOLY MOLY you agree to:\n\n"
                "• Arrive on time and complete the booked task.\n"
                "• Quote fair, transparent prices.\n"
                "• Treat every customer with respect.\n"
                "• Keep your tools and skills up to date.\n"
                "• Maintain a rating above 4.0 stars.\n\n"
                "Slide the button below to accept and start receiving jobs.",
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: _SlideToAccept(
                onAccepted: () {
                  HapticFeedback.heavyImpact();
                  context.go(Routes.dashboard);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.sm),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.teal
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A horizontal "slide to accept" control. Pure gesture math — no async.
class _SlideToAccept extends StatefulWidget {
  final VoidCallback onAccepted;
  const _SlideToAccept({required this.onAccepted});

  @override
  State<_SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<_SlideToAccept> {
  double _dx = 0;
  bool _done = false;
  static const double _thumb = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDx = constraints.maxWidth - _thumb;
        return Container(
          height: _thumb,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_thumb / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                _done ? "Accepted ✓" : "Slide to accept →",
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.tealDark),
              ),
              Positioned(
                left: _dx,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    if (_done) return;
                    setState(() {
                      _dx = (_dx + d.delta.dx).clamp(0.0, maxDx);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dx > maxDx * 0.85) {
                      setState(() {
                        _dx = maxDx;
                        _done = true;
                      });
                      widget.onAccepted();
                    } else {
                      setState(() => _dx = 0);
                    }
                  },
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: const BoxDecoration(
                      gradient: AppColors.tealGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _done ? Icons.check : Icons.chevron_right,
                      color: AppColors.onBrand,
                      size: AppSizes.iconLg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
