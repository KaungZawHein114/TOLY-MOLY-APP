import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/demo_data.dart';
import '../../core/utils/ai_mock.dart';

// LOCAL UI STATE (Riverpod), declared in this screen file.
// Seeded with a welcome message so the screen is never empty.
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => const [
      ChatMessage(
        text: "Mingalaba! 👋 I'm your TOLY MOLY assistant. "
            "Tell me what you need — like \"I need someone to fix my sink\".",
        fromUser: false,
      ),
    ]);

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _quickPrompts = [
    "Fix my sink",
    "Clean my apartment",
    "AC not cooling",
    "Need a tutor",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Fully synchronous: append the user message + the mock reply at once.
  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final current = ref.read(chatMessagesProvider);
    final reply = chatbotReply(text); // sync, <100ms
    ref.read(chatMessagesProvider.notifier).state = [
      ...current,
      ChatMessage(text: text, fromUser: true),
      ChatMessage(text: reply, fromUser: false),
    ];
    _controller.clear();

    // Scroll to bottom on the next frame (non-async callback).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.teal,
              child: Text("🤖", style: TextStyle(fontSize: 14)),
            ),
            SizedBox(width: 8),
            Text("TOLY MOLY Assistant"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) => _Bubble(message: messages[i]),
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
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: fromUser ? AppColors.tealGradient : null,
          color: fromUser ? null : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
          border: fromUser
              ? null
              : Border.all(color: theme.dividerColor),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: fromUser
                ? Colors.white
                : theme.textTheme.bodyLarge?.color,
            height: 1.35,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final p in prompts)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(p),
                onPressed: () => onTap(p),
                side: const BorderSide(color: AppColors.teal),
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
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  hintText: "Type a message…",
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onSend(controller.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.tealGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
