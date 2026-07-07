import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';

/// A suggested navigation destination for a chat action (spec §4.5). The chat
/// surfaces this as a BUTTON the user taps — the assistant never auto-jumps.
class ChatNavTarget {
  /// A `Routes.*` constant (never a raw path string).
  final String route;
  final String label;
  final IconData icon;

  /// Whether tapping should reset the stack (`context.go`) instead of pushing.
  /// Used for "find a task", which lands the tasker on their dashboard.
  final bool reset;

  /// Whether to focus the tasker's job-search field after navigating.
  final bool focusJobSearch;

  const ChatNavTarget({
    required this.route,
    required this.label,
    required this.icon,
    this.reset = false,
    this.focusJobSearch = false,
  });
}

/// The intent → `Routes.*` routing table (spec §4.5's "small routing table").
/// Maps an assistant [action] (one of `kChatActions`) + the user's [role] to a
/// destination, or null when there's nothing to navigate to (general/off_topic).
/// Role-aware where a destination differs by role (e.g. Edit Profile).
///
/// To make a new intent navigable: add a backend/mock intent + action, then a
/// case here. Nothing else in the chat UI changes.
ChatNavTarget? chatNavTargetFor(String? action, String role) {
  switch (action) {
    case 'post_task':
      return const ChatNavTarget(
        route: Routes.postTask,
        label: AppStrings.chatbotPostTaskCta,
        icon: Icons.add_circle_outline,
      );
    case 'find_task':
      return const ChatNavTarget(
        route: Routes.dashboard,
        label: AppStrings.chatbotFindTaskCta,
        icon: Icons.search,
        reset: true,
        focusJobSearch: true,
      );
    case 'find_tasker':
      return const ChatNavTarget(
        route: Routes.workerList,
        label: AppStrings.chatbotFindTaskerCta,
        icon: Icons.groups_outlined,
      );
    case 'edit_profile':
      return ChatNavTarget(
        route: role == 'tasker'
            ? Routes.taskerProfileScreen
            : Routes.clientProfileScreen,
        label: AppStrings.chatbotEditProfileCta,
        icon: Icons.person_outline,
      );
    default:
      return null;
  }
}
