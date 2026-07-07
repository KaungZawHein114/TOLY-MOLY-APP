import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/agent/agent_session.dart';
import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_service.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/field_label_with_voice.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../auth/audio/auth_audio_map.dart';
import '../auth/data/auth_failure.dart';
import '../auth/providers/auth_provider.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';
import 'widgets/voice_onboarding_sheet.dart';

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

  // Onboarding voice mode (spec §4.1/§4.6): Pho Wa Yoke listens, extracts the
  // fields, and (on the user's confirm) pre-fills them here. The user still sees
  // and edits the real form and walks the normal steps — nothing is submitted.
  Future<void> _openVoiceFill() async {
    final role = ref.read(selectedRoleProvider) ?? UserRole.client;
    ref.read(agentModeProvider.notifier).state = AgentMode.onboarding;
    ref.read(agentSessionProvider.notifier).state = AgentSession.active;

    final result = await showVoiceOnboarding(context, role: role);
    if (!mounted || result == null) return;
    _applyExtraction(result, role);
  }

  void _applyExtraction(OnboardingExtraction e, UserRole role) {
    // Refresh the two fields visible on THIS screen; gender/age/skills are
    // stored on the draft for the later steps' own initState/build to pick up.
    if (e.name.isNotEmpty) _nameController.text = e.name;
    if (e.phone.isNotEmpty) _phoneController.text = e.phone;

    if (role == UserRole.tasker) {
      final n = ref.read(taskerDraftProvider.notifier);
      n.state = n.state.copyWith(
        name: e.name.isNotEmpty ? e.name : null,
        phone: e.phone.isNotEmpty ? e.phone : null,
        gender: e.gender,
        age: e.age,
        skills: e.skills.isNotEmpty ? e.skills.toSet() : null,
      );
    } else {
      final n = ref.read(clientDraftProvider.notifier);
      n.state = n.state.copyWith(
        name: e.name.isNotEmpty ? e.name : null,
        phone: e.phone.isNotEmpty ? e.phone : null,
        gender: e.gender,
        age: e.age,
      );
    }

    setState(() {}); // reflect the updated controllers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(OnboardingStrings.voiceAppliedMessage)),
    );
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
          _VoiceFillBanner(onTap: _openVoiceFill),
          const SizedBox(height: AppSpacing.xl),
          FieldLabelWithVoice(
            label: OnboardingStrings.nameLabel,
            readAloudText: OnboardingStrings.nameLabel,
            audioKey: AuthAudioKeys.name,
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
            audioKey: AuthAudioKeys.phone,
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
            audioKey: AuthAudioKeys.password,
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

/// Indigo (AI-accent) CTA that opens the onboarding voice-fill sheet — the
/// accessibility headline: speak once instead of typing every field.
class _VoiceFillBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceFillBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.indigoGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo700.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: AppSizes.avatarSm,
                  height: AppSizes.avatarSm,
                  decoration: const BoxDecoration(
                    color: AppColors.onBrand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mic_rounded,
                      color: AppColors.indigo700, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(OnboardingStrings.voiceFillCta,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: AppColors.onBrand)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(OnboardingStrings.voiceFillCtaSubtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.onBrandMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome, color: AppColors.onBrand),
              ],
            ),
          ),
        ),
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
