// ============================================================================
// CORE FILE 2 of 2 — HARDCODED AI MOCKS ONLY
// ----------------------------------------------------------------------------
// Every function here is SYNCHRONOUS. No async/await, no Future, no HTTP,
// no API keys. Responses are derived from simple keyword matching against the
// hardcoded demo data so the demo always feels "smart" and never blocks.
// ============================================================================

import '../../features/customer/task_posting/task_posting_models.dart';
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

/// Deterministic mock budget suggestion for the task-posting flow's budget
/// screen. No randomness — the same inputs always reproduce the same numbers
/// across a demo run.
({int low, int high, int marketPercent}) suggestBudget(
  String category,
  bool urgent,
  WorkerTier tier,
  int workersNeeded,
) {
  const baseRanges = {
    "Plumber": (10000, 15000),
    "Electrician": (10000, 15000),
    "AC Technician": (15000, 25000),
    "Cleaner": (8000, 12000),
    "Carpenter": (15000, 25000),
    "Tutor": (10000, 15000),
    "Gardener": (8000, 12000),
    "Delivery": (5000, 8000),
    "Handyman": (10000, 15000),
  };
  const marketPercentByCategory = {
    "Plumber": 82,
    "Electrician": 79,
    "AC Technician": 75,
    "Cleaner": 88,
    "Carpenter": 74,
    "Tutor": 85,
    "Gardener": 80,
    "Delivery": 90,
    "Handyman": 77,
  };

  final (baseLow, baseHigh) = baseRanges[category] ?? (10000, 15000);
  final tierMultiplier = switch (tier) {
    WorkerTier.basic => 1.0,
    WorkerTier.trusted => 1.3,
    WorkerTier.expert => 1.7,
  };
  final urgentMultiplier = urgent ? 1.2 : 1.0;
  final totalMultiplier = tierMultiplier * urgentMultiplier * workersNeeded;

  return (
    low: (baseLow * totalMultiplier).round(),
    high: (baseHigh * totalMultiplier).round(),
    marketPercent: marketPercentByCategory[category] ?? 78,
  );
}

// ----------------------------------------------------------------------------
// Internal keyword matcher — maps any free text to a known worker skill.
// ----------------------------------------------------------------------------
String _skillForQuery(String query) {
  final q = query.toLowerCase();

  const Map<String, List<String>> keywords = {
    "Plumber": [
      "sink", "leak", "pipe", "toilet", "water", "tap", "plumb", "drain",
      "ရေယို", "ပိုက်", "ရေပိုက်", "ရေပန်း",
    ],
    "Electrician": [
      "light", "wire", "power", "fan", "electric", "socket", "breaker", "solar",
      "မီး", "လျှပ်စစ်", "ဖန်ပြာ",
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
      "deliver", "parcel", "package", "send", "courier",
      "ပို့ဆောင်", "ပါဆယ်",
    ],
    "Handyman": [
      "fix", "repair", "mount", "paint", "handy", "odd job",
      "ပြင်ဆင်", "ဆေးသုတ်",
    ],
  };

  for (final entry in keywords.entries) {
    for (final kw in entry.value) {
      if (q.contains(kw)) return entry.key;
    }
  }
  return "Handyman"; // safe default — never empty
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
