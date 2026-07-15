import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../../core/widgets/onboarding/shake_on_trigger.dart';
import '../../auth/audio/auth_audio_button.dart';
import '../../auth/audio/auth_audio_map.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';
import '../widgets/voice_fill_banner.dart';

/// "About You" — the redesigned journey's first form step: name, gender and
/// age together in one comfortable chunk (all recognition/simple answers, no
/// credentials). Phone + password come on the next step, once the user has
/// already invested in the flow.
class ClientPersonalInfoScreen extends ConsumerStatefulWidget {
  const ClientPersonalInfoScreen({super.key});

  @override
  ConsumerState<ClientPersonalInfoScreen> createState() => _ClientPersonalInfoScreenState();
}

class _ClientPersonalInfoScreenState extends ConsumerState<ClientPersonalInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  String? _nameError;
  String? _ageError;
  int _genderShakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(clientDraftProvider);
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
    final notifier = ref.read(clientDraftProvider.notifier);
    notifier.state = notifier.state.copyWith(
      name: _nameController.text,
      gender: gender,
      age: int.tryParse(_ageController.text),
    );
  }

  // Live check, called from the age field's onChanged so an out-of-range
  // age shows up as soon as it's typed, not only after "Continue" is pressed.
  // Returns null while the field is still empty.
  String? _ageFormatError(String value) {
    if (value.isEmpty) return null;
    final age = int.tryParse(value);
    return (age == null || age < 18 || age > 80) ? OnboardingStrings.ageRangeError : null;
  }

  void _continue() {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final gender = ref.read(clientDraftProvider).gender;

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
    context.push(Routes.onboardingBasicInfo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(clientDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.clientPersonalMascotMessage,
      title: OnboardingStrings.aboutYouTitle,
      // No recorded clip for the whole-screen prompt; each field below has its
      // own recorded listen button instead (no TTS on auth screens).
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Speak once → Pho Wa Yoke fills the whole form (name/gender/age,
          // and the phone number for the next step).
          VoiceFillBanner(
            role: UserRole.client,
            onApplied: () {
              final d = ref.read(clientDraftProvider);
              setState(() {
                if (d.name.isNotEmpty) _nameController.text = d.name;
                if (d.age != null) _ageController.text = d.age.toString();
              });
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.nameLabel,
            audioKey: AuthAudioKeys.name,
            mockTranscript: "Aye Aye",
            onSpeechResult: (v) => setState(() => _updateDraft()),
            controller: _nameController,
            leadingIcon: Icons.person_outline,
            hintText: OnboardingStrings.namePlaceholder,
            errorText: _nameError,
            onChanged: (v) => setState(() {
              if (v.trim().isNotEmpty) _nameError = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text(OnboardingStrings.genderLabel, style: theme.textTheme.titleMedium)),
              const AuthAudioButton(
                audioKey: AuthAudioKeys.gender,
                semanticLabel: OnboardingStrings.genderLabel,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Two large pictorial cards only (no "other" option) — an
          // immediately recognizable visual choice, never a dropdown.
          ShakeOnTrigger(
            trigger: _genderShakeTrigger,
            child: Row(
              children: [
                for (final g in const [Gender.male, Gender.female])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: OnboardingSelectionCard(
                        emoji: g.emoji,
                        label: g.label,
                        selected: draft.gender == g,
                        onTap: () => _updateDraft(gender: g),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.ageLabel,
            audioKey: AuthAudioKeys.age,
            mockTranscript: "25",
            onSpeechResult: (v) => setState(() {
              _ageError = _ageFormatError(v.trim());
              _updateDraft();
            }),
            controller: _ageController,
            keyboardType: TextInputType.number,
            leadingIcon: Icons.cake_outlined,
            hintText: OnboardingStrings.agePlaceholder,
            errorText: _ageError,
            onChanged: (v) => setState(() {
              _ageError = _ageFormatError(v.trim());
              _updateDraft();
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        onTap: _continue,
      ),
    );
  }
}
