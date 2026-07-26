import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_service.dart';

/// The two kinds of money movement in a worker's wallet.
enum WalletTxnType { paymentCleared, withdrawal }

/// A single wallet history entry. Immutable; the notifier prepends new ones.
class WalletTransaction {
  final String id;
  final WalletTxnType type;
  final double amount;
  final DateTime date;

  /// Burmese-first label shown in the history list.
  final String title;

  /// Payout channel — only set for [WalletTxnType.withdrawal].
  final String? method;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.title,
    this.method,
  });
}

/// Immutable snapshot of the worker's funds + history.
class WalletState {
  /// Cleared money the worker can withdraw right now.
  final double availableBalance;

  /// Money still held in escrow, released on digital checkout.
  final double pendingBalance;

  final List<WalletTransaction> transactions;

  const WalletState({
    required this.availableBalance,
    required this.pendingBalance,
    this.transactions = const [],
  });

  WalletState copyWith({
    double? availableBalance,
    double? pendingBalance,
    List<WalletTransaction>? transactions,
  }) =>
      WalletState(
        availableBalance: availableBalance ?? this.availableBalance,
        pendingBalance: pendingBalance ?? this.pendingBalance,
        transactions: transactions ?? this.transactions,
      );
}

/// Mock wallet "service" — a Riverpod [StateNotifier], matching the repo's
/// existing state pattern (see `_ProfileNotifier`). No backend/network: this
/// is the seam a real payments API would slot behind later, keeping the same
/// method shapes.
class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;
  WalletNotifier(this._ref) : super(_seed());

  /// Demo starting funds + a little history so the screen isn't empty.
  static WalletState _seed() {
    final now = DateTime.now();
    return WalletState(
      availableBalance: 185000,
      pendingBalance: 72000,
      transactions: [
        WalletTransaction(
          id: 'seed-1',
          type: WalletTxnType.paymentCleared,
          amount: 45000,
          date: now.subtract(const Duration(days: 1)),
          title: 'ငွေပေးချေမှု ရရှိပြီး',
        ),
        WalletTransaction(
          id: 'seed-2',
          type: WalletTxnType.withdrawal,
          amount: 100000,
          date: now.subtract(const Duration(days: 3)),
          title: 'ငွေထုတ်ယူမှု',
          method: 'KBZPay',
        ),
        WalletTransaction(
          id: 'seed-3',
          type: WalletTxnType.paymentCleared,
          amount: 60000,
          date: now.subtract(const Duration(days: 5)),
          title: 'ငွေပေးချေမှု ရရှိပြီး',
        ),
      ],
    );
  }

  /// Mimics the double-handshake escrow release: on digital checkout the job's
  /// [amount] moves from pending → available and a "Payment Cleared" record is
  /// logged. Pending is floored at 0 so it can't go negative while the full
  /// amount is always credited to the worker.
  ///
  /// Side effects on release: a brief haptic (mimics feeling the payment land)
  /// and a "Money Received" notification (top toast + bell-history entry), via
  /// [notificationProvider]. This is the single seam where a real payments
  /// webhook would trigger the same UX.
  void simulateDigitalCheckout(double amount) {
    if (amount <= 0) return;

    final txn = WalletTransaction(
      id: _newId(),
      type: WalletTxnType.paymentCleared,
      amount: amount,
      date: DateTime.now(),
      title: 'ငွေပေးချေမှု ရရှိပြီး',
    );
    final newPending = state.pendingBalance - amount;
    state = state.copyWith(
      pendingBalance: newPending < 0 ? 0 : newPending,
      availableBalance: state.availableBalance + amount,
      transactions: [txn, ...state.transactions],
    );

    HapticFeedback.heavyImpact();
    _ref.read(notificationProvider.notifier).notifyMoneyReceived(amount);
  }

  /// Deducts [amount] from the available balance via [method], logging a
  /// "Withdrawal" record. Returns false (and changes nothing) when the amount
  /// is non-positive or exceeds the available balance.
  bool withdrawFunds(double amount, String method) {
    if (amount <= 0 || amount > state.availableBalance) return false;

    final txn = WalletTransaction(
      id: _newId(),
      type: WalletTxnType.withdrawal,
      amount: amount,
      date: DateTime.now(),
      title: 'ငွေထုတ်ယူမှု',
      method: method,
    );
    state = state.copyWith(
      availableBalance: state.availableBalance - amount,
      transactions: [txn, ...state.transactions],
    );
    return true;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

/// App-wide wallet provider. NOT autoDispose: balances must survive navigating
/// away from the wallet screen (e.g. after a checkout elsewhere in the app).
final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) => WalletNotifier(ref));
