import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent_session.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

/// Bottom-right floating button that opens the in-app AI assistant.
/// Shared by the client and tasker dashboards so the two stay identical.
/// Indigo per the design system's "AI / intelligence" accent.
class ChatbotFab extends StatelessWidget {
  final VoidCallback onTap;
  const ChatbotFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.indigo700,
      foregroundColor: AppColors.onBrand,
      tooltip: AppStrings.chatbotFabLabel,
      child: Semantics(
        label: AppStrings.chatbotFabLabel,
        button: true,
        child: ClipOval(
          child: Image.asset("assets/img.png", width: 40, height: 40, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// The agent's floating entry point — the [ChatbotFab] made session-aware so it
/// plugs into the shared agent shell (spec §3). It:
///   • hides entirely when the session is [AgentSession.sleep];
///   • on tap, marks the session [AgentSession.active] + mode [AgentMode.overall]
///     and runs [onTap] (opens the assistant);
///   • on long-press, puts the agent to sleep with an undoable "wake" snackbar,
///     giving a way back from [AgentSession.sleep] without a persistent handle.
///
/// Reuses [ChatbotFab] for the visual so the button looks identical everywhere.
class AgentFab extends ConsumerWidget {
  final VoidCallback onTap;
  const AgentFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(agentSessionProvider);
    // Sleep = fully hidden, no floating button (spec §3).
    if (session == AgentSession.sleep) return const SizedBox.shrink();

    return GestureDetector(
      onLongPress: () {
        ref.read(agentSessionProvider.notifier).state = AgentSession.sleep;
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text(AgentStrings.sleptMessage),
            action: SnackBarAction(
              label: AgentStrings.wakeAction,
              onPressed: () => ref.read(agentSessionProvider.notifier).state =
                  AgentSession.wakie,
            ),
          ),
        );
      },
      child: ChatbotFab(
        onTap: () {
          ref.read(agentSessionProvider.notifier).state = AgentSession.active;
          ref.read(agentModeProvider.notifier).state = AgentMode.overall;
          onTap();
        },
      ),
    );
  }
}
