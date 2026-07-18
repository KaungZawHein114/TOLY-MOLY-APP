import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../auth/audio/auth_audio_map.dart';
import '../auth/data/auth_failure.dart';
import '../auth/providers/auth_provider.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

/// "Account security" step of the redesigned journey: phone number and
/// password ONLY — asked after the easy About You questions, right before
/// verification, when the user has already invested in the flow
/// (progressive disclosure). Name/gender/age were collected one step
/// earlier and already live on the role's draft.
///
/// Continue sends the OTP immediately, so a duplicate-phone error shows up
/// in red under the exact field the user just typed — never two screens
/// later.
class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  late final TextEditingController _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneError;
  String? _passwordError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final role = ref.read(selectedRoleProvider);
    final phone = role == UserRole.tasker
        ? ref.read(taskerDraftProvider).phone
        : ref.read(clientDraftProvider).phone;
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Live, per-field checks — called from each field's onChanged so a bad
  // phone/password shows up the moment it's typed, not only after
  // "Continue" is pressed. Returns null while the field is still empty (no
  // "required" nagging before the user has started typing).
  static final _phoneRegex = RegExp(r'^09\d{7,9}$');
  static final _numericOnlyRegex = RegExp(r'^\d+$');

  String? _phoneFormatError(String phone) {
    if (phone.isEmpty) return null;
    return _phoneRegex.hasMatch(phone) ? null : OnboardingStrings.phoneInvalidError;
  }

  String? _passwordFormatError(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return OnboardingStrings.passwordTooShortError;
    if (_numericOnlyRegex.hasMatch(password)) return OnboardingStrings.passwordNumericOnlyError;
    return null;
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final role = ref.read(selectedRoleProvider);
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _phoneError = phone.isEmpty ? OnboardingStrings.phoneRequiredError : _phoneFormatError(phone);
      _passwordError =
          password.isEmpty ? OnboardingStrings.passwordRequiredError : _passwordFormatError(password);
    });
    if (_phoneError != null || _passwordError != null) return;

    // Sending the OTP right here — not on the verification screen — is what
    // makes a duplicate-phone error show up immediately, in red, right under
    // the field the user just typed it into.
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!mounted) return;
      if (role == UserRole.tasker) {
        ref.read(taskerDraftProvider.notifier).state = ref.read(taskerDraftProvider).copyWith(
              phone: phone,
              password: password,
              otpSent: true,
              lastDevOtpCode: result.devCode,
            );
        context.push(Routes.taskerPhone);
      } else {
        ref.read(clientDraftProvider.notifier).state = ref.read(clientDraftProvider).copyWith(
              phone: phone,
              password: password,
              otpSent: true,
              lastDevOtpCode: result.devCode,
            );
        context.push(Routes.clientPhone);
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
    final role = ref.watch(selectedRoleProvider);
    final isTasker = role == UserRole.tasker;

    return OnboardingScaffold(
      progress: OnboardingProgress(step: 2, totalSteps: isTasker ? 5 : 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.accountStepMascotMessage,
      title: OnboardingStrings.accountStepTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: OnboardingStrings.phoneLabel,
            audioKey: AuthAudioKeys.phone,
            mockTranscript: "09123456789",
            onSpeechResult: (v) => setState(
                () => _phoneError = _phoneFormatError(v.trim())),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixText: "MM +95",
            hintText: "09•••••••••",
            errorText: _phoneError,
            onChanged: (v) =>
                setState(() => _phoneError = _phoneFormatError(v.trim())),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.passwordLabel,
            audioKey: AuthAudioKeys.password,
            controller: _passwordController,
            obscureText: true,
            leadingIcon: Icons.lock_outline,
            hintText: OnboardingStrings.passwordPlaceholder,
            helperText: OnboardingStrings.passwordHelper,
            errorText: _passwordError,
            onChanged: (v) =>
                setState(() => _passwordError = _passwordFormatError(v.trim())),
          ),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        loading: _isSubmitting,
        onTap: _continue,
      ),
    );
  }
}
