import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/customer/home_screen.dart';
import '../../features/customer/worker_list_screen.dart';
import '../../features/customer/worker_profile_screen.dart';
import '../../features/customer/booking_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/create_account_screen.dart';
import '../../features/onboarding/basic_info_screen.dart';
import '../../features/onboarding/client/client_personal_info_screen.dart';
import '../../features/onboarding/client/client_phone_verification_screen.dart';
import '../../features/onboarding/client/client_basic_profile_screen.dart';
import '../../features/onboarding/client/client_rules_screen.dart';
import '../../features/onboarding/client/client_welcome_screen.dart';
import '../../features/onboarding/tasker/tasker_personal_info_screen.dart';
import '../../features/onboarding/tasker/tasker_phone_verification_screen.dart';
import '../../features/onboarding/tasker/tasker_skills_screen.dart';
import '../../features/onboarding/tasker/tasker_basic_profile_screen.dart';
import '../../features/onboarding/tasker/tasker_rules_screen.dart';
import '../../features/onboarding/tasker/tasker_welcome_screen.dart';
import '../../features/worker/dashboard_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../data/demo_data.dart';
import '../theme/app_spacing.dart';

/// Centralized route names, grouped by feature so each group can grow
/// independently. Screens reference these constants — never raw path strings.
class Routes {
  Routes._();

  // ── onboarding ──────────────────────────────────────────────────────────
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingCreateAccount = '/onboarding/create-account';
  static const String onboardingBasicInfo = '/onboarding/basic-info';
  static const String clientPersonal = '/onboarding/client/personal';
  static const String clientPhone = '/onboarding/client/phone';
  static const String clientProfile = '/onboarding/client/profile';
  static const String clientRules = '/onboarding/client/rules';
  static const String clientWelcome = '/onboarding/client/welcome';
  static const String taskerPersonal = '/onboarding/tasker/personal';
  static const String taskerPhone = '/onboarding/tasker/phone';
  static const String taskerSkills = '/onboarding/tasker/skills';
  static const String taskerProfile = '/onboarding/tasker/profile';
  static const String taskerRules = '/onboarding/tasker/rules';
  static const String taskerWelcome = '/onboarding/tasker/welcome';

  // ── customer ────────────────────────────────────────────────────────────
  static const String customerHome = '/customer/home';
  static const String workerList = '/customer/workers';
  static const String workerProfile = '/customer/worker'; // + /:id
  static const String booking = '/customer/booking'; // + /:id

  // ── worker ──────────────────────────────────────────────────────────────
  static const String dashboard = '/worker/dashboard';

  // ── chatbot ─────────────────────────────────────────────────────────────
  static const String chatbot = '/chatbot';
}

// ============================================================================
// FEATURE ROUTE GROUPS
// To add a screen: drop it in the right group list below. Nothing else changes.
// ============================================================================

/// Combined fade + subtle slide-up used for the redesigned onboarding screens,
/// instead of the platform-default horizontal slide — used only by the
/// routes in [_onboardingRoutes] that opt in via `pageBuilder`.
Page<void> _onboardingTransitionPage({required String path, required Widget child}) {
  return CustomTransitionPage<void>(
    key: ValueKey(path),
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, transitionChild) {
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      return FadeTransition(
        opacity: curved,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: transitionChild,
        ),
      );
    },
  );
}

final List<RouteBase> _onboardingRoutes = [
  GoRoute(
    path: Routes.onboardingWelcome,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingWelcome,
      child: const WelcomeScreen(),
    ),
  ),
  GoRoute(
    path: Routes.onboardingCreateAccount,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingCreateAccount,
      child: const CreateAccountScreen(),
    ),
  ),
  GoRoute(
    path: Routes.onboardingBasicInfo,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      path: Routes.onboardingBasicInfo,
      child: const BasicInfoScreen(),
    ),
  ),
  GoRoute(
    path: Routes.clientPersonal,
    builder: (context, state) => const ClientPersonalInfoScreen(),
  ),
  GoRoute(
    path: Routes.clientPhone,
    builder: (context, state) => const ClientPhoneVerificationScreen(),
  ),
  GoRoute(
    path: Routes.clientProfile,
    builder: (context, state) => const ClientBasicProfileScreen(),
  ),
  GoRoute(
    path: Routes.clientRules,
    builder: (context, state) => const ClientRulesScreen(),
  ),
  GoRoute(
    path: Routes.clientWelcome,
    builder: (context, state) => const ClientWelcomeScreen(),
  ),
  GoRoute(
    path: Routes.taskerPersonal,
    builder: (context, state) => const TaskerPersonalInfoScreen(),
  ),
  GoRoute(
    path: Routes.taskerPhone,
    builder: (context, state) => const TaskerPhoneVerificationScreen(),
  ),
  GoRoute(
    path: Routes.taskerSkills,
    builder: (context, state) => const TaskerSkillsScreen(),
  ),
  GoRoute(
    path: Routes.taskerProfile,
    builder: (context, state) => const TaskerBasicProfileScreen(),
  ),
  GoRoute(
    path: Routes.taskerRules,
    builder: (context, state) => const TaskerRulesScreen(),
  ),
  GoRoute(
    path: Routes.taskerWelcome,
    builder: (context, state) => const TaskerWelcomeScreen(),
  ),
];

final List<RouteBase> _customerRoutes = [
  GoRoute(
    path: Routes.customerHome,
    builder: (context, state) => const CustomerHomeScreen(),
  ),
  GoRoute(
    path: Routes.workerList,
    builder: (context, state) {
      // Optional ?skill= filter from a tapped category. Missing -> all.
      final skill = state.uri.queryParameters['skill'];
      return WorkerListScreen(initialSkill: skill);
    },
  ),
  GoRoute(
    path: '${Routes.workerProfile}/:id',
    builder: (context, state) =>
        WorkerProfileScreen(worker: _findWorker(state.pathParameters['id'])),
  ),
  GoRoute(
    path: '${Routes.booking}/:id',
    builder: (context, state) =>
        BookingScreen(worker: _findWorker(state.pathParameters['id'])),
  ),
];

final List<RouteBase> _workerRoutes = [
  GoRoute(
    path: Routes.dashboard,
    builder: (context, state) => const WorkerDashboardScreen(),
  ),
];

final List<RouteBase> _chatbotRoutes = [
  GoRoute(
    path: Routes.chatbot,
    builder: (context, state) => const ChatbotScreen(),
  ),
];

/// GoRouter is the single source of navigation truth.
///
/// All feature routes live inside ONE [ShellRoute] whose builder wraps every
/// screen in [_RootBackHandler]. That gives us a single, centralized place to
/// govern the Android system back button (see the behaviour table there).
///
/// FAIL-SAFE: any unknown / errored route renders the onboarding WelcomeScreen
/// (still wrapped in the back-handler) instead of a blank screen or app exit.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.onboardingWelcome,
  errorBuilder: (context, state) =>
      const _RootBackHandler(child: WelcomeScreen()),
  routes: [
    ShellRoute(
      builder: (context, state, child) => _RootBackHandler(child: child),
      routes: [
        ..._onboardingRoutes,
        ..._customerRoutes,
        ..._workerRoutes,
        ..._chatbotRoutes,
      ],
    ),
  ],
);

/// Always returns a valid Worker — falls back to the first worker (or the
/// hardcoded fallbackWorker) if the id is missing or not found.
Worker _findWorker(String? rawId) {
  final id = int.tryParse(rawId ?? '');
  if (id != null) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
  }
  return workers.isNotEmpty ? workers.first : fallbackWorker;
}

// ============================================================================
// CENTRALIZED ANDROID BACK-BUTTON CONTROL
// ----------------------------------------------------------------------------
// Wraps the whole app once. No screen overrides the back button itself.
//
//   Screen type      Back button behaviour
//   ───────────────  ───────────────────────────────────────────────
//   Stack root       "Exit app?" confirmation dialog (e.g. onboarding Welcome)
//   Any other screen normal back navigation (pops the stack)
// ============================================================================
class _RootBackHandler extends StatelessWidget {
  final Widget child;
  const _RootBackHandler({required this.child});

  @override
  Widget build(BuildContext context) {
    // canPop:false => the system back never auto-closes the app; we decide.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: child,
    );
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);

    // Mid-stack: normal back navigation.
    if (router.canPop()) {
      router.pop();
      return;
    }

    // Stack root (Role Selection or any reset root): guard the exit.
    _confirmExit(context);
  }
}

bool _exitDialogVisible = false;

void _confirmExit(BuildContext context) {
  if (_exitDialogVisible) return;
  _exitDialogVisible = true;
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Exit TOLY MOLY?"),
      content: const Text("Are you sure you want to close the app?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Stay"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text("Exit"),
        ),
      ],
    ),
  ).then((shouldExit) {
    _exitDialogVisible = false;
    if (shouldExit == true) {
      SystemNavigator.pop(); // closes the app on Android, no-op-ish on iOS
    }
  });
}
