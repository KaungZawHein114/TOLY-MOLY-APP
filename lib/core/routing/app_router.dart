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

/// Centralized route names so screens never hardcode path strings.
class Routes {
  Routes._();
  static const String splash = '/';
  static const String role = '/role';
  static const String customerHome = '/customer/home';
  static const String workerList = '/customer/workers';
  static const String workerProfile = '/customer/worker'; // + /:id
  static const String booking = '/customer/booking'; // + /:id
  static const String onboarding = '/worker/onboarding';
  static const String dashboard = '/worker/dashboard';
  static const String chatbot = '/chatbot';
}

/// GoRouter is the single source of navigation truth.
/// FAIL-SAFE: any unknown / errored route renders RoleSelectionScreen instead
/// of a blank screen.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  errorBuilder: (context, state) => const RoleSelectionScreen(),
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.role,
      builder: (context, state) => const RoleSelectionScreen(),
    ),
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
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final worker = _findWorker(id);
        return WorkerProfileScreen(worker: worker);
      },
    ),
    GoRoute(
      path: '${Routes.booking}/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        final worker = _findWorker(id);
        return BookingScreen(worker: worker);
      },
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const WorkerOnboardingScreen(),
    ),
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) => const WorkerDashboardScreen(),
    ),
    GoRoute(
      path: Routes.chatbot,
      builder: (context, state) => const ChatbotScreen(),
    ),
  ],
);

/// Always returns a valid Worker — falls back to the first worker (or the
/// hardcoded fallbackWorker) if the id is missing or not found.
Worker _findWorker(int? id) {
  if (id != null) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
  }
  return workers.isNotEmpty ? workers.first : fallbackWorker;
}
