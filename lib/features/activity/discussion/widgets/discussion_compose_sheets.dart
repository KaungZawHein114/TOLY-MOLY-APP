import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'duration_card.dart' show kDurationChoices;

// ---------------------------------------------------------------------------
// Small composers used when creating a discussion card.
//
// Every field is pre-filled with the most likely answer, so the common case is
// "open → confirm". A user with low digital literacy should be able to raise a
// discussion point without typing a single character.
// ---------------------------------------------------------------------------

const List<String> kMaterialSuggestions = [
  'PVC တိပ်',
  'ပါဝါ ရင်း (Wrench)',
  'ရေပုံး',
  'ဝါယာကြိုး',
  'ဆလင်ဒါ ဆီ',
];

const List<String> kDateChoices = ['ဇွန် ၂၈ ရက်', 'ဇွန် ၂၉ ရက်', 'ဇွန် ၃၀ ရက်'];
const List<String> kTimeChoices = [
  'နံနက် ၉:၀၀',
  'နေ့လည် ၂:၀၀',
  'ညနေ ၅:၀၀',
  'ည ၇:၀၀',
];

Future<T?> _showComposer<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => child,
  );
}

class _ComposerShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  const _ComposerShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: AppColors.purple700),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
              ),
              icon: const Icon(Icons.send_rounded),
              label: Text(primaryLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('မလုပ်တော့ပါ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pill that toggles between filled and outlined. Used everywhere a composer
/// needs a pick-one/pick-many control instead of a keyboard.
class ComposerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ComposerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple700 : AppColors.lightBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded,
                      size: AppSizes.iconSm, color: AppColors.onBrand),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.onBrand : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Materials
// ---------------------------------------------------------------------------

Future<List<String>?> showMaterialsComposer(BuildContext context) =>
    _showComposer<List<String>>(context, const _MaterialsComposer());

class _MaterialsComposer extends StatefulWidget {
  const _MaterialsComposer();

  @override
  State<_MaterialsComposer> createState() => _MaterialsComposerState();
}

class _MaterialsComposerState extends State<_MaterialsComposer> {
  final Set<String> _selected = {
    kMaterialSuggestions[0],
    kMaterialSuggestions[1],
    kMaterialSuggestions[2],
  };
  final List<String> _extra = [];
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _extra.add(text);
      _selected.add(text);
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ComposerShell(
      icon: Icons.handyman_outlined,
      title: 'လိုအပ်သော ပစ္စည်းများ',
      subtitle: 'အလုပ်ရှင်က ဘယ်ဟာတွေ ရှိပြီးသားလဲ ခြစ်ပြပါလိမ့်မယ်။',
      primaryLabel: 'ပစ္စည်းစာရင်း ပေးပို့ရန်',
      onPrimary:
          _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final material in [...kMaterialSuggestions, ..._extra])
                ComposerChip(
                  label: material,
                  selected: _selected.contains(material),
                  onTap: () => setState(() {
                    if (!_selected.remove(material)) _selected.add(material);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'အခြား ပစ္စည်း ထည့်ရန်...',
                    filled: true,
                    fillColor: AppColors.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _addCustom,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.indigo700,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.add, color: AppColors.onBrand),
                tooltip: 'ထည့်ရန်',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Duration (tasker states its own estimate)
// ---------------------------------------------------------------------------

Future<String?> showDurationComposer(BuildContext context) =>
    _showComposer<String>(context, const _DurationComposer());

class _DurationComposer extends StatefulWidget {
  const _DurationComposer();

  @override
  State<_DurationComposer> createState() => _DurationComposerState();
}

class _DurationComposerState extends State<_DurationComposer> {
  String _choice = kDurationChoices[2];

  @override
  Widget build(BuildContext context) {
    return _ComposerShell(
      icon: Icons.schedule_outlined,
      title: 'ခန့်မှန်း ကြာမြင့်ချိန်',
      subtitle: 'အလုပ် ဘယ်လောက်ကြာမလဲ ကြိုပြောပေးပါ။',
      primaryLabel: 'ကြာချိန် ပေးပို့ရန်',
      onPrimary: () => Navigator.of(context).pop(_choice),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final choice in kDurationChoices)
            ComposerChip(
              label: choice,
              selected: _choice == choice,
              onTap: () => setState(() => _choice = choice),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Apprentice
// ---------------------------------------------------------------------------

Future<String?> showApprenticeComposer(BuildContext context) =>
    _showComposer<String>(context, const _ApprenticeComposer());

class _ApprenticeComposer extends StatefulWidget {
  const _ApprenticeComposer();

  @override
  State<_ApprenticeComposer> createState() => _ApprenticeComposerState();
}

class _ApprenticeComposerState extends State<_ApprenticeComposer> {
  final TextEditingController _ctrl = TextEditingController(
    text: 'မော်တာက အလေးချိန် များတဲ့အတွက် လက်ထောက် တစ်ယောက် ခေါ်လာချင်ပါတယ်။',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ComposerShell(
      icon: Icons.groups_outlined,
      title: 'လက်ထောက် ခေါ်ဆောင်ခြင်း',
      subtitle: 'အလုပ်ရှင်ထံ ခွင့်တောင်းပါ။ အကြောင်းပြချက် ရေးပေးပါ။',
      primaryLabel: 'ခွင့်တောင်း ပေးပို့ရန်',
      onPrimary: () => Navigator.of(context).pop(_ctrl.text.trim()),
      child: TextField(
        controller: _ctrl,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Possible extra cost
// ---------------------------------------------------------------------------

Future<Map<String, Object?>?> showCostComposer(BuildContext context) =>
    _showComposer<Map<String, Object?>>(context, const _CostComposer());

class _CostComposer extends StatefulWidget {
  const _CostComposer();

  @override
  State<_CostComposer> createState() => _CostComposerState();
}

class _CostComposerState extends State<_CostComposer> {
  final TextEditingController _itemCtrl = TextEditingController(text: 'ရေပိုက် အသစ်');
  final TextEditingController _reasonCtrl = TextEditingController(
    text: 'လက်ရှိပိုက် ပျက်နေမှသာ လိုအပ်ပါမည်။',
  );
  int _amount = 8000;

  static const List<int> _amountChoices = [3000, 5000, 8000, 15000];

  @override
  void dispose() {
    _itemCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ComposerShell(
      icon: Icons.payments_outlined,
      title: 'ဖြစ်နိုင်သော ကုန်ကျစရိတ်',
      subtitle: 'ကြိုတင် အသိပေးထားခြင်းက နောက်ပိုင်း အငြင်းပွားမှု မဖြစ်စေပါ။',
      primaryLabel: 'အသိပေးချက် ပေးပို့ရန်',
      onPrimary: () => Navigator.of(context).pop({
        'item': _itemCtrl.text.trim(),
        'amount': _amount,
        'reason': _reasonCtrl.text.trim(),
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ပစ္စည်း / အကြောင်းအရာ',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _itemCtrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('ခန့်မှန်း ကုန်ကျစရိတ်',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final amount in _amountChoices)
                ComposerChip(
                  label: '${amount ~/ 1000},000 ကျပ်',
                  selected: _amount == amount,
                  onTap: () => setState(() => _amount = amount),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('အကြောင်းပြချက်',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _reasonCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------

Future<Map<String, Object?>?> showScheduleComposer(
  BuildContext context, {
  required String currentDate,
  required String currentTime,
}) =>
    _showComposer<Map<String, Object?>>(
      context,
      _ScheduleComposer(currentDate: currentDate, currentTime: currentTime),
    );

class _ScheduleComposer extends StatefulWidget {
  final String currentDate;
  final String currentTime;

  const _ScheduleComposer({required this.currentDate, required this.currentTime});

  @override
  State<_ScheduleComposer> createState() => _ScheduleComposerState();
}

class _ScheduleComposerState extends State<_ScheduleComposer> {
  late String _date = widget.currentDate;
  late String _time = kTimeChoices.firstWhere(
    (t) => t != widget.currentTime,
    orElse: () => kTimeChoices.last,
  );

  bool get _changed => _date != widget.currentDate || _time != widget.currentTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ComposerShell(
      icon: Icons.event_outlined,
      title: 'ချိန်းဆိုချိန် ပြောင်းရန်',
      subtitle: 'လက်ရှိ — ${widget.currentDate} · ${widget.currentTime}',
      primaryLabel: 'အဆိုပြုချက် ပေးပို့ရန်',
      onPrimary: _changed
          ? () => Navigator.of(context).pop({
                'fromDate': widget.currentDate,
                'fromTime': widget.currentTime,
                'toDate': _date,
                'toTime': _time,
              })
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ရက်စွဲ',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final date in kDateChoices)
                ComposerChip(
                  label: date,
                  selected: _date == date,
                  onTap: () => setState(() => _date = date),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('အချိန်',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final time in kTimeChoices)
                ComposerChip(
                  label: time,
                  selected: _time == time,
                  onTap: () => setState(() => _time = time),
                ),
            ],
          ),
          if (!_changed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'လက်ရှိအချိန်နှင့် တူနေပါသည်။ အသစ်တစ်ခု ရွေးပါ။',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeDark),
            ),
          ],
        ],
      ),
    );
  }
}
