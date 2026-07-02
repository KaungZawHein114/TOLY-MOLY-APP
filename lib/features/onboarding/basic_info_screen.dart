import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/field_label_with_voice.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../auth/data/auth_failure.dart';
import '../auth/providers/auth_provider.dart';
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
  bool _obscurePassword = true;
  bool _isSubmitting = false;

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

  Future<void> _continue() async {
    if (_isSubmitting) return;
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

    // Sending the OTP right here — not on the phone-verification screen two
    // steps later — is what makes a duplicate-phone error show up
    // immediately, in red, right under the field the user just typed it
    // into, instead of silently surfacing on a later screen.
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!mounted) return;
      if (role == UserRole.tasker) {
        ref.read(taskerDraftProvider.notifier).state = ref.read(taskerDraftProvider).copyWith(
              name: name,
              phone: phone,
              password: password,
              otpSent: true,
              lastDevOtpCode: result.devCode,
            );
        context.push(Routes.taskerPersonal);
      } else {
        ref.read(clientDraftProvider.notifier).state = ref.read(clientDraftProvider).copyWith(
              name: name,
              phone: phone,
              password: password,
              otpSent: true,
              lastDevOtpCode: result.devCode,
            );
        context.push(Routes.clientPersonal);
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      if (e.code == "phone_already_registered") {
        setState(() => _phoneError = e.message);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.basicInfoMascotMessageV2,
      title: OnboardingStrings.basicInfoTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabelWithVoice(
            label: OnboardingStrings.nameLabel,
            readAloudText: OnboardingStrings.nameLabel,
            mockTranscript: "Aye Aye",
            onSpeechResult: (v) => setState(() => _nameController.text = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.namePlaceholder,
              errorText: _nameError,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(focused: true),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FieldLabelWithVoice(
            label: OnboardingStrings.phoneLabel,
            readAloudText: OnboardingStrings.phoneLabel,
            mockTranscript: "09123456789",
            onSpeechResult: (v) => setState(() => _phoneController.text = v),
          ),
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
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(focused: true),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FieldLabelWithVoice(
            label: OnboardingStrings.passwordLabel,
            readAloudText: OnboardingStrings.passwordLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: OnboardingStrings.passwordPlaceholder,
              errorText: _passwordError,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              border: _fieldBorder(),
              enabledBorder: _fieldBorder(),
              focusedBorder: _fieldBorder(focused: true),
              suffixIcon: Semantics(
                label: _obscurePassword
                    ? OnboardingStrings.showPasswordLabel
                    : OnboardingStrings.hidePasswordLabel,
                button: true,
                child: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
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

/// Shared text-field border for this screen: a soft divider-colored outline
/// at rest, switching to a thicker brand-purple outline on focus.
OutlineInputBorder _fieldBorder({bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(
      color: focused ? AppColors.purple700 : AppColors.onboardingDivider,
      width: focused ? 2 : 1,
    ),
  );
}
