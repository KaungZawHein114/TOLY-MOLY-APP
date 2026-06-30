import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/field_label_with_voice.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../../../core/widgets/onboarding/shake_on_trigger.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class ClientPersonalInfoScreen extends ConsumerStatefulWidget {
  const ClientPersonalInfoScreen({super.key});

  @override
  ConsumerState<ClientPersonalInfoScreen> createState() => _ClientPersonalInfoScreenState();
}

class _ClientPersonalInfoScreenState extends ConsumerState<ClientPersonalInfoScreen> {
  late final TextEditingController _ageController;
  String? _ageError;
  int _genderShakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(clientDraftProvider);
    _ageController = TextEditingController(text: draft.age?.toString() ?? "");
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _updateDraft({Gender? gender}) {
    final notifier = ref.read(clientDraftProvider.notifier);
    notifier.state = notifier.state.copyWith(
      gender: gender,
      age: int.tryParse(_ageController.text),
    );
  }

  void _continue() {
    final age = int.tryParse(_ageController.text.trim());
    final gender = ref.read(clientDraftProvider).gender;

    setState(() {
      _ageError = (age == null || age < 18 || age > 80) ? OnboardingStrings.ageRangeError : null;
    });
    if (_ageError != null || gender == null) {
      if (gender == null) {
        setState(() => _genderShakeTrigger++);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("လိင် ရွေးချယ်ပေးပါနော်")),
        );
      }
      return;
    }

    _updateDraft();
    context.push(Routes.clientPhone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(clientDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.clientPersonalMascotMessage,
      title: OnboardingStrings.personalInfoTitle,
      readAloudText: OnboardingStrings.clientPersonalMascotMessage,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(OnboardingStrings.genderLabel, style: theme.textTheme.titleMedium)),
              ReadAloudButton(textToRead: OnboardingStrings.genderLabel, compact: true),
            ],
          ),
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
          FieldLabelWithVoice(
            label: OnboardingStrings.ageLabel,
            readAloudText: OnboardingStrings.ageLabel,
            mockTranscript: "25",
            onSpeechResult: (v) => setState(() {
              _ageController.text = v;
              _updateDraft();
            }),
          ),
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
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: _continue,
      ),
    );
  }
}
