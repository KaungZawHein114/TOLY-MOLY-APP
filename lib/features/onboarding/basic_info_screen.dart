import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../core/widgets/onboarding/read_aloud_button.dart';
import '../../core/widgets/onboarding/speech_to_text_button.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

/// Step 2 of signup: name, phone, and password — reached only after a role
/// has been chosen on [CreateAccountScreen].
class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  String? _nameError;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final role = ref.read(selectedRoleProvider);
    final name = role == UserRole.tasker
        ? ref.read(taskerDraftProvider).name
        : ref.read(clientDraftProvider).name;
    final phone = role == UserRole.tasker
        ? ref.read(taskerDraftProvider).phone
        : ref.read(clientDraftProvider).phone;
    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continue() {
    final role = ref.read(selectedRoleProvider);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? OnboardingStrings.nameRequiredError : null;
      _phoneError = phone.isEmpty ? OnboardingStrings.phoneRequiredError : null;
      _passwordError = password.isEmpty ? OnboardingStrings.passwordRequiredError : null;
    });
    if (name.isEmpty || phone.isEmpty || password.isEmpty) return;

    if (role == UserRole.tasker) {
      ref.read(taskerDraftProvider.notifier).state =
          ref.read(taskerDraftProvider).copyWith(name: name, phone: phone);
      context.push(Routes.taskerPersonal);
    } else {
      ref.read(clientDraftProvider.notifier).state =
          ref.read(clientDraftProvider).copyWith(name: name, phone: phone);
      context.push(Routes.clientPersonal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.basicInfoMascotMessage,
      title: OnboardingStrings.basicInfoTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReadAloudButton(textToRead: OnboardingStrings.basicInfoInstructions),
              const SizedBox(width: AppSpacing.md),
              SpeechToTextButton(
                semanticPrompt: OnboardingStrings.nameLabel,
                mockTranscript: "Aye Aye",
                onResult: (v) => setState(() => _nameController.text = v),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  "${OnboardingStrings.readAloudButton} / ${OnboardingStrings.speakButton}",
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.nameLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.namePlaceholder,
              errorText: _nameError,
              filled: true,
              fillColor: AppColors.blue100,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.phoneLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  widthFactor: 1,
                  child: Text("MM +95", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              hintText: "09•••••••••",
              errorText: _phoneError,
              filled: true,
              fillColor: AppColors.blue100,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.passwordLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.passwordPlaceholder,
              errorText: _passwordError,
              filled: true,
              fillColor: AppColors.blue100,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
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
