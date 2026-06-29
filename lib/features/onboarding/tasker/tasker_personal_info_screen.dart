import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../../core/widgets/onboarding/shake_on_trigger.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class TaskerPersonalInfoScreen extends ConsumerStatefulWidget {
  const TaskerPersonalInfoScreen({super.key});

  @override
  ConsumerState<TaskerPersonalInfoScreen> createState() => _TaskerPersonalInfoScreenState();
}

class _TaskerPersonalInfoScreenState extends ConsumerState<TaskerPersonalInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  String? _nameError;
  String? _ageError;
  int _genderShakeTrigger = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(taskerDraftProvider);
    _nameController = TextEditingController(text: draft.name);
    _ageController = TextEditingController(text: draft.age?.toString() ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updateDraft({Gender? gender}) {
    final notifier = ref.read(taskerDraftProvider.notifier);
    notifier.state = notifier.state.copyWith(
      name: _nameController.text,
      gender: gender,
      age: int.tryParse(_ageController.text),
    );
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final gender = ref.read(taskerDraftProvider).gender;

    setState(() {
      _nameError = name.isEmpty ? OnboardingStrings.nameRequiredError : null;
      _ageError = (age == null || age < 18 || age > 80) ? OnboardingStrings.ageRangeError : null;
    });
    if (_nameError != null || _ageError != null || gender == null) {
      if (gender == null) {
        setState(() => _genderShakeTrigger++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("လိင် ရွေးချယ်ပေးပါနော်")),
        );
      }
      return;
    }

    _updateDraft();
    final draft = ref.read(taskerDraftProvider);

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authRepositoryProvider).register(
            name: draft.name,
            phoneNumber: draft.phone,
            password: draft.password,
            gender: gender.name,
            age: age!,
            role: "TASKER",
          );
      if (!mounted) return;
      context.push(Routes.taskerPhone);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskerDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 6),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.taskerPersonalMascotMessage,
      title: OnboardingStrings.personalInfoTitle,
      readAloudText: OnboardingStrings.taskerPersonalMascotMessage,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(OnboardingStrings.nameLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.namePlaceholder,
              errorText: _nameError,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                SpeechToTextButton(
                  semanticPrompt: OnboardingStrings.speakButton,
                  mockTranscript: "Aung Aung",
                  large: true,
                  onResult: (v) => setState(() => _nameController.text = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(OnboardingStrings.speakButton, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.genderLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ShakeOnTrigger(
            trigger: _genderShakeTrigger,
            child: Row(
              children: Gender.values.map((g) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: OnboardingSelectionCard(
                      emoji: g.emoji,
                      label: g.label,
                      selected: draft.gender == g,
                      onTap: () => _updateDraft(gender: g),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.ageLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.agePlaceholder,
              errorText: _ageError,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: LargeButton(
        label: _isSubmitting ? OnboardingStrings.submittingLabel : OnboardingStrings.continueButton,
        icon: _isSubmitting ? null : Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: _continue,
      ),
    );
  }
}
