import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'notification_service.dart';

/// Shows the "🎉 Money Received!" banner floating in from the top of the
/// screen. Uses the root [Overlay] so it appears above whatever worker screen
/// is currently on top (dashboard, wallet, task execution, …).
void showMoneyReceivedToast(BuildContext context, double amount) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MoneyReceivedToast(
      amount: amount,
      onDismissed: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _MoneyReceivedToast extends StatefulWidget {
  final double amount;
  final VoidCallback onDismissed;
  const _MoneyReceivedToast({required this.amount, required this.onDismissed});

  @override
  State<_MoneyReceivedToast> createState() => _MoneyReceivedToastState();
}

class _MoneyReceivedToastState extends State<_MoneyReceivedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoHide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      reverseDuration: AppMotion.medium,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.enter));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    // Auto-dismiss after a readable dwell time.
    _autoHide = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    _autoHide?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      // Success-green accent border per the spec.
                      border: Border.all(color: AppColors.success, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🎉', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ငွေလက်ခံရရှိပါပြီ!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'ကျပ် ${formatKyat(widget.amount)} '
                                'သင့်ပိုက်ဆံအိတ်သို့ ရောက်ရှိပါပြီ။',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
