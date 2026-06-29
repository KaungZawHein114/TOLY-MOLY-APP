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
import '../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../core/widgets/onboarding/read_aloud_button.dart';
import '../auth/data/auth_failure.dart';
import '../auth/providers/auth_provider.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

// LOCAL UI STATE for this screen only (which tab is active). Draft data
// itself lives in the shared onboarding_state.dart providers.
final _isLoginTabProvider = StateProvider<bool>((ref) => false);

/// Step 1 of signup: choose the create-account/login tab, then (for signup)
/// pick a role. Name/phone/password collection happens on [BasicInfoScreen].
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  String? _roleError;
  String? _loginError;
  bool _obscureLoginPassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    ref.read(selectedRoleProvider.notifier).state = role;
    setState(() => _roleError = null);
  }

  void _continue() {
    final role = ref.read(selectedRoleProvider);
    setState(() {
      _roleError = role == null ? OnboardingStrings.roleRequiredError : null;
    });
    if (role == null) return;
    context.push(Routes.onboardingBasicInfo);
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;
    final filled = phone.isNotEmpty && password.isNotEmpty;
    setState(() {
      _loginError = filled ? null : OnboardingStrings.loginFieldsRequiredError;
    });
    if (!filled) return;

    setState(() => _isLoggingIn = true);
    try {
      final session = await ref.read(authRepositoryProvider).login(
            phoneNumber: phone,
            password: password,
          );
      if (!mounted) return;
      context.go(session.user.role == "CLIENT" ? Routes.customerHome : Routes.dashboard);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _loginError = e.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLogin = ref.watch(_isLoginTabProvider);
    final role = ref.watch(selectedRoleProvider);

    return OnboardingScaffold(
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.chooseRolePromptV2,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          _TabToggle(
            isLogin: isLogin,
            onChanged: (v) => ref.read(_isLoginTabProvider.notifier).state = v,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isLogin) ..._loginFields(theme) else ..._roleFields(theme, role),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(OnboardingStrings.orDivider,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ),
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LargeButton(
            label: OnboardingStrings.googleSignup,
            icon: Icons.g_mobiledata,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(OnboardingStrings.googleNotSupported)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: isLogin
          ? LargeButton(
              label: _isLoggingIn ? OnboardingStrings.submittingLabel : OnboardingStrings.loginButton,
              icon: _isLoggingIn ? null : Icons.login,
              gradient: AppColors.purpleGradient,
              onTap: _login,
            )
          : LargeButton(
              label: OnboardingStrings.continueButton,
              icon: Icons.arrow_forward,
              gradient: AppColors.purpleGradient,
              onTap: _continue,
            ),
    );
  }

  List<Widget> _roleFields(ThemeData theme, UserRole? role) {
    return [
      Row(
        children: [
          ReadAloudButton(textToRead: OnboardingStrings.signupInstructions),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              OnboardingStrings.readAloudButton,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(OnboardingStrings.chooseRolePrompt, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: OnboardingSelectionCard(
              emoji: "💼",
              label: OnboardingStrings.roleClientLabel,
              sublabel: OnboardingStrings.roleClientSublabel,
              selected: role == UserRole.client,
              onTap: () => _selectRole(UserRole.client),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OnboardingSelectionCard(
              emoji: "🙂",
              label: OnboardingStrings.roleTaskerLabel,
              sublabel: OnboardingStrings.roleTaskerSublabel,
              selected: role == UserRole.tasker,
              onTap: () => _selectRole(UserRole.tasker),
            ),
          ),
        ],
      ),
      if (_roleError != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(_roleError!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
      ],
    ];
  }

  List<Widget> _loginFields(ThemeData theme) {
    return [
      Row(
        children: [
          ReadAloudButton(textToRead: OnboardingStrings.loginInstructions),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              OnboardingStrings.readAloudButton,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(OnboardingStrings.phoneLabel, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _loginPhoneController,
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
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          border: _fieldBorder(),
          enabledBorder: _fieldBorder(),
          focusedBorder: _fieldBorder(focused: true),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(OnboardingStrings.passwordLabel, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _loginPasswordController,
        obscureText: _obscureLoginPassword,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: OnboardingStrings.passwordPlaceholder,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          border: _fieldBorder(),
          enabledBorder: _fieldBorder(),
          focusedBorder: _fieldBorder(focused: true),
          suffixIcon: Semantics(
            label: _obscureLoginPassword
                ? OnboardingStrings.showPasswordLabel
                : OnboardingStrings.hidePasswordLabel,
            button: true,
            child: IconButton(
              icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
          ),
        ),
      ),
      if (_loginError != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(_loginError!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
      ],
    ];
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
