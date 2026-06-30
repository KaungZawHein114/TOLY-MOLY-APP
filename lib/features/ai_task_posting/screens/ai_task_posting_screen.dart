import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../data/location_service.dart';
import '../data/task_failure.dart';
import '../models/ai_task_models.dart';
import '../providers/task_provider.dart';
import '../widgets/voice_record_button.dart';

enum _Phase { chat, location, budget, review }

const _greeting = "မင်္ဂလာပါ။ ဒီနေ့ ဘာအလုပ်တင်ချင်ပါသလဲ?";

const _budgetTierLabels = {
  "ECONOMY": "Economy",
  "STANDARD": "Standard",
  "PROFESSIONAL": "Professional",
};
const _budgetTierDescriptions = {
  "ECONOMY": "Suitable for routine and simple tasks.",
  "STANDARD": "Recommended for most household services.",
  "PROFESSIONAL": "Recommended for skilled or technical work.",
};

/// The whole AI Task Posting flow in one screen (per the spec's "minimal
/// number of screens" principle) — a conversational chat phase, then
/// location confirmation, budget tier selection, and a final editable
/// review, all as sections of the same scrolling screen rather than
/// separate routes.
class AiTaskPostingScreen extends ConsumerStatefulWidget {
  const AiTaskPostingScreen({super.key});

  @override
  ConsumerState<AiTaskPostingScreen> createState() => _AiTaskPostingScreenState();
}

class _AiTaskPostingScreenState extends ConsumerState<AiTaskPostingScreen> {
  _Phase _phase = _Phase.chat;
  final List<ChatTurn> _history = [const ChatTurn(role: "assistant", content: _greeting)];
  Map<String, dynamic> _knownFields = {"urgency": "NORMAL"};
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSending = false;
  bool _isTranscribing = false;
  String? _chatError;

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationError;

  Map<String, BudgetOption>? _budgetOptions;
  String? _selectedBudgetTier;
  bool _isLoadingBudget = false;
  String? _budgetError;

  bool _isPublishing = false;
  String? _publishError;

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _chatError = null;
    });
    try {
      final result = await ref.read(taskRepositoryProvider).analyze(
            message: trimmed,
            history: _history,
            knownFields: _knownFields,
          );
      setState(() {
        _history.add(ChatTurn(role: "user", content: trimmed));
        _knownFields = result.fields;
        if (result.question != null) {
          _history.add(ChatTurn(role: "assistant", content: result.question!));
        }
      });
      _messageController.clear();
      _scrollChatToBottom();
      if (result.ready) {
        await _enterLocationPhase();
      }
    } on TaskFailure catch (e) {
      setState(() => _chatError = e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _onVoiceRecorded(List<int> bytes) async {
    setState(() {
      _isTranscribing = true;
      _chatError = null;
    });
    try {
      final text = await ref.read(taskRepositoryProvider).transcribeAudio(bytes);
      if (!mounted) return;
      setState(() => _isTranscribing = false);
      await _sendMessage(text);
    } on TaskFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _chatError = e.message;
      });
    }
  }

  Future<void> _enterLocationPhase() async {
    setState(() => _phase = _Phase.location);
    await _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final result = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    } on LocationUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _confirmLocation() async {
    setState(() => _phase = _Phase.budget);
    setState(() => _isLoadingBudget = true);
    try {
      final options = await ref.read(taskRepositoryProvider).budgetOptions(
            category: _knownFields["category"] as String,
            urgency: _knownFields["urgency"] as String? ?? "NORMAL",
          );
      if (!mounted) return;
      setState(() => _budgetOptions = options);
    } on TaskFailure catch (e) {
      if (!mounted) return;
      setState(() => _budgetError = e.message);
    } finally {
      if (mounted) setState(() => _isLoadingBudget = false);
    }
  }

  void _selectBudgetTier(String tier) {
    setState(() {
      _selectedBudgetTier = tier;
      _phase = _Phase.review;
    });
  }

  Future<void> _publish() async {
    if (_isPublishing || _selectedBudgetTier == null || _budgetOptions == null) return;
    final option = _budgetOptions![_selectedBudgetTier]!;
    setState(() {
      _isPublishing = true;
      _publishError = null;
    });
    try {
      await ref.read(taskRepositoryProvider).publish({
        "category": _knownFields["category"],
        "title": _knownFields["title"],
        "description": "",
        "date": _knownFields["date"],
        "time": _knownFields["time"],
        "latitude": _latitude,
        "longitude": _longitude,
        "urgency": _knownFields["urgency"] ?? "NORMAL",
        "budget_tier": _selectedBudgetTier,
        "worker_tier_min": option.workerTierMin,
        "worker_tier_max": option.workerTierMax,
        "budget_mmk": option.budgetMmk,
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("🎉 Your task has been published successfully."),
          content: const Text("Taskers nearby can now see it on the task board and express interest."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go("/customer/home");
              },
              child: const Text("Done"),
            ),
          ],
        ),
      );
    } on TaskFailure catch (e) {
      if (!mounted) return;
      setState(() => _publishError = e.message);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _editTextField(String key, String label) async {
    final controller = TextEditingController(text: _knownFields[key]?.toString() ?? "");
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $label"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text("Save")),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _knownFields = {..._knownFields, key: result});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Task Assistant"),
        actions: [ReadAloudButton(textToRead: _history.last.content)],
      ),
      body: switch (_phase) {
        _Phase.chat => _buildChatPhase(),
        _Phase.location => _buildLocationPhase(),
        _Phase.budget => _buildBudgetPhase(),
        _Phase.review => _buildReviewPhase(),
      },
    );
  }

  Widget _buildChatPhase() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _history.length,
            itemBuilder: (context, i) => _ChatBubble(turn: _history[i]),
          ),
        ),
        if (_chatError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(_chatError!, style: const TextStyle(color: AppColors.error)),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_isSending && !_isTranscribing,
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    filled: true,
                    fillColor: AppColors.blue100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              VoiceRecordButton(onRecorded: _onVoiceRecorded),
              const SizedBox(width: AppSpacing.sm),
              (_isSending || _isTranscribing)
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppColors.purple700),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPhase() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, size: 64, color: AppColors.purple700),
          const SizedBox(height: AppSpacing.lg),
          if (_isLocating)
            const CircularProgressIndicator()
          else if (_locationError != null) ...[
            Text(_locationError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.lg),
            LargeButton(label: "Try Again", onTap: _detectLocation, gradient: AppColors.purpleGradient),
          ] else if (_latitude != null) ...[
            const Text("I found your current location. Would you like to use this location?"),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            LargeButton(label: "Confirm", onTap: _confirmLocation, gradient: AppColors.purpleGradient),
            const SizedBox(height: AppSpacing.md),
            LargeButton(
              label: "Change Location",
              filled: false,
              outlineColor: AppColors.purple700,
              onTap: _detectLocation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetPhase() {
    if (_isLoadingBudget) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_budgetError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(_budgetError!, style: const TextStyle(color: AppColors.error)),
        ),
      );
    }
    final options = _budgetOptions;
    if (options == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text("Choose the service level for your task", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.lg),
        for (final tier in ["ECONOMY", "STANDARD", "PROFESSIONAL"])
          if (options[tier] != null) _BudgetTierCard(
            label: _budgetTierLabels[tier]!,
            description: _budgetTierDescriptions[tier]!,
            budgetMmk: options[tier]!.budgetMmk,
            onTap: () => _selectBudgetTier(tier),
          ),
      ],
    );
  }

  Widget _buildReviewPhase() {
    final option = _selectedBudgetTier == null ? null : _budgetOptions?[_selectedBudgetTier];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text("Review your task", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: AppSpacing.lg),
        _ReviewRow(label: "Category", value: "${_knownFields["category"]}", onEdit: () => _editTextField("category", "Category")),
        _ReviewRow(label: "Title", value: "${_knownFields["title"]}", onEdit: () => _editTextField("title", "Title")),
        _ReviewRow(label: "Date", value: "${_knownFields["date"]}", onEdit: () => _editTextField("date", "Date")),
        _ReviewRow(label: "Time", value: "${_knownFields["time"]}", onEdit: () => _editTextField("time", "Time")),
        _ReviewRow(
          label: "Location",
          value: _latitude == null ? "-" : "${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}",
          onEdit: _enterLocationPhase,
        ),
        _ReviewRow(
          label: "Urgent",
          value: _knownFields["urgency"] == "URGENT" ? "Yes" : "No",
          onEdit: () => setState(() {
            _knownFields = {
              ..._knownFields,
              "urgency": _knownFields["urgency"] == "URGENT" ? "NORMAL" : "URGENT",
            };
          }),
        ),
        _ReviewRow(
          label: "Service Level",
          value: _selectedBudgetTier == null ? "-" : _budgetTierLabels[_selectedBudgetTier]!,
          onEdit: () => setState(() => _phase = _Phase.budget),
        ),
        _ReviewRow(
          label: "Initial Budget",
          value: option == null ? "-" : "${option.budgetMmk} MMK",
          onEdit: () => setState(() => _phase = _Phase.budget),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_publishError != null) ...[
          Text(_publishError!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: AppSpacing.md),
        ],
        LargeButton(
          label: _isPublishing ? "Publishing..." : "Publish Task",
          icon: _isPublishing ? null : Icons.check_circle_outline,
          gradient: AppColors.purpleGradient,
          celebratory: true,
          onTap: _publish,
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatTurn turn;
  const _ChatBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isAssistant = turn.role == "assistant";
    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAssistant ? AppColors.blue100 : AppColors.purple700,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(turn.content, style: TextStyle(color: isAssistant ? AppColors.textPrimary : AppColors.onBrand)),
      ),
    );
  }
}

class _BudgetTierCard extends StatelessWidget {
  final String label;
  final String description;
  final int budgetMmk;
  final VoidCallback onTap;

  const _BudgetTierCard({
    required this.label,
    required this.description,
    required this.budgetMmk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(description, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text("$budgetMmk MMK", style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ReviewRow({required this.label, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text("Edit")),
        ],
      ),
    );
  }
}
