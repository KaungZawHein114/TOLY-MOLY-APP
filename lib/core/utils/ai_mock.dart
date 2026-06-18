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
      "(${pick.rating}★, ${pick.distanceMiles} miles away, "
      "${pick.hourlyRateMmk} MMK/hr). Tap \"$skill\" on the home screen to book.";
}

// ----------------------------------------------------------------------------
// Internal keyword matcher — maps any free text to a known worker skill.
// ----------------------------------------------------------------------------
String _skillForQuery(String query) {
  final q = query.toLowerCase();

  const Map<String, List<String>> keywords = {
    "Plumber": ["sink", "leak", "pipe", "toilet", "water", "tap", "plumb", "drain"],
    "Electrician": ["light", "wire", "power", "fan", "electric", "socket", "breaker", "solar"],
    "AC Technician": ["ac", "air con", "aircon", "cooling", "cold", "gas refill"],
    "Cleaner": ["clean", "wash", "tidy", "dust", "laundry", "mop"],
    "Carpenter": ["wood", "furniture", "door", "cabinet", "shelf", "table", "carpent"],
    "Tutor": ["teach", "tutor", "study", "maths", "math", "english", "exam", "lesson"],
    "Gardener": ["garden", "plant", "lawn", "grass", "tree"],
    "Delivery": ["deliver", "parcel", "package", "send", "courier"],
    "Handyman": ["fix", "repair", "mount", "paint", "handy", "odd job"],
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
