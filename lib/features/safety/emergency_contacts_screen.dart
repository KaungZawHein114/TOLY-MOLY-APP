import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'safety_service.dart';

/// Manage the user's emergency (safety) contacts — reached from Profile.
/// Max 3 contacts; each shows name, relationship, phone, and a remove action.
class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final safety = ref.watch(safetyProvider);
    final contacts = safety.contacts;

    return Scaffold(
      appBar: AppBar(title: const Text('အရေးပေါ် ဆက်သွယ်ရန်')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Reassuring intro.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.blue300.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.purple700),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'အရေးပေါ်အခြေအနေတွင် SOS နှိပ်လျှင် ဤသူများထံ '
                    'သင့်တည်နေရာကို အလိုအလျောက် ပေးပို့ပါမည်။',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'သိမ်းဆည်းထားသော အဆက်အသွယ် (${contacts.length}/${SafetyState.maxContacts})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'အဆက်အသွယ် မထည့်ရသေးပါ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ),
            )
          else
            for (final c in contacts) ...[
              _ContactCard(
                contact: c,
                onRemove: () => ref.read(safetyProvider.notifier).removeContact(c.id),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

          const SizedBox(height: AppSpacing.sm),
          if (safety.canAddMore)
            _AddContactButton(onTap: () => _openAddForm(context, ref))
          else
            Text(
              'အများဆုံး ${SafetyState.maxContacts} ဦး ထည့်နိုင်ပါသည်။',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
        ],
      ),
    );
  }

  void _openAddForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        // Lift the sheet above the keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddContactForm(
          onSave: (name, phone, rel) {
            final ok = ref.read(safetyProvider.notifier).addContact(name, phone, rel);
            Navigator.of(ctx).pop();
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ထည့်၍မရပါ — အချက်အလက် စစ်ဆေးပါ')),
              );
            }
          },
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onRemove;
  const _ContactCard({required this.contact, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.purple100,
            child: Text(
              contact.name.trim().isEmpty ? '?' : contact.name.trim()[0],
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple100.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        contact.relationship.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.purple700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  contact.phoneNumber,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ဖယ်ရှားမည်',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddContactButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddContactButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.purple100.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.purple700.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.purple700),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'အသစ်ထည့်မည်',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.purple700,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The add-contact form (name / phone / relationship) shown in a bottom sheet.
class _AddContactForm extends StatefulWidget {
  final void Function(String name, String phone, ContactRelationship rel) onSave;
  const _AddContactForm({required this.onSave});

  @override
  State<_AddContactForm> createState() => _AddContactFormState();
}

class _AddContactFormState extends State<_AddContactForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  ContactRelationship _relationship = ContactRelationship.family;
  bool _showErrors = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onSave(name, phone, _relationship);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('အဆက်အသွယ် အသစ်ထည့်ရန်', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            Text('အမည်', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'ဥပမာ — မမြင့်မြင့်',
                errorText: _showErrors && _nameController.text.trim().isEmpty
                    ? 'အမည် ထည့်ပါ'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('ဖုန်းနံပါတ်', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '09xxxxxxxxx',
                errorText: _showErrors && _phoneController.text.trim().isEmpty
                    ? 'ဖုန်းနံပါတ် ထည့်ပါ'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('ဆက်ဆံရေး', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final rel in ContactRelationship.values)
                  ChoiceChip(
                    label: Text(rel.label),
                    selected: _relationship == rel,
                    onSelected: (_) => setState(() => _relationship = rel),
                    selectedColor: AppColors.purple700,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: _relationship == rel ? AppColors.onBrand : theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple700,
                  foregroundColor: AppColors.onBrand,
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('သိမ်းဆည်းမည်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
