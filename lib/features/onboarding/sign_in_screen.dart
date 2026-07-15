import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_error_message.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../auth/audio/auth_audio_button.dart';
import '../auth/audio/auth_audio_map.dart';
import '../auth/data/auth_failure.dart';
import '../auth/providers/auth_provider.dart';

/// Dedicated returning-user sign-in — its own screen (Jakob's law: every app
/// this audience knows puts "log in" one obvious tap from the first screen),
/// holding exactly two fields and one action. New users never see it.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final filled = phone.isNotEmpty && password.isNotEmpty;
    setState(() {
      _error = filled ? null : OnboardingStrings.loginFieldsRequiredError;
    });
    if (!filled) return;

    setState(() => _isLoggingIn = true);
    try {
      final session = await ref.read(authRepositoryProvider).login(
            phoneNumber: phone,
            password: password,
          );
      if (!mounted) return;
      context.go(session.user.role == "CLIENT"
          ? Routes.customerHome
          : Routes.dashboard);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingScaffold(
      mascotState: PhoWaYokeState.happy,
      mascotMessage: OnboardingStrings.loginInstructions,
      title: OnboardingStrings.loginTab,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AuthAudioButton(audioKey: AuthAudioKeys.login),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  OnboardingStrings.readAloudButton,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.phoneLabel,
            audioKey: AuthAudioKeys.phone,
            mockTranscript: "09123456789",
            onSpeechResult: (v) =>
                setState(() => _phoneController.text = v),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixText: "MM +95",
            hintText: "09•••••••••",
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.passwordLabel,
            audioKey: AuthAudioKeys.password,
            controller: _passwordController,
            obscureText: true,
            leadingIcon: Icons.lock_outline,
            hintText: OnboardingStrings.passwordPlaceholder,
          ),
          AppErrorMessage(message: _error),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.loginButton,
        icon: Icons.login,
        loading: _isLoggingIn,
        onTap: _login,
      ),
    );
  }
}
