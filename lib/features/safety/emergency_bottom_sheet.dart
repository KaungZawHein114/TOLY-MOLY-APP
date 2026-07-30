import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'safety_service.dart';

/// Myanmar emergency + platform numbers. Central so they're easy to audit.
const String _kPoliceNumber = '199';
const String _kAmbulanceNumber = '192';

/// Opens the urgent, high-contrast SOS sheet. [location] is the text shared
/// with contacts (e.g. the current task's township).
void showEmergencyBottomSheet(BuildContext context, {required String location}) {
  HapticFeedback.heavyImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => EmergencyBottomSheet(location: location),
  );
}

class EmergencyBottomSheet extends ConsumerWidget {
  final String location;
  const EmergencyBottomSheet({super.key, required this.location});

  Future<void> _dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) _dialFallback(context, number);
    } catch (_) {
      if (context.mounted) _dialFallback(context, number);
    }
  }

  // On desktop/web the dialer often can't open — show the number so the user
  // can still call it manually. Never leave an emergency tap doing nothing.
  void _dialFallback(BuildContext context, String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ဖုန်းခေါ်၍မရပါ — ကိုယ်တိုင်ခေါ်ဆိုပါ - $number')),
    );
  }

  void _alertContacts(BuildContext context, WidgetRef ref) {
    final result = ref.read(safetyProvider.notifier).triggerSOSAlert(location);
    Navigator.of(context).pop(); // close the sheet first
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          result.notifiedCount > 0
              ? 'တည်နေရာ ပေးပို့ပြီးပါပြီ — ${result.notifiedCount} ဦးထံ အကြောင်းကြားပြီး'
              : 'အရေးပေါ်အဆက်အသွယ် မထည့်ရသေးပါ — အရင်ထည့်ပါ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            // Urgent header banner.
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.error, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.error, size: AppSizes.iconLg),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'အရေးပေါ် အကူအညီ',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'ဘေးအန္တရာယ်ရှိပါက အောက်ပါခလုတ်ကို နှိပ်ပါ',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Action 1: Police + Ambulance (side by side) ──
            Row(
              children: [
                Expanded(
                  child: _EmergencyCallButton(
                    icon: Icons.local_police,
                    label: 'ရဲစခန်း',
                    number: _kPoliceNumber,
                    onTap: () => _dial(context, _kPoliceNumber),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _EmergencyCallButton(
                    icon: Icons.medical_services,
                    label: 'လူနာတင်ယာဉ်',
                    number: _kAmbulanceNumber,
                    onTap: () => _dial(context, _kAmbulanceNumber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Action 2: Notify emergency contacts ──
            _WideActionButton(
              icon: Icons.notifications_active,
              color: AppColors.warning,
              title: 'အရေးပေါ်အဆက်အသွယ်များထံ အကြောင်းကြားရန်',
              subtitle: 'သင်၏ လက်ရှိတည်နေရာကို SMS ဖြင့် ပေးပို့မည်',
              onTap: () => _alertContacts(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large, high-contrast red call button (Police / Ambulance).
class _EmergencyCallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onTap;
  const _EmergencyCallButton({
    required this.icon,
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              Icon(icon, color: AppColors.onBrand, size: AppSizes.iconLg),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onBrand,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                number,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onBrand,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width action row (Notify contacts / Support) with icon + title + sub.
class _WideActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WideActionButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.onBrand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.onBrand, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrand.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
