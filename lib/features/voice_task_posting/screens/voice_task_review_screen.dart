import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_message_card.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../data/voice_task_api.dart';
import '../models/extracted_task.dart';
import '../voice_task_state.dart';

// Category vocabulary — mirrors CANONICAL_CATEGORIES in the backend
// (apps/tasks/services.py) so a picked value always lines up server-side.
const _kCategories = [
  'Plumber',
  'Electrician',
  'Cleaner',
  'Carpenter',
  'AC Technician',
  'Tutor',
  'Handyman',
  'Gardener',
  'Delivery',
];

// Demo-only fixed location (Yangon, Sule Pagoda) — the voice flow never asks
// for GPS permission; it publishes this coordinate, same decision the
// ai_task_posting flow made. The spoken township is stored as the address.
const _demoLatitude = 16.7745;
const _demoLongitude = 96.1591;

// Voice flow doesn't ask the client to reason about worker tiers/budget tiers,
// so publish uses the middle band. budget_tier is required server-side.
const _kDefaultBudgetTier = 'STANDARD';
const _kDefaultWorkerTierMin = 4;
const _kDefaultWorkerTierMax = 5;

const _kAppBarTitle = 'အလုပ်အချက်အလက် စစ်ဆေးရန်';
const _kMascotMsg =
    'အချက်အလက်တွေ မှန်ကန်ရဲ့လား ကြည့်ပါ။ "မဖြည့်ရသေးပါ" တွေကို နှိပ်ပြီး ကိုယ်တိုင် ဖြည့်နိုင်ပါတယ်။';
const _kNotGiven = 'မဖြည့်ရသေးပါ';
const _kEdit = 'ပြင်ရန်';
const _kFill = 'ဖြည့်ရန်';
const _kPublish = 'အလုပ်တင်မည်';
const _kPublishing = 'တင်နေသည်…';
const _kSave = 'သိမ်းမည်';
const _kCancel = 'မလုပ်တော့ပါ';
const _kDone = 'ပြီးပါပြီ';

const _kTitle = 'ခေါင်းစဉ်';
const _kCategory = 'ဝန်ဆောင်မှုအမျိုးအစား';
const _kDescription = 'အသေးစိတ်';
const _kDate = 'ရက်စွဲ';
const _kTime = 'အချိန်';
const _kUrgent = 'အရေးပေါ်';
const _kBudget = 'ကျသင့်ငွေ (ကျပ်)';
const _kLocation = 'တည်နေရာ';

const _kUrgentYes = 'ဟုတ်ကဲ့ (အရေးပေါ်)';
const _kUrgentNo = 'မဟုတ်ပါ';

const _kSuccessTitle = 'အလုပ်တင်ပြီးပါပြီ';
const _kSuccessMsg = 'အနီးအနားက အလုပ်သမားများ ယခု မြင်တွေ့နိုင်ပါပြီ။';
const _kFillFirst = 'ကျေးဇူးပြု၍ ဤအချက်အလက်များကို အရင်ဖြည့်ပါ —';

/// Step 2 of the voice flow: review + fill + publish. Reads the AI-extracted
/// [ExtractedTask] from [voiceDraftProvider]; every field is editable, and
/// anything the AI couldn't hear shows "Not given" until the client fills it.
/// Publishing POSTs a real Task to the backend (same endpoint as the other
/// flows), so it lands in Postgres and shows on the tasker board.
class VoiceTaskReviewScreen extends ConsumerStatefulWidget {
  const VoiceTaskReviewScreen({super.key});

  @override
  ConsumerState<VoiceTaskReviewScreen> createState() =>
      _VoiceTaskReviewScreenState();
}

class _VoiceTaskReviewScreenState extends ConsumerState<VoiceTaskReviewScreen> {
  bool _isPublishing = false;
  String? _publishError;

  // ── field editors — each writes straight back to the shared draft ────────
  void _update(ExtractedTask Function(ExtractedTask) change) {
    ref.read(voiceDraftProvider.notifier).update(change);
  }

  Future<void> _editText(
    String label,
    String? current,
    void Function(String) onSave, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text(_kCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text(_kSave)),
        ],
      ),
    );
    if (result != null) onSave(result);
  }

  Future<void> _pickCategory(String? current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(_kCategory),
        children: [
          for (final c in _kCategories)
            ListTile(
              title: Text(c),
              trailing: c == current
                  ? const Icon(Icons.check, color: AppColors.purple700)
                  : null,
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    );
    if (selected != null) _update((d) => d.copyWith(category: selected));
  }

  Future<void> _pickDate(String? current) async {
    final now = DateTime.now();
    final parsed = _parseDate(current);
    final initial = (parsed == null || parsed.isBefore(now)) ? now : parsed;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) _update((d) => d.copyWith(date: _fmtDate(picked)));
  }

  Future<void> _pickTime(String? current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(current) ?? TimeOfDay.now(),
    );
    if (picked != null) _update((d) => d.copyWith(time: _fmtTime(picked)));
  }

  Future<void> _pickUrgent(bool? current) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text(_kUrgent),
        children: [
          ListTile(
            title: const Text(_kUrgentYes),
            trailing: current == true
                ? const Icon(Icons.check, color: AppColors.purple700)
                : null,
            onTap: () => Navigator.pop(ctx, true),
          ),
          ListTile(
            title: const Text(_kUrgentNo),
            trailing: current == false
                ? const Icon(Icons.check, color: AppColors.purple700)
                : null,
            onTap: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    );
    if (result != null) _update((d) => d.copyWith(urgent: result));
  }

  // ── publish ──────────────────────────────────────────────────────────────
  /// Django requires category, title, date, time, budget_tier, budget_mmk.
  /// budget_tier is defaulted, so these are the ones the client must supply.
  List<String> _missingRequired(ExtractedTask d) {
    return [
      if ((d.category ?? '').isEmpty) _kCategory,
      if ((d.title ?? '').isEmpty) _kTitle,
      if ((d.date ?? '').isEmpty) _kDate,
      if ((d.time ?? '').isEmpty) _kTime,
      if (d.budgetMmk == null) _kBudget,
    ];
  }

  Future<void> _publish() async {
    if (_isPublishing) return;
    final d = ref.read(voiceDraftProvider);
    final missing = _missingRequired(d);
    if (missing.isNotEmpty) {
      setState(() => _publishError = '$_kFillFirst ${missing.join('၊ ')}');
      return;
    }
    setState(() {
      _isPublishing = true;
      _publishError = null;
    });
    try {
      await ref.read(voiceTaskApiProvider).publish({
        'category': d.category,
        'title': d.title,
        'description': d.description ?? '',
        'date': d.date,
        'time': d.time,
        'latitude': _demoLatitude,
        'longitude': _demoLongitude,
        'address': d.township ?? '',
        'urgency': (d.urgent ?? false) ? 'URGENT' : 'NORMAL',
        'budget_tier': _kDefaultBudgetTier,
        'worker_tier_min': _kDefaultWorkerTierMin,
        'worker_tier_max': _kDefaultWorkerTierMax,
        'budget_mmk': d.budgetMmk,
      });
      if (!mounted) return;
      await _showSuccess();
    } on VoiceTaskFailure catch (e) {
      if (!mounted) return;
      setState(() => _publishError = e.message);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _showSuccess() {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhoWaYoke(state: PhoWaYokeState.success, size: 100),
            const SizedBox(height: AppSpacing.md),
            Text('🎉 $_kSuccessTitle',
                textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(_kSuccessMsg,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(voiceDraftProvider.notifier).state =
                    ExtractedTask.empty();
                Navigator.of(context).pop(); // close the dialog
                context.go(Routes.customerHome);
              },
              child: const Text(_kDone),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = ref.watch(voiceDraftProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(_kAppBarTitle),
        actions: [
          ReadAloudButton(textToRead: _readAloudSummary(d)),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const MascotMessageCard(
                    state: PhoWaYokeState.pointing,
                    message: _kMascotMsg,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.blue100,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        _row(theme, _kTitle, d.title,
                            () => _editText(_kTitle, d.title,
                                (v) => _update((x) => x.copyWith(title: v)))),
                        _row(theme, _kCategory, d.category,
                            () => _pickCategory(d.category)),
                        _row(
                            theme,
                            _kDescription,
                            d.description,
                            () => _editText(_kDescription, d.description,
                                (v) => _update((x) => x.copyWith(description: v)),
                                maxLines: 4)),
                        _row(theme, _kDate, d.date, () => _pickDate(d.date)),
                        _row(theme, _kTime, d.time, () => _pickTime(d.time)),
                        _row(
                            theme,
                            _kUrgent,
                            d.urgent == null
                                ? null
                                : (d.urgent! ? _kUrgentYes : _kUrgentNo),
                            () => _pickUrgent(d.urgent)),
                        _row(
                            theme,
                            _kBudget,
                            d.budgetMmk == null ? null : '${d.budgetMmk} ကျပ်',
                            () => _editText(
                                  _kBudget,
                                  d.budgetMmk?.toString(),
                                  (v) => _update((x) => x.copyWith(
                                      budgetMmk: int.tryParse(v))),
                                  keyboardType: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                )),
                        _row(
                            theme,
                            _kLocation,
                            d.township,
                            () => _editText(_kLocation, d.township,
                                (v) => _update((x) => x.copyWith(township: v))),
                            isLast: true),
                      ],
                    ),
                  ),
                  if (_publishError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_publishError!,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LargeButton(
                label: _isPublishing ? _kPublishing : _kPublish,
                icon: _isPublishing ? null : Icons.check_circle,
                gradient: AppColors.purpleGradient,
                celebratory: true,
                onTap: _publish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String? value, VoidCallback onEdit,
      {bool isLast = false}) {
    final hasValue = value != null && value.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  hasValue ? value : _kNotGiven,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasValue ? AppColors.textPrimary : AppColors.warning,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
              onPressed: onEdit, child: Text(hasValue ? _kEdit : _kFill)),
        ],
      ),
    );
  }

  String _readAloudSummary(ExtractedTask d) => [
        '$_kTitle ${d.title ?? _kNotGiven}',
        '$_kCategory ${d.category ?? _kNotGiven}',
        '$_kDate ${d.date ?? _kNotGiven}',
        '$_kTime ${d.time ?? _kNotGiven}',
      ].join('။ ');

  // ── small date/time parse + format helpers ───────────────────────────────
  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), day = int.tryParse(p[2]);
    if (y == null || m == null || day == null) return null;
    return DateTime(y, m, day);
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null) return null;
    final p = s.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]), min = int.tryParse(p[1]);
    if (h == null || min == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: min.clamp(0, 59));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
