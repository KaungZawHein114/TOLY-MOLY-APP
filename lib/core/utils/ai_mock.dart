// ============================================================================
// CORE FILE 2 of 2 — HARDCODED AI MOCKS ONLY
// ----------------------------------------------------------------------------
// Every function here is SYNCHRONOUS. No async/await, no Future, no HTTP,
// no API keys. Responses are derived from simple keyword matching against the
// hardcoded demo data so the demo always feels "smart" and never blocks.
// ============================================================================

import '../data/demo_data.dart';

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

  // Rule-based intent (role only breaks ties).
  final wantsPost = _hasAny(lower, _postWords);
  final wantsFind = _hasAny(lower, _findWords);
  String intent;
  if (wantsPost && !wantsFind) {
    intent = 'post_task';
  } else if (wantsFind && !wantsPost) {
    intent = 'find_task';
  } else if (wantsPost && wantsFind) {
    intent = role == 'tasker' ? 'find_task' : 'post_task';
  } else {
    intent = 'general';
  }

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
  "verification", "account", "feature", "support", "how to", "help",
  "အလုပ်", "အကူအညီ", "ကူညီ", "ဈေး", "ဈေးနှုန်း", "ငွေ", "ဝန်ဆောင်မှု",
  "အဆင့်", "ရှာ", "တင်", "ပရိုဖိုင်", "ဘွတ်ကင်",
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
