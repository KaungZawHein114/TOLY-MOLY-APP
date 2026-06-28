// ============================================================================
// Intent service — the AUTHORITATIVE, rule-based topic + intent gate.
// ----------------------------------------------------------------------------
// Extracted unchanged (plus one new helper) from index.js so the chatbot's
// decision logic lives in one focused module. The model is NEVER trusted to
// decide topic or intent — these rules are:
//   • free + deterministic (off-topic questions never reach OpenAI/Pinecone),
//   • kept in sync with the Flutter offline fallback (lib/core/utils/ai_mock.dart).
//
// Decision order used by chatAssistant:
//   off_topic  -> refuse (no model call)
//   greeting   -> friendly worded reply (no RAG, no action)
//   post_task  -> existing flow + action button   (NO RAG)
//   find_task  -> existing flow + action button   (NO RAG)
//   general    -> knowledge question  -> RAG       (NEW)
// ============================================================================

// Fixed off-topic refusal — mirrors ai_mock.dart's chatOffTopicReply.
const OFF_TOPIC_REPLY =
  "ဤအက်ပ်အသုံးပြုခြင်း၊ အလုပ်တင်ခြင်း သို့မဟုတ် အလုပ်သမားဝန်ဆောင်မှုများနှင့် " +
  "သက်ဆိုင်သော မေးခွန်းများကိုသာ ကူညီပေးနိုင်ပါသည်။ " +
  "(I can only help with questions related to using this app, tasks, or tasker services.)";

// Structured app knowledge for the LEGACY wording path (post/find/general
// fallback). Knowledge questions now go through RAG instead; this stays as the
// safe wording context when RAG is skipped or unavailable.
const KNOWLEDGE = [
  "TOLY MOLY connects clients with local workers (taskers) in Yangon for home services: plumbing, electrical, cleaning, AC, carpentry, tutoring, gardening, delivery, handyman.",
  "Clients post a task (category, location, date & time, description, budget); workers express interest and the client chooses one.",
  "Workers check in to become available, browse a job board filtered by their skill and trust tier, then tap 'Interested'.",
  "Trust is shown through ratings, reviews, verification badges and tiers (Community Helper, Verified Professional, Community Ambassador).",
  "Prices are in Myanmar Kyat (MMK); the app suggests a fair budget range.",
];

// Keyword rule sets — kept in sync with lib/core/utils/ai_mock.dart.
const SERVICE_KEYWORDS = [
  "sink", "leak", "pipe", "toilet", "water", "tap", "plumb", "drain",
  "light", "wire", "power", "fan", "electric", "socket", "breaker", "solar", "install",
  "ac", "air con", "aircon", "cooling", "cold",
  "clean", "wash", "tidy", "dust", "laundry", "mop",
  "wood", "furniture", "door", "cabinet", "shelf", "table", "carpent",
  "teach", "tutor", "study", "math", "english", "exam", "lesson",
  "garden", "plant", "lawn", "grass", "tree",
  "deliver", "parcel", "package", "courier", "grocer",
  "fix", "repair", "mount", "paint", "handy", "odd job",
  "ရေယို", "ပိုက်", "မီး", "လျှပ်စစ်", "ပန်ကာ", "အဲယားကွန်း", "သန့်ရှင်း",
  "လက်သမား", "ကျူရှင်", "ဥယျာဉ်", "ပို့ဆောင်", "ပြင်ဆင်",
];

// On-topic vocabulary. The FAQ/help/platform words at the end were ADDED for
// Phase 2 so genuine knowledge questions (payments, verification, premium,
// safety, community rules, …) pass the topic gate and reach RAG. Mirrored in
// ai_mock.dart's _appWords so the offline gate agrees.
const APP_WORDS = [
  "task", "post", "job", "jobs", "worker", "tasker", "client", "book", "booking",
  "hire", "search", "price", "budget", "cost", "pay", "rate", "rating", "review",
  "tier", "verify", "verified", "service", "category", "available", "tolymoly",
  "toly moly", "dashboard", "how do i", "how to", "help",
  // ── Phase 2: knowledge-base topics (route to RAG) ──
  "payment", "premium", "refund", "cancel", "commission", "fee", "safety",
  "secure", "community", "rule", "rules", "report", "scam", "trust", "badge",
  "verification", "account", "profile", "review", "feature", "support",
  "အလုပ်", "အကူအညီ", "ကူညီ", "ဈေး", "ငွေ", "ဝန်ဆောင်မှု", "အဆင့်", "ရှာ", "တင်", "ပရိုဖိုင်",
  "ငွေပေးချေ", "လုံခြုံ", "စည်းမျဉ်း", "အကောင့်", "ယုံကြည်", "တိုင်ကြား", "ပရီမီယံ",
];

const POST_WORDS = [
  "need", "i need", "fix", "repair", "broken", "leak", "not working", "install",
  "hire", "book a", "post a task", "post task", "someone to", "get someone",
  "come and", "help me fix",
  "လိုအပ်", "ပြင်ပေး", "တပ်ဆင်", "တင်ချင်", "ငှား", "လာပြင်",
];

const FIND_WORDS = [
  "find job", "find jobs", "find task", "find tasks", "find work", "job", "jobs",
  "work near", "looking for work", "want work", "want job", "more jobs",
  "get jobs", "near me",
  "အလုပ်ရှာ", "အလုပ်လို", "အလုပ်ရှာဖွေ", "အလုပ်ရ",
];

const hasAny = (lower, words) => words.some((w) => lower.includes(w));
const isGreeting = (lower) =>
  ["hi", "hello", "hey", "mingala", "မင်္ဂလာ"].some((g) => lower.includes(g));
const isAppTopic = (lower) =>
  hasAny(lower, SERVICE_KEYWORDS) || hasAny(lower, APP_WORDS);

// Rule-based intent: "post_task" | "find_task" | "general". role breaks ties.
function detectIntent(lower, role) {
  const wantsPost = hasAny(lower, POST_WORDS);
  const wantsFind = hasAny(lower, FIND_WORDS);
  if (wantsPost && !wantsFind) return "post_task";
  if (wantsFind && !wantsPost) return "find_task";
  if (wantsPost && wantsFind) return role === "tasker" ? "find_task" : "post_task";
  return "general";
}

// A knowledge question = on-topic, not a greeting, and not a post/find action.
// These (and only these) are routed to the RAG pipeline.
function isKnowledgeQuestion(lower, intent) {
  return isAppTopic(lower) && !isGreeting(lower) && intent === "general";
}

// Defense in depth on the MODEL's reply: reject empty / oversized output.
function isAllowedResponse(reply) {
  return !!reply && reply.trim().length > 0 && reply.length <= 1200;
}

// Safe wording used when OpenAI is unavailable OR its reply is rejected.
function templateMessage(intent) {
  switch (intent) {
    case "post_task":
      return 'အလုပ်တစ်ခု တင်နိုင်ပါတယ်။ အောက်က "Post a Task" ကို နှိပ်ပါ။';
    case "find_task":
      return 'အလုပ်များ ရှာနိုင်ပါတယ်။ အောက်က "Find a Task" ကို နှိပ်ပြီး Dashboard ရှာဖွေမှုဘားတွင် ကြည့်ပါ။';
    default:
      return "TOLY MOLY တွင် အလုပ်တင်ခြင်း၊ အလုပ်ရှာခြင်းနှင့် အလုပ်သမားများအကြောင်း ကူညီပေးနိုင်ပါတယ်။";
  }
}

const intentToAction = (intent) =>
  intent === "post_task" || intent === "find_task" ? intent : null;

module.exports = {
  OFF_TOPIC_REPLY,
  KNOWLEDGE,
  hasAny,
  isGreeting,
  isAppTopic,
  detectIntent,
  isKnowledgeQuestion,
  isAllowedResponse,
  templateMessage,
  intentToAction,
};
