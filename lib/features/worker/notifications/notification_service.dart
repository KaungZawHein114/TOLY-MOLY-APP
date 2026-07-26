import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Formats a kyat amount with thousands separators (whole kyat, no decimals).
/// Western digits are intentional for financial clarity (mirrors the wallet).
String formatKyat(double amount) {
  final s = amount.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// A single item in the worker's notification history (bell dropdown).
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        read: read ?? this.read,
      );
}

/// A transient "show a top toast now" signal. Kept in [NotificationState] with
/// a monotonically increasing [seq] so a `ref.listen` fires once per event
/// (each new event is `!=` the previous). It is NOT the persistent history —
/// that's [NotificationState.items].
class ToastSignal {
  final int seq;
  final double amount;
  const ToastSignal(this.seq, this.amount);
}

/// Immutable snapshot of notification history + the latest toast signal.
class NotificationState {
  final List<AppNotification> items;
  final ToastSignal? toast;

  const NotificationState({this.items = const [], this.toast});

  /// Badge count for the bell icon.
  int get unreadCount => items.where((n) => !n.read).length;

  NotificationState copyWith({
    List<AppNotification>? items,
    ToastSignal? toast,
  }) =>
      NotificationState(
        items: items ?? this.items,
        toast: toast ?? this.toast,
      );
}

/// Mock notification "service" — a Riverpod [StateNotifier], matching the
/// repo's existing state pattern (see `WalletNotifier`). No backend/network:
/// this is the seam a real push-notification pipeline would slot behind later.
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  int _toastSeq = 0;

  /// Called when a digital checkout clears: prepends an unread "Transfer
  /// Successful" record (bumping the bell badge) and raises a toast signal for
  /// the top banner.
  void notifyMoneyReceived(double amount) {
    final now = DateTime.now();
    final item = AppNotification(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'ငွေလွှဲပြောင်းမှု အောင်မြင်သည်',
      body: 'အလုပ်ပြီးစီးကြောင်း အတည်ပြုလိုက်ပါပြီ။ '
          'ကျပ် ${formatKyat(amount)} ကို သင့် ပိုက်ဆံအိတ်ထဲသို့ ထည့်သွင်းပေးလိုက်ပါပြီ။',
      timestamp: now,
      read: false,
    );
    state = state.copyWith(
      items: [item, ...state.items],
      toast: ToastSignal(++_toastSeq, amount),
    );
  }

  /// Marks every notification read — clears the bell badge.
  void markAllRead() {
    if (state.unreadCount == 0) return;
    state = state.copyWith(
      items: [for (final n in state.items) n.copyWith(read: true)],
    );
  }
}

/// App-wide notification provider. NOT autoDispose: the badge/history must
/// survive navigating between worker screens.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
