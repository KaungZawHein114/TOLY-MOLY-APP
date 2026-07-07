// ============================================================================
// AGENT SESSION / MODE — the ONE sanctioned app-wide shared provider.
// ----------------------------------------------------------------------------
// Pho Wa Yoke is a SINGLE agent (spec §2) that wears different context "hats"
// (modes) and is more or less present depending on the session state (spec §3).
// This is the deliberate, documented exception to CLAUDE.md's "providers live
// in one screen" rule, because agent presence/context is app-wide. It is the
// ONLY new shared provider the AI-agents work introduces.
//
// Nothing here does I/O or async — it is pure UI state. Each agent mode (the
// nine "agents" in the design) plugs into this shell; see the mode enum below.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How present the agent is right now (spec §3).
///
/// - [sleep]  — fully hidden: no floating button, no nudges (for users who find
///   it distracting). Left only by an explicit wake.
/// - [wakie]  — idle but available: the small floating Pho Wa Yoke button waits
///   to be tapped. The default.
/// - [active] — engaged: listening, asking, filling, matching, or explaining.
enum AgentSession { sleep, wakie, active }

/// The context "hat" Pho Wa Yoke is wearing. One agent, many modes (spec §4).
///
/// Nicknames are Burmese-first placeholders (spec §8 leaves final naming open);
/// they label the mode, never a separate avatar. They are safe to change later
/// without touching feature code.
enum AgentMode {
  /// Navigation + FAQ chat helper (spec §4.5 / §4.9).
  overall,

  /// Voice-first onboarding / auth form filling (spec §4.1 / §4.6).
  onboarding,

  /// Spoken/typed "my fan is broken" → a complete task (spec §4.2).
  taskPosting,

  /// Ranked tasker shortlist with spoken reasons (spec §4.3).
  taskerFinding,

  /// Task-lifecycle nudges + completion summaries (spec §4.4 / §4.8).
  taskHandling,

  /// Tasker-side "find me work" matching (spec §4.7).
  taskAnalyzing,
}

extension AgentModeInfo on AgentMode {
  /// A short, cute Burmese nickname for the mode (placeholder — spec §8).
  String get nickname {
    switch (this) {
      case AgentMode.overall:
        return 'ဖိုးလမ်းပြ';
      case AgentMode.onboarding:
        return 'ဖိုးကြိုဆို';
      case AgentMode.taskPosting:
        return 'ဖိုးရေးသား';
      case AgentMode.taskerFinding:
        return 'ဖိုးရှာဖွေ';
      case AgentMode.taskHandling:
        return 'ဖိုးစောင့်ကြည့်';
      case AgentMode.taskAnalyzing:
        return 'ဖိုးအလုပ်ရှာ';
    }
  }

  /// One-line Burmese description of what this mode does.
  String get description {
    switch (this) {
      case AgentMode.overall:
        return 'သင်လိုချင်တဲ့ စာမျက်နှာကို လမ်းညွှန်ပေးပါတယ်။';
      case AgentMode.onboarding:
        return 'အသံဖြင့် အကောင့်ဖွင့်ခြင်းကို ကူညီပေးပါတယ်။';
      case AgentMode.taskPosting:
        return 'သင်ပြောတာကို အလုပ်တစ်ခုအဖြစ် ရေးပေးပါတယ်။';
      case AgentMode.taskerFinding:
        return 'သင့်အတွက် အကောင်းဆုံး အလုပ်သမားများ ရှာပေးပါတယ်။';
      case AgentMode.taskHandling:
        return 'အလုပ်အခြေအနေကို စောင့်ကြည့် သတိပေးပါတယ်။';
      case AgentMode.taskAnalyzing:
        return 'သင့်ကျွမ်းကျင်မှုနှင့် ကိုက်ညီတဲ့ အလုပ်များ ရှာပေးပါတယ်။';
    }
  }
}

/// Short Burmese-first copy for the agent shell (FAB long-press to sleep, etc.).
class AgentStrings {
  AgentStrings._();

  static const String fabLabel = 'ဖိုးဝရုပ် အကူအညီ';
  static const String sleptMessage = 'ဖိုးဝရုပ် ခဏ အနားယူပါမယ်။';
  static const String wakeAction = 'ပြန်နှိုးမည်';
  static const String longPressHint = 'အကြာကြီး ဖိထားရင် ဖိုးဝရုပ်ကို အနားပေးနိုင်ပါတယ်။';
}

/// Proactivity thresholds for the Task-Handling mode (spec §4.4/§4.8). These
/// are the spec §8 "open" knobs — set to gentle demo-friendly defaults here for
/// the human to tune later. Kept in one place so tuning is a one-file change.
class AgentThresholds {
  AgentThresholds._();

  /// A posted task with no taker for longer than this earns a gentle
  /// "make it more attractive" nudge (spec §4.4 Phase 1). Demo-friendly.
  static const int stalePostHours = 12;

  /// A tasker's accepted task within this many hours of its start time shows a
  /// gentle "do it in its window" reminder (spec §4.8). Non-blocking.
  static const int reminderLeadHours = 24;
}

/// The current session presence. Defaults to [AgentSession.wakie] (spec §3).
final agentSessionProvider =
    StateProvider<AgentSession>((ref) => AgentSession.wakie);

/// The current context mode. Defaults to [AgentMode.overall].
final agentModeProvider = StateProvider<AgentMode>((ref) => AgentMode.overall);
