import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/ai_service.dart';
import '../../features/worker/dashboard_screen.dart' show jobSearchFocusNode;
import '../../features/worker/worker_home_shell.dart' show workerTabIndexProvider;

// LOCAL UI STATE (Riverpod), declared in this screen file.
// Seeded with a welcome message so the screen is never empty on first frame.
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => const [
      ChatMessage(text: AppStrings.chatbotWelcome, fromUser: false),
    ]);

/// In-app assistant. Scoped to app/task/platform questions and able to detect
/// whether the user wants to POST a task (client) or FIND a task (tasker),
/// surfacing the matching action button under the reply.
///
/// [role] ("client" | "tasker") is passed from whichever dashboard opened it;
/// it only biases intent detection — the message is the source of truth.
class ChatbotScreen extends ConsumerStatefulWidget {
  final String role;
  const ChatbotScreen({super.key, this.role = 'client'});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  static const List<String> _quickPrompts = [
    "Fix my sink",
    "Clean my apartment",
    "Find plumbing jobs",
    "How do I post a task?",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    // Snapshot the transcript BEFORE adding the new message, for light context.
    // Only the last few turns are sent (the function also caps to 6). Chat isn't
    // persisted — an app restart starts fresh, which is fine for the demo.
    final all = ref.read(chatMessagesProvider);
    final recent = all.length > 6 ? all.sublist(all.length - 6) : all;
    final history = [
      for (final m in recent)
        {'role': m.fromUser ? 'user' : 'assistant', 'text': m.text},
    ];

    ref.read(chatMessagesProvider.notifier).state = [
      ...ref.read(chatMessagesProvider),
      ChatMessage(text: text, fromUser: true),
    ];
    _controller.clear();
    setState(() => _sending = true);
    _scrollToBottom();

    // Live Cloud Function with automatic offline-mock fallback (never throws).
    final reply = await AiService.chatAssistant(
      message: text,
      role: widget.role,
      history: history,
    );
    if (!mounted) return;

    ref.read(chatMessagesProvider.notifier).state = [
      ...ref.read(chatMessagesProvider),
      ChatMessage(text: reply.message, fromUser: false, action: reply.action),
    ];
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // Routes the inline action button under a bot message.
  void _handleAction(String action) {
    switch (action) {
      case 'post_task':
        context.push(Routes.postTask);
        break;
      case 'find_task':
        // Land the tasker on the dashboard that holds the job search bar, and
        // best-effort focus it (no-op if the field isn't on screen yet).
        ref.read(workerTabIndexProvider.notifier).state = 0;
        context.go(Routes.dashboard);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          jobSearchFocusNode.requestFocus();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.indigo700,
              child: Icon(Icons.smart_toy_outlined,
                  size: 16, color: AppColors.onBrand),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(AppStrings.chatbotTitle),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (_sending && i == messages.length) {
                  return const _TypingBubble();
                }
                return _Bubble(
                  message: messages[i],
                  onAction: _handleAction,
                );
              },
            ),
          ),
          _QuickPrompts(prompts: _quickPrompts, onTap: _send),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String> onAction;
  const _Bubble({required this.message, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUser = message.fromUser;
    final hasAction =
        !fromUser && message.action != null && kChatActions.contains(message.action);

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.indigo700 : theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(fromUser ? AppRadius.lg : 4),
                bottomRight: Radius.circular(fromUser ? 4 : AppRadius.lg),
              ),
              border: fromUser ? null : Border.all(color: theme.dividerColor),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: fromUser
                    ? AppColors.onBrand
                    : theme.textTheme.bodyLarge?.color,
                height: 1.35,
              ),
            ),
          ),
          if (hasAction) _ActionButton(action: message.action!, onTap: onAction),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String action;
  final ValueChanged<String> onTap;
  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPost = action == 'post_task';
    final label =
        isPost ? AppStrings.chatbotPostTaskCta : AppStrings.chatbotFindTaskCta;
    final icon = isPost ? Icons.add_circle_outline : Icons.search;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: isPost ? AppColors.indigo700 : AppColors.indigo500,
          foregroundColor: AppColors.onBrand,
          minimumSize: const Size(0, 48), // ≥48px touch target
        ),
        onPressed: () => onTap(action),
        icon: Icon(icon, size: AppSizes.iconMd),
        label: Text(label),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.indigo500),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppStrings.chatbotTyping,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onTap;
  const _QuickPrompts({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final p in prompts)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                label: Text(p),
                onPressed: () => onTap(p),
                side: const BorderSide(color: AppColors.indigo500),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs + 2, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  hintText: AppStrings.chatbotInputHint,
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              label: 'Send',
              button: true,
              child: GestureDetector(
                onTap: () => onSend(controller.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.indigo700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send,
                      color: AppColors.onBrand, size: AppSizes.iconMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
