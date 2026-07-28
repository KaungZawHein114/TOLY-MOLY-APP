import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../activity_chat.dart' show ActivityRole;

// ---------------------------------------------------------------------------
// DISCUSSION WORKSPACE — MODELS
//
// The discussion page is a "collaborative agreement workspace", not a chat.
// Every important decision is a [DiscussionItem]: a small structured card that
// one side creates and the other side answers. Chat is kept alongside it for
// casual talk only.
//
// Phase-1 safe: plain immutable value objects, no async, no backend.
// ---------------------------------------------------------------------------

/// The six decisions a task needs settled before money moves.
enum DiscussionItemType {
  photoRequest,
  materialChecklist,
  durationRequest,
  apprenticeRequest,
  extraCostProposal,
  scheduleProposal,
}

/// Where an item sits in its little lifecycle.
enum DiscussionStatus {
  pending,
  answered,
  accepted,
  rejected,
  needsClarification,
}

/// The other side of a two-party discussion.
ActivityRole counterpartOf(ActivityRole role) =>
    role == ActivityRole.client ? ActivityRole.tasker : ActivityRole.client;

String roleLabel(ActivityRole role) =>
    role == ActivityRole.client ? 'အလုပ်ရှင်' : 'ဝန်ဆောင်မှုပေးသူ';

extension DiscussionStatusX on DiscussionStatus {
  bool get isPending => this == DiscussionStatus.pending;

  /// Anything that is no longer waiting on someone counts as settled — that is
  /// what the progress card counts, including a clean "no" (rejected).
  bool get isSettled => this != DiscussionStatus.pending;

  /// Settled *and* agreed — drives the green ticks.
  bool get isAgreed =>
      this == DiscussionStatus.answered || this == DiscussionStatus.accepted;

  String get label => switch (this) {
        DiscussionStatus.pending => 'စောင့်ဆိုင်းဆဲ',
        DiscussionStatus.answered => 'ဖြေကြားပြီး',
        DiscussionStatus.accepted => 'သဘောတူပြီး',
        DiscussionStatus.rejected => 'လက်မခံပါ',
        DiscussionStatus.needsClarification => 'ထပ်ဆွေးနွေးရန်',
      };

  IconData get icon => switch (this) {
        DiscussionStatus.pending => Icons.hourglass_top_rounded,
        DiscussionStatus.answered => Icons.check_rounded,
        DiscussionStatus.accepted => Icons.check_circle_rounded,
        DiscussionStatus.rejected => Icons.close_rounded,
        DiscussionStatus.needsClarification => Icons.forum_rounded,
      };

  Color get fg => switch (this) {
        DiscussionStatus.pending => AppColors.orangeDark,
        DiscussionStatus.answered => AppColors.indigo700,
        DiscussionStatus.accepted => AppColors.tealDark,
        DiscussionStatus.rejected => AppColors.error,
        DiscussionStatus.needsClarification => AppColors.purple700,
      };

  Color get bg => switch (this) {
        DiscussionStatus.pending => AppColors.warning.withValues(alpha: 0.16),
        DiscussionStatus.answered => AppColors.indigo100,
        DiscussionStatus.accepted => AppColors.success.withValues(alpha: 0.16),
        DiscussionStatus.rejected => AppColors.error.withValues(alpha: 0.12),
        DiscussionStatus.needsClarification => AppColors.purple100,
      };
}

extension DiscussionItemTypeX on DiscussionItemType {
  /// Short label used on the progress checklist.
  String get checklistLabel => switch (this) {
        DiscussionItemType.photoRequest => 'ဓာတ်ပုံ',
        DiscussionItemType.materialChecklist => 'ပစ္စည်း',
        DiscussionItemType.durationRequest => 'ကြာချိန်',
        DiscussionItemType.apprenticeRequest => 'လက်ထောက်',
        DiscussionItemType.extraCostProposal => 'ကုန်ကျစရိတ်',
        DiscussionItemType.scheduleProposal => 'ချိန်းချိန်',
      };

  /// Full label used on the card header.
  String get label => switch (this) {
        DiscussionItemType.photoRequest => 'ဓာတ်ပုံ တောင်းဆိုချက်',
        DiscussionItemType.materialChecklist => 'လိုအပ်သော ပစ္စည်းများ',
        DiscussionItemType.durationRequest => 'ကြာမြင့်ချိန်',
        DiscussionItemType.apprenticeRequest => 'လက်ထောက် ခေါ်ဆောင်ခြင်း',
        DiscussionItemType.extraCostProposal => 'ဖြစ်နိုင်သော ကုန်ကျစရိတ်',
        DiscussionItemType.scheduleProposal => 'ချိန်းဆိုချိန် ပြောင်းလဲမှု',
      };

  IconData get icon => switch (this) {
        DiscussionItemType.photoRequest => Icons.photo_camera_outlined,
        DiscussionItemType.materialChecklist => Icons.handyman_outlined,
        DiscussionItemType.durationRequest => Icons.schedule_outlined,
        DiscussionItemType.apprenticeRequest => Icons.groups_outlined,
        DiscussionItemType.extraCostProposal => Icons.payments_outlined,
        DiscussionItemType.scheduleProposal => Icons.event_outlined,
      };

  Color get accent => switch (this) {
        DiscussionItemType.photoRequest => AppColors.indigo700,
        DiscussionItemType.materialChecklist => AppColors.purple700,
        DiscussionItemType.durationRequest => AppColors.indigo500,
        DiscussionItemType.apprenticeRequest => AppColors.purple500,
        DiscussionItemType.extraCostProposal => AppColors.orangeDark,
        DiscussionItemType.scheduleProposal => AppColors.purple700,
      };

  Color get accentBg => switch (this) {
        DiscussionItemType.photoRequest => AppColors.indigo100,
        DiscussionItemType.materialChecklist => AppColors.purple100,
        DiscussionItemType.durationRequest => AppColors.indigo100,
        DiscussionItemType.apprenticeRequest => AppColors.purple100,
        DiscussionItemType.extraCostProposal => AppColors.warning.withValues(alpha: 0.14),
        DiscussionItemType.scheduleProposal => AppColors.blue100,
      };
}

/// The fixed checklist every task is measured against — the progress card
/// always shows these six rows, whether or not a card exists for them yet.
const List<DiscussionItemType> kDiscussionChecklist = DiscussionItemType.values;

// ---------------------------------------------------------------------------
// The item itself
// ---------------------------------------------------------------------------

@immutable
class DiscussionItem {
  final String id;
  final DiscussionItemType type;
  final ActivityRole creatorRole;
  final String title;
  final String description;
  final DiscussionStatus status;

  /// Type-specific payload. Kept as a plain map so a Phase-2 backend can send
  /// the same shape down without a per-type parser in the UI layer.
  final Map<String, Object?> data;
  final String createdAt;

  const DiscussionItem({
    required this.id,
    required this.type,
    required this.creatorRole,
    required this.title,
    this.description = '',
    this.status = DiscussionStatus.pending,
    this.data = const {},
    this.createdAt = 'ယခု',
  });

  DiscussionItem copyWith({
    String? title,
    String? description,
    DiscussionStatus? status,
    Map<String, Object?>? data,
  }) {
    return DiscussionItem(
      id: id,
      type: type,
      creatorRole: creatorRole,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      data: data ?? this.data,
      createdAt: createdAt,
    );
  }

  /// Merge a few keys into [data] without rebuilding the whole map at call sites.
  DiscussionItem withData(Map<String, Object?> patch) =>
      copyWith(data: {...data, ...patch});

  // ── typed payload accessors ───────────────────────────────────────────────

  int get photoCount => (data['photos'] as int?) ?? 0;

  List<String> get materials =>
      (data['materials'] as List?)?.cast<String>() ?? const <String>[];

  List<String> get ownedMaterials =>
      (data['have'] as List?)?.cast<String>() ?? const <String>[];

  String? get duration => data['duration'] as String?;

  String? get reason => data['reason'] as String?;

  bool get isCostFilled => data['amount'] != null;

  int get costAmountMmk => (data['amount'] as int?) ?? 0;

  String get costItem => (data['item'] as String?) ?? '';

  String get fromDate => (data['fromDate'] as String?) ?? '';
  String get fromTime => (data['fromTime'] as String?) ?? '';
  String get toDate => (data['toDate'] as String?) ?? '';
  String get toTime => (data['toTime'] as String?) ?? '';

  // ── turn taking ───────────────────────────────────────────────────────────

  /// Who the card is currently waiting on, or null when it is settled.
  ///
  /// Some answers always belong to one side no matter who opened the card:
  /// only the tasker can estimate a duration or price extra work, and only the
  /// client can approve spending or an extra worker in their home.
  ActivityRole? get awaitingRole {
    if (!status.isPending) return null;
    switch (type) {
      case DiscussionItemType.photoRequest:
      case DiscussionItemType.scheduleProposal:
        return counterpartOf(creatorRole);
      case DiscussionItemType.materialChecklist:
        return ActivityRole.client;
      case DiscussionItemType.durationRequest:
        return ActivityRole.tasker;
      case DiscussionItemType.apprenticeRequest:
        return ActivityRole.client;
      case DiscussionItemType.extraCostProposal:
        return isCostFilled ? ActivityRole.client : ActivityRole.tasker;
    }
  }

  bool isMyTurn(ActivityRole viewer) => awaitingRole == viewer;
}
