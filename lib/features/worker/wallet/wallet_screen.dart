import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'wallet_service.dart';

/// Formats a kyat amount with thousands separators (no decimals — kyat is
/// used whole here). Western digits are intentional for financial clarity and
/// to match the number-pad input.
String _formatKyat(double amount) {
  final s = amount.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// The tasker's wallet / earnings screen. Pushed from the Profile tab (worker
/// flow only). Reads/writes funds through [walletProvider].
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ကျွန်ုပ်၏ ပိုက်ဆံအိတ်'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _BalanceCard(
            wallet: wallet,
            onWithdraw: () => _openWithdrawSheet(context, ref),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('လတ်တလော ငွေအလွှဲအပြောင်းများ', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (wallet.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'မှတ်တမ်း မရှိသေးပါ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ),
            )
          else
            for (final txn in wallet.transactions) ...[
              _TransactionTile(txn: txn),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _openWithdrawSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_WithdrawResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const _WithdrawSheet(),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_formatKyat(result.amount)} ကျပ်ကို ${result.method} သို့ ထုတ်ယူပြီးပါပြီ ✅',
          ),
        ),
      );
    }
  }
}

// ============================================================================
// TOP SECTION — available balance + withdraw CTA + pending (escrow) stat
// ============================================================================

class _BalanceCard extends StatelessWidget {
  final WalletState wallet;
  final VoidCallback onWithdraw;
  const _BalanceCard({required this.wallet, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple700.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ရရှိနိုင်သော လက်ကျန်ငွေ',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onBrandMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _formatKyat(wallet.availableBalance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.onBrand),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ကျပ်',
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onBrandMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('ငွေထုတ်မည်'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.onBrand,
                foregroundColor: AppColors.purple700,
                minimumSize: const Size(0, AppSizes.buttonHeight - 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Pending / escrow stat + explanatory tooltip.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onBrand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock, color: AppColors.onBrand, size: AppSizes.iconSm),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ငွေလွှဲဆိုင်းငံ့',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${_formatKyat(wallet.pendingBalance)} ကျပ်',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.onBrand,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 4),
                  message:
                      'ဒီငွေကို Digital Checkout ပြီးဆုံးသည်အထိ Escrow တွင် ထိန်းသိမ်းထားပါသည်။',
                  child: Semantics(
                    label: 'ငွေလွှဲဆိုင်းငံ့ အကြောင်း',
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(Icons.info_outline, color: AppColors.onBrandMuted, size: AppSizes.iconSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRANSACTION TILE
// ============================================================================

class _TransactionTile extends StatelessWidget {
  final WalletTransaction txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = txn.type == WalletTxnType.paymentCleared;
    final accent = isCredit ? AppColors.success : AppColors.purple700;
    final sign = isCredit ? '+' : '-';

    final subtitle = txn.method == null
        ? _formatDate(txn.date)
        : '${txn.method} • ${_formatDate(txn.date)}';

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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(
              isCredit ? Icons.south_west : Icons.north_east,
              color: accent,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign${_formatKyat(txn.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

// ============================================================================
// WITHDRAWAL WORKFLOW (bottom sheet)
// ============================================================================

class _WithdrawResult {
  final double amount;
  final String method;
  const _WithdrawResult(this.amount, this.method);
}

const List<String> _payoutMethods = ['KBZPay', 'WavePay', 'Bank Transfer'];

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet();

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _method = _payoutMethods.first;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    final available = ref.read(walletProvider).availableBalance;
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() => _error = 'ငွေပမာဏ မှန်ကန်စွာ ထည့်ပါ');
      return;
    }
    if (amount > available) {
      setState(() => _error = 'လက်ကျန်ငွေထက် ကျော်လွန်နေပါသည်');
      return;
    }

    final ok = ref.read(walletProvider.notifier).withdrawFunds(amount, _method);
    if (!ok) {
      setState(() => _error = 'ငွေထုတ်ယူမှု မအောင်မြင်ပါ');
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_WithdrawResult(amount, _method));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = ref.watch(walletProvider).availableBalance;
    // Pad for the keyboard so the Confirm button stays visible while typing.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
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
          Text('ငွေထုတ်မည်', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ရရှိနိုင်သော လက်ကျန် — ${_formatKyat(available)} ကျပ်',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 1 — amount.
          Text('ငွေပမာဏ', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: 'ကျပ်',
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Step 2 — payout method.
          Text('ငွေလက်ခံမည့် နည်းလမ်း', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final m in _payoutMethods)
                ChoiceChip(
                  label: Text(m),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                  selectedColor: AppColors.purple100,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _method == m ? AppColors.purple700 : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Step 3 — confirm.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
                minimumSize: const Size(0, AppSizes.buttonHeight - 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('အတည်ပြုမည်'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROFILE MENU TILE — drop into the tasker profile's `sections` list.
// ============================================================================

/// Tappable "My Wallet / Earnings" tile for the Profile screen. Presentational
/// only — the caller supplies [onTap] (navigation).
class WalletMenuTile extends StatelessWidget {
  final VoidCallback onTap;
  const WalletMenuTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.onBrand,
                    size: AppSizes.iconLg,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ကျွန်ုပ်၏ ပိုက်ဆံအိတ်',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'ဝင်ငွေနှင့် ငွေထုတ်ယူမှု',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
