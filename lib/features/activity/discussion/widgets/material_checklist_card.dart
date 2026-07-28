import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// The tasker lists what the job needs; the client ticks what they already
/// have. What's left unticked is what the tasker must bring — so both sides
/// leave with the same shopping list instead of a guess.
class MaterialChecklistCard extends StatefulWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;
  final VoidCallback? onDemoAnswer;

  const MaterialChecklistCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.onUpdate,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  @override
  State<MaterialChecklistCard> createState() => _MaterialChecklistCardState();
}

class _MaterialChecklistCardState extends State<MaterialChecklistCard> {
  late final Set<String> _selected = widget.item.ownedMaterials.toSet();

  void _submit() {
    widget.onUpdate(
      widget.item.withData({'have': _selected.toList()}).copyWith(
          status: DiscussionStatus.answered),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final materials = item.materials;
    final myTurn = item.isMyTurn(widget.viewerRole);
    final owned = item.status.isSettled ? item.ownedMaterials.toSet() : _selected;
    final missing = materials.where((m) => !owned.contains(m)).toList();

    return DiscussionCard(
      item: item,
      viewerRole: widget.viewerRole,
      highlighted: widget.highlighted,
      onDemoAnswer: widget.onDemoAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (myTurn)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'သင့်အိမ်မှာ ရှိပြီးသား ပစ္စည်းတွေကို အမှန်ခြစ် ပေးပါ။',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          for (final material in materials)
            _MaterialRow(
              label: material,
              checked: owned.contains(material),
              interactive: myTurn,
              onToggle: () => setState(() {
                if (_selected.contains(material)) {
                  _selected.remove(material);
                } else {
                  _selected.add(material);
                }
              }),
            ),
          if (myTurn) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('အတည်ပြု ပေးပို့ရန်'),
            ),
          ] else if (item.status.isSettled) ...[
            const SizedBox(height: AppSpacing.md),
            DiscussionResultNote(
              icon: Icons.shopping_bag_outlined,
              color: missing.isEmpty ? AppColors.tealDark : AppColors.indigo700,
              text: missing.isEmpty
                  ? 'ပစ္စည်းအားလုံး အိမ်မှာ ရှိပြီးသားပါ။'
                  : 'ဝန်ဆောင်မှုပေးသူ ယူလာရမည် — ${missing.join('၊ ')}',
            ),
          ],
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final String label;
  final bool checked;
  final bool interactive;
  final VoidCallback onToggle;

  const _MaterialRow({
    required this.label,
    required this.checked,
    required this.interactive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 48),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: checked ? AppColors.purple100 : AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box_rounded : Icons.check_box_outline_blank,
            color: checked ? AppColors.purple700 : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                color: checked ? AppColors.purple900 : AppColors.textPrimary,
              ),
            ),
          ),
          if (checked)
            Text(
              'ရှိပြီး',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );

    if (!interactive) {
      return Semantics(
        label: '$label — ${checked ? 'ရှိပြီး' : 'မရှိသေး'}',
        child: row,
      );
    }
    return Semantics(
      button: true,
      checked: checked,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onToggle,
        child: row,
      ),
    );
  }
}
