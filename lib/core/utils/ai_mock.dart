// ============================================================================
// CORE FILE 2 of 2 — HARDCODED AI MOCKS ONLY
// ----------------------------------------------------------------------------
// Every function here is SYNCHRONOUS. No async/await, no Future, no HTTP,
// no API keys. Responses are derived from simple keyword matching against the
// hardcoded demo data so the demo always feels "smart" and never blocks.
// ============================================================================

import '../constants/task_posting_strings.dart' show TaskPostingStrings;
import '../data/demo_data.dart';
import '../../features/onboarding/onboarding_models.dart' show TaskerSkill;

/// Suggests a service category + a couple of nearby workers for a free-text
/// query. Pure keyword matching, returns instantly.
Map<String, dynamic> suggestService(String query) {
  final skill = _skillForQuery(query);
  final matches = workers.where((w) => w.skill == skill).take(2).toList();
  return {
    "category": skill,
    "workers": matches.map((w) => w.name).toList(),
  };
}

/// Categorizes a free-text job description into a known skill.
String categorizeJob(String text) => _skillForQuery(text);

/// Pretends to extract structured data from a spoken sentence
/// (e.g. "I'm a plumber, 5 years"). Returns name/skill/experience.
Map<String, String> extractVoiceData(String spokenText) {
  final skill = _skillForQuery(spokenText);
  final years = _firstNumber(spokenText) ?? 5;
  return {
    "name": "Ko Aung",
    "skill": skill,
    "experience": "$years years",
  };
}

/// Pretends to OCR an NRC card image. Returns fixed demo identity.
Map<String, String> extractNrcData(String imagePath) {
  return {
    "name": "Ko Aung",
    "nrc_number": "12/MaYaKa(N)123456",
  };
}

/// Generates an instant chatbot reply for the support/assistant screen.
String chatbotReply(String userMessage) {
  final lower = userMessage.toLowerCase();

  if (_isGreeting(lower)) {
    return "Hi! 👋 I'm the TOLY MOLY assistant. Tell me what you need help with "
        "— like \"fix my sink\" or \"clean my apartment\".";
  }

  final skill = _skillForQuery(userMessage);
  final matches = workers.where((w) => w.skill == skill && w.isAvailableNow).toList();
  final pick = matches.isNotEmpty ? matches.first : workers.first;

  return "Sounds like a $skill job. I recommend ${pick.name} "
      "(${pick.rating}★, ${pick.distanceMiles} miles away). "
      "Tap \"$skill\" on the home screen to book.";
}

/// Fixed off-topic refusal — mirrors the Cloud Function's wording so the app
/// behaves identically whether the reply came from OpenAI or this mock.
const String chatOffTopicReply =
    "ဤအက်ပ်အသုံးပြုခြင်း၊ အလုပ်တင်ခြင်း သို့မဟုတ် အလုပ်သမားဝန်ဆောင်မှုများနှင့် "
    "သက်ဆိုင်သော မေးခွန်းများကိုသာ ကူညီပေးနိုင်ပါသည်။ "
    "(I can only help with questions related to using this app, tasks, or tasker services.)";

/// Offline fallback for the in-app assistant (used when the `chatAssistant`
/// Cloud Function is unavailable). Fully synchronous. Mirrors the server's
/// rule-based logic: an app-topic gate (off-topic → refusal) and rule-based
/// intent detection — the model is never trusted to decide either.
///
/// Returns a short reply plus [action] ("post_task" | "find_task" | null) for
/// the inline button, and [intent] ("post_task" | "find_task" | "general" |
/// "off_topic") for the forward-compatible response shape.
///
/// [role] ("client" | "tasker") only breaks ties when the message could be read
/// either way.
({String message, String? action, String intent}) chatAssistantReply(
  String userMessage,
  String role,
) {
  final lower = userMessage.toLowerCase();

  // App-topic gate: only answer app/task/service questions (greetings allowed),
  // else refuse — same authoritative guard the Cloud Function applies.
  if (!_isAppTopic(lower) && !_isGreeting(lower)) {
    return (message: chatOffTopicReply, action: null, intent: 'off_topic');
  }

  if (_isGreeting(lower)) {
    return (
      message: "မင်္ဂလာပါ။ 👋 TOLY MOLY အကူအညီပေးသူပါ။ "
          "ဘာများ ကူညီပေးရမလဲ — \"sink ပြင်ချင်တယ်\" သို့မဟုတ် "
          "\"plumbing jobs ရှာချင်တယ်\" လို ပြောနိုင်ပါတယ်။",
      action: null,
      intent: 'general',
    );
  }

  // Rule-based intent — mirrors intent_service.js detectIntent exactly so the
  // offline and online classifications agree.
  final intent = _detectMockIntent(lower, role);

  if (intent == 'find_task') {
    final skill = _skillForQuery(userMessage);
    return (
      message: "$skill အလုပ်တွေ ရှာပေးနိုင်ပါတယ်။ "
          "အောက်က \"Find a Task\" ကို နှိပ်ပြီး Dashboard ရှာဖွေမှုဘားတွင် ကြည့်နိုင်ပါတယ်။",
      action: 'find_task',
      intent: 'find_task',
    );
  }
  if (intent == 'post_task') {
    final skill = _skillForQuery(userMessage);
    final matches =
        workers.where((w) => w.skill == skill && w.isAvailableNow).toList();
    final pick = matches.isNotEmpty ? matches.first : workers.first;
    return (
      message: "$skill အလုပ်တစ်ခု တင်နိုင်ပါတယ်။ "
          "${pick.name} (${pick.rating}★) လို ကျွမ်းကျင်သူများ ရှိပါတယ်။ "
          "အောက်က \"Post a Task\" ကို နှိပ်ပါ။",
      action: 'post_task',
      intent: 'post_task',
    );
  }
  if (intent == 'find_tasker') {
    final skill = _skillForQuery(userMessage);
    return (
      message: "$skill ကျွမ်းကျင်သူများ ရှာပေးနိုင်ပါတယ်။ "
          "အောက်က \"Browse Workers\" ကို နှိပ်ပြီး ရွေးချယ်နိုင်ပါတယ်။",
      action: 'find_tasker',
      intent: 'find_tasker',
    );
  }
  if (intent == 'edit_profile') {
    return (
      message: "သင့်ပရိုဖိုင်ကို ပြင်နိုင်ပါတယ်။ "
          "အောက်က \"Edit Profile\" ကို နှိပ်ပါ။",
      action: 'edit_profile',
      intent: 'edit_profile',
    );
  }

  // On-topic but no clear intent — general guidance, no action button.
  return (
    message: "TOLY MOLY တွင် အလုပ်တင်ခြင်း၊ အလုပ်ရှာခြင်းနှင့် အလုပ်သမားများအကြောင်း "
        "ကူညီပေးနိုင်ပါတယ်။ ဘာများ သိချင်ပါသလဲ။",
    action: null,
    intent: 'general',
  );
}

// App-topic vocabulary — kept narrow so off-topic questions (general
// knowledge, math, news) fall through to the refusal.
const List<String> _appWords = [
  "task", "tasks", "post", "job", "jobs", "worker", "tasker", "client",
  "book", "booking", "hire", "search", "price", "budget", "cost", "pay",
  "rate", "rating", "review", "tier", "verify", "verified", "service",
  "category", "available", "tolymoly", "toly moly", "dashboard",
  // Phase 2: knowledge-base topics — kept in sync with the Cloud Function's
  // APP_WORDS (functions/services/intent_service.js) so the same FAQ/help
  // questions are treated as on-topic online (-> RAG) and offline (-> general).
  "payment", "premium", "refund", "cancel", "commission", "fee", "safety",
  "secure", "community", "rule", "rules", "report", "scam", "trust", "badge",
  "verification", "account", "profile", "password", "details", "feature",
  "support", "how to", "help",
  "အလုပ်", "အကူအညီ", "ကူညီ", "ဈေး", "ဈေးနှုန်း", "ငွေ", "ဝန်ဆောင်မှု",
  "အဆင့်", "ရှာ", "တင်", "ပရိုဖိုင်", "အချက်အလက်", "ဘွတ်ကင်",
  "ငွေပေးချေ", "လုံခြုံ", "စည်းမျဉ်း", "အကောင့်", "ယုံကြည်", "တိုင်ကြား", "ပရီမီယံ",
];

// Wanting a job DONE / hiring someone → post a task.
const List<String> _postWords = [
  "need", "i need", "fix", "repair", "broken", "leak", "not working",
  "install", "hire", "book a", "post a task", "post task", "someone to",
  "get someone", "come and", "help me fix",
  "လိုအပ်", "ပြင်ပေး", "တပ်ဆင်", "တင်ချင်", "ငှား", "လာပြင်",
];

// Wanting to find work / jobs → find a task.
const List<String> _findWords = [
  "find job", "find jobs", "find task", "find tasks", "find work",
  "job", "jobs", "work near", "looking for work", "want work", "want job",
  "more jobs", "get jobs", "near me",
  "အလုပ်ရှာ", "အလုပ်လို", "အလုပ်ရှာဖွေ", "အလုပ်ရ",
];

// CLIENT wants to browse/choose a worker → worker list (Slice 3, spec §4.5).
// Mirrors intent_service.js FIND_TASKER_WORDS; kept free of "hire".
const List<String> _findTaskerWords = [
  "find a worker", "find worker", "find a tasker", "find tasker",
  "browse workers", "show workers", "see workers", "workers list",
  "list of workers", "find someone to", "recommend a worker", "best worker",
  "find a plumber", "find a cleaner", "find an electrician", "find a carpenter",
  "find a gardener", "find a handyman", "find a tutor", "find a mover",
  "find a painter",
  "အလုပ်သမား ရှာ", "အလုပ်သမားရှာ", "လုပ်သားရှာ", "ဝန်ဆောင်မှုပေးသူ ရှာ",
];

// Wants to edit their own profile/account → profile screen. Mirrors EDIT_WORDS.
const List<String> _editWords = [
  "edit profile", "edit my profile", "update profile", "update my profile",
  "change my profile", "edit account", "update account", "change password",
  "update my details", "edit my details",
  "ပရိုဖိုင်ပြင်", "ပရိုဖိုင် ပြင်", "အကောင့်ပြင်", "အကောင့် ပြင်", "အချက်အလက်ပြင်",
];

/// Rule-based intent — a faithful port of intent_service.js `detectIntent`.
/// Returns "post_task" | "find_task" | "find_tasker" | "edit_profile" |
/// "general". [role] ("client" | "tasker") breaks ties.
String _detectMockIntent(String lower, String role) {
  if (_hasAny(lower, _editWords)) return 'edit_profile';

  final wantsPost = _hasAny(lower, _postWords);
  final wantsFind = _hasAny(lower, _findWords);

  if (role == 'tasker') {
    if (wantsFind) return 'find_task';
    if (wantsPost) return 'post_task';
    return 'general';
  }

  final wantsFindTasker = _hasAny(lower, _findTaskerWords);
  if (wantsFindTasker && !wantsPost) return 'find_tasker';
  if (wantsPost && !wantsFind) return 'post_task';
  if (wantsFind && !wantsPost) return 'find_task';
  if (wantsPost && wantsFind) return 'post_task';
  if (wantsFindTasker) return 'find_tasker';
  return 'general';
}

bool _isAppTopic(String lower) {
  if (_matchesServiceKeyword(lower)) return true;
  return _hasAny(lower, _appWords);
}

bool _hasAny(String lower, List<String> words) {
  for (final w in words) {
    if (lower.contains(w)) return true;
  }
  return false;
}

/// Generates a plausible Burmese task description for the task-posting
/// flow's "AI က ရေးပေးမည်" button. Purely templated by [category] — the
/// free-text [userInput] is accepted for symmetry with a future real model
/// but not otherwise inspected here.
String generateTaskDescription(String category, String userInput) {
  const templates = {
    "Plumber": "အိမ်တွင် ရေပိုက်ယိုနေပါသည်။ ပိုက်ပြင်ကျွမ်းကျင်သူ လိုအပ်ပါသည်။",
    "Electrician": "အိမ်တွင် မီးဖိုင်ပြဿနာ ရှိနေပါသည်။ လျှပ်စစ်ကျွမ်းကျင်သူ လိုအပ်ပါသည်။",
    "AC Technician": "အဲယားကွန်း အေးမှု မရှိတော့ပါ။ ပြင်ဆင်ရန် ကျွမ်းကျင်သူ လိုအပ်ပါသည်။",
    "Cleaner": "အိမ်ကို သေချာစွာ သန့်ရှင်းရေး လုပ်ပေးစရာ လိုအပ်ပါသည်။",
    "Carpenter": "ပရိဘောဂ ပြုပြင်ရန် လက်သမား ကျွမ်းကျင်သူ လိုအပ်ပါသည်။",
    "Tutor": "ကျောင်းသားအတွက် ကျူရှင်ဆရာ/ဆရာမ လိုအပ်ပါသည်။",
    "Gardener": "ဥယျာဉ်ထဲရှိ အပင်များကို ပြုစုပေးရန် လိုအပ်ပါသည်။",
    "Delivery": "ပစ္စည်းတစ်ခုကို ပို့ဆောင်ပေးရန် လိုအပ်ပါသည်။",
    "Handyman": "အိမ်တွင်း ပြင်ဆင်စရာများအတွက် အကူအညီ လိုအပ်ပါသည်။",
  };
  return templates[category] ?? "အကူအညီတစ်ခု လိုအပ်ပါသည်။ အသေးစိတ် ဖော်ပြပေးပါ။";
}

// ----------------------------------------------------------------------------
// Onboarding voice mode (Slice 2, spec §4.1/§4.6) — synchronous OFFLINE extract.
// ----------------------------------------------------------------------------
// Best-effort keyword/regex extraction from a spoken self-introduction, the
// offline fallback for AiService.extractOnboarding. It NEVER invents: a field it
// can't confidently read is left blank/null so the user fills it manually. Names
// are hard to parse reliably offline, so `name` is intentionally left empty
// (the user types it). Returns primitives; the service maps them to enums,
// mirroring how matchTaskersMock's records become TaskerMatch.

/// Skill keywords for offline extraction, keyed by [TaskerSkill.name].
const Map<TaskerSkill, List<String>> _taskerSkillKeywords = {
  TaskerSkill.cleaning: [
    "clean", "wash", "tidy", "mop", "သန့်ရှင်း", "ဖွတ်", "ရှင်းလင်း",
  ],
  TaskerSkill.electrical: [
    "electric", "wire", "light", "fan", "power", "လျှပ်စစ်", "မီး", "ဝိုင်ယာ", "ပန်ကာ",
  ],
  TaskerSkill.plumbing: [
    "plumb", "pipe", "water", "leak", "tap", "ပိုက်", "ရေ", "ရေယို",
  ],
  TaskerSkill.delivery: [
    "deliver", "parcel", "courier", "send", "ပို့", "ပါဆယ်", "ပို့ဆောင်",
  ],
  TaskerSkill.petCare: [
    "pet", "dog", "cat", "အိမ်မွေး", "ခွေး", "ကြောင်", "တိရစ္ဆာန်",
  ],
  TaskerSkill.moving: [
    "moving", "move", "shift", "ရွှေ့", "ပြောင်း", "သယ်", "ပစ္စည်းရွှေ့",
  ],
  TaskerSkill.painting: [
    "paint", "ဆေးသုတ်", "ဆေး",
  ],
};

/// Offline onboarding extraction. Returns primitives; `gender` is one of
/// 'male'|'female'|'other' or null; `skillIds` are [TaskerSkill.name] values,
/// only populated when [isTasker]. `name` is always '' (see note above).
({String name, String? gender, int? age, String phone, List<String> skillIds})
    extractOnboardingMock(String transcript, {required bool isTasker}) {
  final lower = transcript.toLowerCase();
  // Burmese speech-to-text may return Burmese numerals — normalise to ASCII so
  // the phone/age regexes (which use \d) can read them.
  final normalized = _asciiDigits(transcript);

  // Phone: a 7–11 digit run (optionally starting 09). Take the longest match.
  String phone = '';
  for (final m in RegExp(r'\d[\d\s-]{6,}\d').allMatches(normalized)) {
    final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 7 && digits.length > phone.length) phone = digits;
  }

  // Age: a plausible standalone number NOT part of the phone run.
  int? age;
  for (final m in RegExp(r'\b(\d{1,3})\b').allMatches(normalized)) {
    final n = int.tryParse(m.group(1)!);
    if (n != null && n >= 15 && n <= 90 && !phone.contains(m.group(1)!)) {
      age = n;
      break;
    }
  }

  // Gender by keyword (Burmese/English).
  String? gender;
  if (_hasAny(lower, const ['အမျိုးသမီး', 'မိန်းမ', 'မိန်းကလေး', 'female', 'woman', 'lady'])) {
    gender = 'female';
  } else if (_hasAny(
      lower, const ['အမျိုးသား', 'ယောက်ျား', 'ကျား', 'male', 'man', 'boy'])) {
    gender = 'male';
  }

  // Skills (tasker only): every skill whose keywords appear.
  final skillIds = <String>[];
  if (isTasker) {
    for (final entry in _taskerSkillKeywords.entries) {
      if (_hasAny(lower, entry.value)) skillIds.add(entry.key.name);
    }
  }

  return (name: '', gender: gender, age: age, phone: phone, skillIds: skillIds);
}

// ----------------------------------------------------------------------------
// Task-Handling mode (Slice 4, spec §4.4/§4.8) — synchronous OFFLINE fallbacks.
// ----------------------------------------------------------------------------
// Wording only (no ranking of real entities). Each mirrors its Cloud Function's
// response shape and stays fully templated from the task fields.

/// Stale-post fixes (client, §4.4 Phase 1). 2–4 short templated Burmese tips.
List<String> taskFixTipsMock(Map<String, dynamic> task, int ageHours) {
  final urgent = task['urgent'] == true;
  final desc = (task['description'] ?? '').toString();
  final tips = <String>[
    TaskPostingStrings.tipRaiseBudget,
    TaskPostingStrings.tipWidenTier,
    if (desc.trim().length < 40) TaskPostingStrings.tipAddDetail,
    if (!urgent) TaskPostingStrings.tipMarkUrgent,
  ];
  return tips.take(4).toList();
}

/// Tasker per-task brief (§4.8): a short "what the client wants" + prep/tools.
({String summary, List<String> suggestions}) taskerBriefMock(
  Map<String, dynamic> task,
) {
  final category = (task['category'] ?? task['skill'] ?? '').toString();
  final desc = (task['description'] ?? '').toString().trim();
  final summary =
      desc.isNotEmpty ? desc : generateTaskDescription(category, '');
  return (
    summary: summary,
    suggestions: <String>[
      TaskPostingStrings.briefPrepGeneric,
      TaskPostingStrings.briefPrepArriveEarly,
      TaskPostingStrings.briefPrepConfirm,
    ],
  );
}

/// Completion summary + SUGGESTED tier delta (§4.4 Phase 3). The delta is only a
/// recommendation in [-1, 1]; the real tier is decided by rules + client rating.
({String summary, int suggestedTierDelta, String rationale})
    completionSummaryMock({
  required Map<String, dynamic> task,
  required Map<String, dynamic> timing,
  required Map<String, dynamic> review,
}) {
  final rating = (review['rating'] is num)
      ? (review['rating'] as num).toDouble()
      : null;
  final onTime = timing['onTime'] == true;

  int delta;
  String rationale;
  if (rating != null && rating < 3) {
    delta = -1;
    rationale = TaskPostingStrings.completionRatingLow;
  } else if (onTime && (rating == null || rating >= 4.5)) {
    delta = 1;
    rationale = TaskPostingStrings.completionOnTime;
  } else {
    delta = 0;
    rationale = TaskPostingStrings.completionSummaryGeneric;
  }
  return (
    summary: TaskPostingStrings.completionSummaryGeneric,
    suggestedTierDelta: delta,
    rationale: rationale,
  );
}

// ----------------------------------------------------------------------------
// Tasker-Finding mode (Slice 1, spec §4.3) — deterministic OFFLINE fallback.
// ----------------------------------------------------------------------------
// The synchronous fallback for AiService.matchTaskers. It scores every
// candidate on REAL Worker fields (skill match, rating, distance, tier,
// completed tasks, availability, verification), sorts, and returns the top ≤3
// as (workerId, reason) records with a short, templated Burmese reason.
//
// Crucially it NEVER invents a tasker: every id returned is one of [candidates].
// The service maps these records into TaskerMatch, mirroring how
// chatAssistantReply's record is wrapped into ChatReply.

/// Weighted match score for [w] against a task in [category]. Higher is better.
/// Same field set the online prompt is told to weigh, so online and offline
/// rankings feel consistent.
double taskerMatchScore(Worker w, String category) {
  final skillMatch = (category.isNotEmpty && w.skill == category) ? 100.0 : 0.0;
  final ratingScore = w.rating / 5 * 100;
  // Closer is better; 0 miles -> 100, ~6.2 miles (10km) -> 0.
  final distanceScore = (100 - w.distanceMiles * 1.609 * 10).clamp(0, 100).toDouble();
  final tierScore = w.currentTier / 7 * 100;
  final completionScore = (w.completedTasks / 2).clamp(0, 100).toDouble();
  final availableBonus = w.isAvailableNow ? 100.0 : 0.0;
  final verifiedBonus = w.isVerified ? 100.0 : 0.0;
  return skillMatch * 0.35 +
      ratingScore * 0.20 +
      distanceScore * 0.15 +
      tierScore * 0.15 +
      completionScore * 0.05 +
      availableBonus * 0.06 +
      verifiedBonus * 0.04;
}

/// A short, one-line Burmese "why I picked them", built only from real fields.
String taskerMatchReason(Worker w, String category) {
  final parts = <String>[];
  if (category.isNotEmpty && w.skill == category) {
    parts.add(TaskPostingStrings.matchReasonSkill);
  }
  parts.add('${w.rating}${TaskPostingStrings.matchReasonRatingSuffix}');
  final km = (w.distanceMiles * 1.609).toStringAsFixed(1);
  parts.add('$km${TaskPostingStrings.matchReasonNearbySuffix}');
  if (w.isAvailableNow) {
    parts.add(TaskPostingStrings.matchReasonAvailable);
  } else if (w.currentTier >= 5) {
    parts.add(TaskPostingStrings.matchReasonTopTier);
  }
  // Keep it to a readable one-liner — at most three clauses.
  return '${parts.take(3).join('၊ ')}။';
}

/// Deterministic offline shortlist: the top ≤3 candidates for [task]. The
/// `category` key of [task] drives skill-match scoring. Stable id tiebreak
/// keeps the result reproducible for the demo (and tests).
List<({int workerId, String reason})> matchTaskersMock(
  Map<String, dynamic> task,
  List<Worker> candidates,
) {
  if (candidates.isEmpty) return const [];
  final category = (task['category'] ?? '').toString();
  final scored = [
    for (final w in candidates) (w: w, score: taskerMatchScore(w, category)),
  ]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.w.id.compareTo(b.w.id); // stable tiebreak -> deterministic
    });
  return [
    for (final e in scored.take(3))
      (workerId: e.w.id, reason: taskerMatchReason(e.w, category)),
  ];
}

// ----------------------------------------------------------------------------
// Voice task posting (demo) — scripted conversation + synchronous extraction.
// ----------------------------------------------------------------------------
// The voice posting flow is a DEMO: there is no speech engine and no model
// behind it. Pho Wa Yoke walks a fixed question script, and each answer (typed,
// tapped as a quick reply, or handed over by the mock mic) is read here with
// the same keyword matching the rest of this file uses. Nothing is invented:
// a field that can't be read falls back to an obvious, sensible default so the
// summary screen is never blank.

/// The fields the scripted conversation collects, in the order it asks for them.
enum VoiceTaskField { need, place, schedule, urgency, tier }

/// One scripted turn: what Pho Wa Yoke asks, the canned transcript the mock mic
/// "hears" for that turn, and tappable quick replies for keyboard-free demos.
typedef VoiceTaskQuestion = ({
  VoiceTaskField field,
  String question,
  String micTranscript,
  List<String> quickReplies,
});

/// The whole demo conversation, start to finish. Five short questions is enough
/// to fill every field the summary screen shows.
const List<VoiceTaskQuestion> taskVoiceScript = [
  (
    field: VoiceTaskField.need,
    question: "မင်္ဂလာပါ။ ကျွန်တော် ဖိုးဝရုပ်ပါ။ ဘာအကူအညီ လိုအပ်လဲ ပြောပြပါနော်။",
    micTranscript: "မီးဖိုချောင်က ရေပိုက် ယိုနေလို့ ပြင်ချင်ပါတယ်",
    quickReplies: [
      "ရေပိုက် ယိုနေတယ်",
      "အိမ် သန့်ရှင်းရေး လုပ်ချင်တယ်",
      "ပန်ကာ တပ်ချင်တယ်",
    ],
  ),
  (
    field: VoiceTaskField.place,
    question: "ရပါပြီ။ ဘယ်မြို့နယ်မှာလဲ ပြောပေးပါ။",
    micTranscript: "လှိုင် မြို့နယ်မှာ ပါ",
    quickReplies: ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း"],
  ),
  (
    field: VoiceTaskField.schedule,
    question: "ဘယ်အချိန် လိုအပ်ပါသလဲ။",
    micTranscript: "မနက်ဖြန် မနက်ပိုင်း ရောက်ပေးပါ",
    quickReplies: ["ဒီနေ့ ညနေ", "မနက်ဖြန် မနက်", "နောက်တစ်ပတ်"],
  ),
  (
    field: VoiceTaskField.urgency,
    question: "ဒါက အရေးပေါ် အလုပ်လား။",
    micTranscript: "မဟုတ်ပါဘူး၊ ပုံမှန်ပါ",
    quickReplies: ["ဟုတ်ကဲ့၊ အရေးပေါ်", "မဟုတ်ပါ"],
  ),
  (
    field: VoiceTaskField.tier,
    question: "ဘယ်လို အလုပ်သမား အဆင့် လိုချင်ပါသလဲ။",
    micTranscript: "အတည်ပြုပြီးသား လုပ်သား ဖြစ်ရင် ကောင်းမယ်",
    quickReplies: [
      TaskPostingStrings.tier1Label,
      TaskPostingStrings.tier3Label,
      TaskPostingStrings.tier5Label,
    ],
  ),
];

/// Pho Wa Yoke's closing line, spoken just before the summary screen opens.
const String voiceTaskWrapUpMessage =
    "ကျေးဇူးတင်ပါတယ်။ အချက်အလက်တွေ စုစည်းပြီးပါပြီ — အနှစ်ချုပ်ကို ပြပါမယ်နော်။";

/// Reads the "what do you need?" answer into a category, a short title and a
/// templated description. [answer] doubles as the title so the client's own
/// words survive to the summary.
({String category, String title, String description}) voiceTaskNeed(
  String answer,
) {
  final category = _skillForQuery(answer);
  final title = answer.trim();
  return (
    category: category,
    title: title.isEmpty ? generateTaskDescription(category, '') : title,
    description: generateTaskDescription(category, answer),
  );
}

/// Matches a spoken place against the Yangon township list. Anything we can't
/// recognise is kept verbatim as a free-text address instead of being dropped.
({String township, String address}) voiceTaskPlace(String answer) {
  final text = answer.trim();
  for (final t in TaskPostingStrings.yangonTownships) {
    if (text.contains(t)) return (township: t, address: text);
  }
  return (township: '', address: text);
}

/// Reads a spoken date/time into a concrete slot. Defaults to tomorrow morning
/// — the most common request — so the summary always has a real date.
({DateTime date, String timeSlot}) voiceTaskSchedule(String answer) {
  final lower = answer.toLowerCase();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var date = today.add(const Duration(days: 1));
  if (_hasAny(lower, const ["ဒီနေ့", "ယနေ့", "အခု", "today", "now"])) {
    date = today;
  } else if (_hasAny(lower, const ["နောက်တစ်ပတ်", "သီတင်းပတ်", "next week"])) {
    date = today.add(const Duration(days: 7));
  }

  var timeSlot = "09:00";
  if (_hasAny(lower, const ["ညနေ", "ည ", "afternoon", "evening", "night"])) {
    timeSlot = "17:00";
  } else if (_hasAny(lower, const ["နေ့လယ်", "မွန်းတည့်", "noon", "midday"])) {
    timeSlot = "12:00";
  }
  // An explicit hour ("၉ နာရီ" / "9am") always wins over the coarse guess.
  final hour = _firstNumber(_asciiDigits(answer));
  if (hour != null && hour >= 1 && hour <= 23) {
    final isPm = hour < 12 &&
        _hasAny(lower, const ["ညနေ", "pm", "afternoon", "evening"]);
    final normalized = isPm ? hour + 12 : hour;
    timeSlot = "${normalized.toString().padLeft(2, '0')}:00";
  }
  return (date: date, timeSlot: timeSlot);
}

/// True only on an explicit "yes, it's urgent" — silence means not urgent.
bool voiceTaskUrgent(String answer) {
  final lower = answer.toLowerCase();
  if (_hasAny(lower, const ["မဟုတ်", "မလို", "no", "not urgent", "ပုံမှန်"])) {
    return false;
  }
  return _hasAny(
      lower, const ["အရေးပေါ်", "မြန်မြန်", "ချက်ချင်း", "urgent", "asap", "yes"]);
}

/// Maps a spoken tier answer to a tier number, 1-7. Falls back to tier 3
/// ("အတည်ပြုပြီး လုပ်သား") — the safe middle of the ladder.
int voiceTaskTierNumber(String answer) {
  const labels = [
    TaskPostingStrings.tier1Label,
    TaskPostingStrings.tier2Label,
    TaskPostingStrings.tier3Label,
    TaskPostingStrings.tier4Label,
    TaskPostingStrings.tier5Label,
    TaskPostingStrings.tier6Label,
    TaskPostingStrings.tier7Label,
  ];
  final text = answer.trim();
  for (var i = 0; i < labels.length; i++) {
    if (text.contains(labels[i])) return i + 1;
  }
  final lower = text.toLowerCase();
  if (_hasAny(lower, const ["ထိပ်တန်း", "အကောင်းဆုံး", "best", "top"])) return 7;
  if (_hasAny(lower, const ["ကျွမ်းကျင်", "အဆင့်မြင့်", "expert", "pro"])) return 5;
  if (_hasAny(lower, const ["အသစ်", "စတင်", "သက်သာ", "cheap", "new"])) return 1;
  return 3;
}

// ----------------------------------------------------------------------------
// AI budget estimate — the client no longer types a price; the tasker level
// they pick determines it. Deterministic and offline: a per-category base rate
// scaled by the tier ladder, so every tier card can show its own figure.
// ----------------------------------------------------------------------------

const Map<String, int> _categoryBaseRateMmk = {
  "Plumber": 15000,
  "Electrician": 18000,
  "AC Technician": 25000,
  "Cleaner": 12000,
  "Carpenter": 20000,
  "Tutor": 15000,
  "Gardener": 12000,
  "Delivery": 8000,
  "Handyman": 15000,
};

/// Tier 1 (newest) → tier 7 (elite) price multipliers.
const List<double> _tierRateFactor = [0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75];

/// The AI's estimated budget in MMK for [category] at [tierNumber] (1-7),
/// rounded to the nearest 500 so it reads like a real quote. Urgent tasks carry
/// a 10% premium on top (the flat urgent platform fee is shown separately).
int estimateTaskBudgetMmk({
  required String category,
  required int tierNumber,
  bool urgent = false,
}) {
  final base = _categoryBaseRateMmk[category] ?? 15000;
  final factor = _tierRateFactor[(tierNumber - 1).clamp(0, 6)];
  final raw = base * factor * (urgent ? 1.1 : 1.0);
  return (raw / 500).round() * 500;
}

// ----------------------------------------------------------------------------
// Internal keyword matcher — maps any free text to a known worker skill.
// Lifted to file scope so the chatbot's app-topic gate can reuse the same set.
// ----------------------------------------------------------------------------
const Map<String, List<String>> _skillKeywords = {
  "Plumber": [
    "sink", "leak", "pipe", "toilet", "water", "tap", "plumb", "drain",
    "ရေယို", "ပိုက်", "ရေပိုက်", "ရေပန်း",
  ],
  "Electrician": [
    "light", "wire", "power", "fan", "electric", "socket", "breaker", "solar",
    "ceiling fan", "install",
    "မီး", "လျှပ်စစ်", "ပန်ကာ", "မီးပန်ကာ", "ခလုတ်",
  ],
  "AC Technician": [
    "ac", "air con", "aircon", "cooling", "cold", "gas refill",
    "အဲယားကွန်း", "လေအေး",
  ],
  "Cleaner": [
    "clean", "wash", "tidy", "dust", "laundry", "mop",
    "သန့်ရှင်း", "အိမ်ရှင်း", "ဖွတ်",
  ],
  "Carpenter": [
    "wood", "furniture", "door", "cabinet", "shelf", "table", "carpent",
    "လက်သမား", "ပရိဘောဂ",
  ],
  "Tutor": [
    "teach", "tutor", "study", "maths", "math", "english", "exam", "lesson",
    "ကျူရှင်", "သင်ကြား",
  ],
  "Gardener": [
    "garden", "plant", "lawn", "grass", "tree",
    "ဥယျာဉ်", "သစ်ပင်",
  ],
  "Delivery": [
    "deliver", "parcel", "package", "send", "courier", "grocer", "groceries",
    "ပို့ဆောင်", "ပါဆယ်", "ကုန်ပစ္စည်း", "ပို့ပေး",
  ],
  "Handyman": [
    "fix", "repair", "mount", "paint", "handy", "odd job", "move", "furniture",
    "ပြင်ဆင်", "ဆေးသုတ်", "ပြောင်းရွှေ့", "သယ်ပို့", "ပရိဘောဂ ရွှေ့",
  ],
};

String _skillForQuery(String query) {
  final q = query.toLowerCase();
  for (final entry in _skillKeywords.entries) {
    for (final kw in entry.value) {
      if (q.contains(kw)) return entry.key;
    }
  }
  return "Handyman"; // safe default — never empty
}

/// True if [lower] hits any known service keyword (any language).
bool _matchesServiceKeyword(String lower) {
  for (final list in _skillKeywords.values) {
    for (final kw in list) {
      if (lower.contains(kw)) return true;
    }
  }
  return false;
}

bool _isGreeting(String lower) {
  for (final g in const ["hi", "hello", "hey", "mingala", "မင်္ဂလာ"]) {
    if (lower.contains(g)) return true;
  }
  return false;
}

int? _firstNumber(String text) {
  final match = RegExp(r'\d+').firstMatch(text);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

/// Converts Burmese numerals (၀-၉) in [s] to ASCII digits (0-9). The inverse of
/// [toBurmeseDigits]; used so the onboarding extractor can read spoken numbers
/// regardless of which numeral set the speech engine returned.
String _asciiDigits(String s) {
  const burmese = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
  var out = s;
  for (var i = 0; i < burmese.length; i++) {
    out = out.replaceAll(burmese[i], '$i');
  }
  return out;
}
