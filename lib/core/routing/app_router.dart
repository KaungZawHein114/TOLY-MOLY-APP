import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/splash_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/customer/home_screen.dart';
import '../../features/customer/worker_list_screen.dart';
import '../../features/customer/worker_profile_screen.dart';
import '../../features/customer/booking_screen.dart';
import '../../features/worker/onboarding_screen.dart';
import '../../features/worker/dashboard_screen.dart';
import '../../features/chatbot/chatbot_screen.dart';
import '../data/demo_data.dart';

/// Centralized route names, grouped by feature so each group can grow
/// independently. Screens reference these constants — never raw path strings.
class Routes {
  Routes._();

  // ── auth ────────────────────────────────────────────────────────────────
  static const String splash = '/auth/splash';
  static const String role = '/auth/role';

  // ── customer ────────────────────────────────────────────────────────────
  static const String customerHome = '/customer/home';
  static const String workerList = '/customer/workers';
  static const String workerProfile = '/customer/worker'; // + /:id
  static const String booking = '/customer/booking'; // + /:id

  // ── worker ──────────────────────────────────────────────────────────────
  static const String onboarding = '/worker/onboarding';
  static const String dashboard = '/worker/dashboard';

  // ── chatbot ─────────────────────────────────────────────────────────────
  static const String chatbot = '/chatbot';
}

// ============================================================================
// FEATURE ROUTE GROUPS
// To add a screen: drop it in the right group list below. Nothing else changes.
// ============================================================================

final List<RouteBase> _authRoutes = [
  GoRoute(
    path: Routes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: Routes.role,
    builder: (context, state) => const RoleSelectionScreen(),
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
    path: Routes.onboarding,
    builder: (context, state) => const WorkerOnboardingScreen(),
  ),
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
/// FAIL-SAFE: any unknown / errored route renders RoleSelectionScreen (still
/// wrapped in the back-handler) instead of a blank screen or an app exit.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  errorBuilder: (context, state) =>
      const _RootBackHandler(child: RoleSelectionScreen()),
  routes: [
    ShellRoute(
      builder: (context, state, child) => _RootBackHandler(child: child),
      routes: [
        ..._authRoutes,
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
//   Splash           ignored (swallowed) — prevents exit mid-launch
//   Stack root       "Exit app?" confirmation dialog (e.g. Role Selection)
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
    final location = router.routeInformationProvider.value.uri.path;

    // Splash: swallow back entirely (it auto-advances in 1.5s anyway).
    if (location == Routes.splash) return;

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
