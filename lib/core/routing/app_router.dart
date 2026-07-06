import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/customer/customer_home_shell.dart';
import '../../features/customer/task_posting/ai_category_screen.dart';
import '../../features/customer/task_posting/budget_screen.dart';
import '../../features/customer/task_posting/date_time_screen.dart';
import '../../features/customer/task_posting/review_publish_screen.dart';
import '../../features/customer/task_posting/task_description_screen.dart';
import '../../features/customer/task_posting/task_type_location_screen.dart';
import '../../features/customer/task_posting/workers_tier_urgency_screen.dart';
import '../../features/customer/worker_list_screen.dart';
import '../../features/customer/worker_profile_screen.dart';
import '../../features/customer/client_profile_screen.dart';
import '../../features/customer/booking_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/create_account_screen.dart';
import '../../features/onboarding/basic_info_screen.dart';
import '../../features/onboarding/client/client_personal_info_screen.dart';
import '../../features/onboarding/client/client_phone_verification_screen.dart';
import '../../features/onboarding/client/client_rules_screen.dart';
import '../../features/onboarding/client/client_welcome_screen.dart';
import '../../features/onboarding/tasker/tasker_personal_info_screen.dart';
import '../../features/onboarding/tasker/tasker_phone_verification_screen.dart';
import '../../features/onboarding/tasker/tasker_skills_screen.dart';
import '../../features/onboarding/tasker/tasker_rules_screen.dart';
import '../../features/onboarding/tasker/tasker_welcome_screen.dart';
import '../../features/worker/worker_home_shell.dart';
import '../../features/worker/tasker_profile_screen.dart';
import '../../features/worker/task_execution_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../../features/ai_task_posting/screens/ai_task_posting_screen.dart';
import '../../features/voice_task_posting/screens/voice_task_intro_screen.dart';
import '../../features/voice_task_posting/screens/voice_task_review_screen.dart';
import '../data/demo_data.dart';
import '../theme/app_spacing.dart';
import '../../features/customer/activity_screen.dart';

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
  static const String clientRules = '/onboarding/client/rules';
  static const String clientWelcome = '/onboarding/client/welcome';
  static const String taskerPersonal = '/onboarding/tasker/personal';
  static const String taskerPhone = '/onboarding/tasker/phone';
  static const String taskerSkills = '/onboarding/tasker/skills';
  static const String taskerRules = '/onboarding/tasker/rules';
  static const String taskerWelcome = '/onboarding/tasker/welcome';

  // ── customer ────────────────────────────────────────────────────────────
  static const String customerHome = '/customer/home';
  static const String postTask = '/customer/post-task';
  static const String aiTaskPosting = '/customer/post-task/ai';
  static const String voiceTaskPosting = '/customer/post-task/voice';
  static const String voiceTaskReview = '/customer/post-task/voice/review';
  static const String postTaskTypeLocation = '/customer/post-task/type-location';
  static const String postTaskDateTime = '/customer/post-task/date-time';
  static const String postTaskWorkersTier = '/customer/post-task/workers-tier';
  static const String postTaskDescription = '/customer/post-task/description';
  static const String postTaskBudget = '/customer/post-task/budget';
  static const String postTaskReview = '/customer/post-task/review';
  static const String workerList = '/customer/workers';
  static const String workerProfile = '/customer/worker'; // + /:id
  static const String clientProfileScreen = '/customer/profile'; // own profile
  static const String booking = '/customer/booking'; // + /:id

  // ── worker ──────────────────────────────────────────────────────────────
  static const String dashboard = '/worker/dashboard';
  static const String taskerProfileScreen = '/worker/profile'; // own profile
  static const String taskExecution = '/worker/task-execution'; // + /:id

  // ── chatbot ─────────────────────────────────────────────────────────────
  static const String chatbot = '/chatbot';

  static const String activity = '/customer/activity';
}



// ============================================================================
// FEATURE ROUTE GROUPS
// To add a screen: drop it in the right group list below. Nothing else changes.
// ============================================================================

/// Combined fade + subtle slide-up used for the redesigned onboarding screens
/// and the task-posting flow, instead of the platform-default horizontal
/// slide — used only by routes that opt in via `pageBuilder`.
// NOTE: keyed with `state.pageKey` (unique per stack entry), NOT the static
// route path. The task-posting "Edit" links re-push a route that is already in
// the back stack (e.g. editing Screen 2 from the Screen 7 review), so a
// path-derived key would collide with the existing page and crash the
// Navigator with a duplicate-key error.
Page<void> _onboardingTransitionPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
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
      key: state.pageKey,
      child: const WelcomeScreen(),
    ),
  ),
  GoRoute(
    path: Routes.onboardingCreateAccount,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const CreateAccountScreen(),
    ),
  ),
  GoRoute(
    path: Routes.onboardingBasicInfo,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
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
    path: Routes.taskerRules,
    builder: (context, state) => const TaskerRulesScreen(),
  ),
  GoRoute(
    path: Routes.taskerWelcome,
    builder: (context, state) => const TaskerWelcomeScreen(),
  ),
  GoRoute(
    path: Routes.activity,
    builder: (context, state) => const ActivityScreen(),
  ),
];

final List<RouteBase> _customerRoutes = [
  GoRoute(
    path: Routes.customerHome,
    builder: (context, state) => const CustomerHomeShell(),
  ),
  GoRoute(
    path: Routes.postTask,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const AiCategoryScreen(),
    ),
  ),
  GoRoute(
    path: Routes.aiTaskPosting,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const AiTaskPostingScreen(),
    ),
  ),
  GoRoute(
    path: Routes.voiceTaskPosting,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const VoiceTaskIntroScreen(),
    ),
  ),
  GoRoute(
    path: Routes.voiceTaskReview,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const VoiceTaskReviewScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskTypeLocation,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const TaskTypeLocationScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskDateTime,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const DateTimeScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskWorkersTier,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const WorkersTierUrgencyScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskDescription,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const TaskDescriptionScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskBudget,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const BudgetScreen(),
    ),
  ),
  GoRoute(
    path: Routes.postTaskReview,
    pageBuilder: (context, state) => _onboardingTransitionPage(
      key: state.pageKey,
      child: const ReviewPublishScreen(),
    ),
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
  // The client's OWN profile. Primarily rendered as a tab inside
  // CustomerHomeShell; this route lets other flows deep-link straight to it.
  GoRoute(
    path: Routes.clientProfileScreen,
    builder: (context, state) => const ClientProfileScreen(),
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
    builder: (context, state) => const WorkerHomeShell(),
  ),
  // The tasker's OWN profile. Primarily rendered as a tab inside
  // WorkerHomeShell; this route lets other flows deep-link straight to it.
  GoRoute(
    path: Routes.taskerProfileScreen,
    builder: (context, state) => const TaskerProfileScreen(),
  ),
  GoRoute(
    path: '${Routes.taskExecution}/:id',
    builder: (context, state) =>
        TaskExecutionScreen(booking: _findBooking(state.pathParameters['id'])),
  ),
];

final List<RouteBase> _chatbotRoutes = [
  GoRoute(
    path: Routes.chatbot,
    builder: (context, state) {
      // Optional ?role=client|tasker hint from whichever dashboard opened it.
      final role = state.uri.queryParameters['role'] == 'tasker'
          ? 'tasker'
          : 'client';
      return ChatbotScreen(role: role);
    },
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

/// Always returns a valid Booking — falls back to the first booking if the
/// id is missing or not found (this app has no fallbackBooking; bookings
/// is never empty in Phase 1 demo data).
Booking _findBooking(String? rawId) {
  final id = int.tryParse(rawId ?? '');
  if (id != null) {
    for (final b in bookings) {
      if (b.id == id) return b;
    }
  }
  return bookings.first;
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
