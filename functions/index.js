// ============================================================================
// TOLY MOLY — Cloud Functions entry point
// ----------------------------------------------------------------------------
// Five callable functions that proxy OpenAI (and, for chat, Pinecone) so the
// API keys NEVER ship in the Flutter app. The app (lib/core/utils/ai_service.dart)
// calls these by name and automatically falls back to its offline mock if any
// of them fail — so a missing key, a cold start, or a rate limit can never break
// the demo.
//
//   suggestCategory({ title, categories })        -> { category }
//   rewriteDescription({ title, category, ... })   -> { description }
//   analyzePrice({ title, category, ... })         -> { low, high, currency }
//   evaluateTask({ title, category, ... })         -> { score, strengths, ... }
//   chatAssistant({ message, role, history })      -> { intent, action, message }
//   matchTaskers({ task, candidates })             -> { matches: [{ id, reason }] }
//   extractOnboarding({ role, transcript, ... })   -> { name, gender, age, phone, skills }
//   suggestTaskFixes({ task, ageHours })           -> { tips: [..] }
//   summarizeCompletion({ task, timing, review })  -> { summary, suggestedTierDelta, rationale }
//   briefTasker({ task })                          -> { summary, suggestions: [..] }
//
// Phase 2: chatAssistant now answers KNOWLEDGE/FAQ questions with RAG (Pinecone
// retrieval + OpenAI). Post-task / find-task / greeting / off-topic behaviour is
// UNCHANGED and the response shape { intent, action, message } is identical, so
// the Flutter app needs no changes. See functions/RAG.md for setup.
//
// Modules:
//   services/openai_service.js     shared OpenAI client + JSON/text helpers
//   services/embedding_service.js  OpenAI embeddings
//   services/pinecone_service.js   Pinecone client + similarity search
//   services/prompt_service.js     loads prompts/*.txt templates
//   services/rag_service.js        embed -> retrieve -> ground -> answer
//   services/intent_service.js     authoritative topic + intent rules
// ============================================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const openai = require("./services/openai_service");
const rag = require("./services/rag_service");
const intent = require("./services/intent_service");

// Secrets live in Firebase's encrypted store, never in code. Set them with:
//   firebase functions:secrets:set OPENAI_API_KEY
//   firebase functions:secrets:set PINECONE_API_KEY
//   firebase functions:secrets:set PINECONE_INDEX
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const PINECONE_API_KEY = defineSecret("PINECONE_API_KEY");
const PINECONE_INDEX = defineSecret("PINECONE_INDEX");

// Task Scoper functions only need OpenAI — unchanged from Phase 1, so deploying
// them gains no new secret dependency.
const taskOptions = {
  secrets: [OPENAI_API_KEY],
  timeoutSeconds: 30,
  memory: "256MiB",
};

// The chatbot additionally needs Pinecone for RAG.
const chatOptions = {
  secrets: [OPENAI_API_KEY, PINECONE_API_KEY, PINECONE_INDEX],
  timeoutSeconds: 30,
  memory: "256MiB",
};

// ── 1. Suggest a category from the task title ───────────────────────────────
exports.suggestCategory = onCall(taskOptions, async (request) => {
  const { title, categories } = request.data || {};
  if (!title || !Array.isArray(categories) || categories.length === 0) {
    throw new HttpsError("invalid-argument", "title and categories required.");
  }
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You categorize home-service task titles for a Yangon, Myanmar marketplace. " +
      "The title may be in Burmese or English. Choose the SINGLE best-fitting " +
      "category from the provided list. You MUST pick one value exactly as it " +
      'appears in the list. Respond as JSON: {"category": "<one value from the list>"}.',
    { title, categories }
  );
  // Never return a value outside the app's known list.
  const category = categories.includes(result.category)
    ? result.category
    : categories[0];
  return { category };
});

// ── 2. Rewrite the description into a clear, professional post ───────────────
exports.rewriteDescription = onCall(taskOptions, async (request) => {
  const { title, category, location, urgent, currentText } = request.data || {};
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You write clear, polite, professional task descriptions in BURMESE for a " +
      "Yangon home-service marketplace. Improve clarity, structure and " +
      "completeness without inventing facts the user did not provide. Keep it " +
      'to 2–4 short sentences. Respond as JSON: {"description": "<burmese text>"}.',
    { title, category, location, urgent: !!urgent, currentText: currentText || "" }
  );
  const description = (result.description || "").toString().trim();
  if (!description) {
    throw new HttpsError("internal", "Empty description from model.");
  }
  return { description };
});

// ── 3. Recommend a price band (MMK) ─────────────────────────────────────────
exports.analyzePrice = onCall(taskOptions, async (request) => {
  const { title, category, description, location, urgent } = request.data || {};
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You estimate a fair price range in Myanmar Kyat (MMK) for a home-service " +
      "task in Yangon, based on the task details. Give a realistic LOW and HIGH " +
      "whole-number amount (no decimals, no separators). Urgent tasks cost more. " +
      'Respond as JSON: {"low": <int>, "high": <int>, "currency": "MMK"}.',
    {
      title: title || "",
      category: category || "",
      description: description || "",
      location: location || "",
      urgent: !!urgent,
    }
  );
  const low = Math.round(Number(result.low));
  const high = Math.round(Number(result.high));
  if (!Number.isFinite(low) || !Number.isFinite(high) || low <= 0 || high < low) {
    throw new HttpsError("internal", "Invalid price range from model.");
  }
  return { low, high, currency: "MMK" };
});

// ── 4. Score the task's attractiveness to workers (0–100) ───────────────────
exports.evaluateTask = onCall(taskOptions, async (request) => {
  const task = request.data || {};
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You are a marketplace quality assistant. Score how attractive this task is " +
      "to workers on a Yangon home-service app, from 0 to 100, considering " +
      "completeness, clarity, fair budget, schedule and urgency. Then give short " +
      "BURMESE bullet points. Respond as JSON: " +
      '{"score": <int 0-100>, "strengths": [..], "weaknesses": [..], "missing": [..]}. ' +
      "Each list has 0–3 short items.",
    task
  );
  let score = Math.round(Number(result.score));
  if (!Number.isFinite(score)) score = 0;
  score = Math.max(0, Math.min(100, score));
  const asList = (v) =>
    Array.isArray(v) ? v.map((x) => String(x)).filter((x) => x.trim()) : [];
  return {
    score,
    strengths: asList(result.strengths),
    weaknesses: asList(result.weaknesses),
    missing: asList(result.missing),
  };
});

// ── 5. In-app assistant chatbot (app-scoped, intent-aware, RAG-backed) ───────
// Decision flow (topic + intent decided by RULES, never the model):
//   1. off-topic            -> refuse, no model/Pinecone call
//   2. post_task / find_task -> existing wording + action button (NO RAG)
//   3. greeting             -> friendly worded reply (NO RAG)
//   4. knowledge question   -> RAG (Pinecone retrieval -> grounded OpenAI answer)
//        └─ if the KB doesn't cover it -> general assistant fallback below
//           (answers app questions from its own knowledge; off-topic is already
//            blocked at step 1, so this can't be abused to answer non-app topics)
// Always returns { intent, action, message } — unchanged contract.
exports.chatAssistant = onCall(chatOptions, async (request) => {
  const { message, role, history } = request.data || {};
  const text = (message || "").toString().trim();
  if (!text) {
    throw new HttpsError("invalid-argument", "message required.");
  }
  const userRole = role === "tasker" ? "tasker" : "client";
  const lower = text.toLowerCase();

  // 1) RULE-BASED GUARDRAIL — off-topic questions never reach a model.
  if (!intent.isAppTopic(lower) && !intent.isGreeting(lower)) {
    return { intent: "off_topic", action: null, message: intent.OFF_TOPIC_REPLY };
  }

  // 2) RULE-BASED INTENT — deterministic, not delegated to the model.
  const detected = intent.isGreeting(lower)
    ? "general"
    : intent.detectIntent(lower, userRole);
  const action = intent.intentToAction(detected);

  // 3) KNOWLEDGE QUESTION -> RAG. Only FAQ/help/platform questions land here
  //    (post/find keep their action flow; greetings are excluded). On ANY RAG
  //    infrastructure failure we fall through to the legacy wording path below,
  //    so the chatbot degrades to exactly its Phase-1 behaviour — never breaks.
  if (intent.isKnowledgeQuestion(lower, detected)) {
    try {
      const result = await rag.answer({
        openAiKey: OPENAI_API_KEY.value(),
        pineconeKey: PINECONE_API_KEY.value(),
        pineconeIndex: PINECONE_INDEX.value(),
        question: text,
      });
      // Only use the RAG answer when the knowledge base actually covered the
      // question. If it didn't (found === false), DON'T dead-end the user with
      // "not in my knowledge base" — fall through to the general assistant so a
      // simple app question still gets a helpful answer.
      if (result.found) {
        return { intent: "general", action: null, message: result.message };
      }
    } catch (err) {
      // RAG unavailable (no Pinecone, cold start, rate limit, …) — fall through.
      console.error("RAG failed, using general assistant:", err);
    }
  }

  // 4) WORDING PATH — used for post_task / find_task / greeting, and as the
  //    general-assistant fallback for knowledge questions the KB didn't cover.
  //    OpenAI words the reply; it's validated, with a templated fallback so a
  //    bad/missing reply can't break the demo or escape the app's scope.
  let replyMessage = intent.templateMessage(detected);
  try {
    const recent = Array.isArray(history)
      ? history
          .slice(-6)
          .map((m) => ({
            role: m && m.role === "user" ? "user" : "assistant",
            text: (m && m.text ? m.text : "").toString().slice(0, 500),
          }))
          .filter((m) => m.text)
      : [];

    // For a "general" question (an on-topic question not covered by the KB), let
    // the assistant answer from its own understanding of how the app works —
    // staying in-scope and avoiding invented specifics. For post/find/greeting
    // we keep the original tight, intent-focused wording prompt.
    const systemPrompt =
      detected === "general"
        ? "You are Pho Wa Yoke, the friendly in-app assistant for TOLY MOLY, a " +
          "home-service marketplace in Yangon, Myanmar that connects clients " +
          "with local workers (taskers). Core facts about the app:\n- " +
          intent.KNOWLEDGE.join("\n- ") +
          "\nThe user asked an on-topic question (user role: " +
          userRole +
          ") that isn't in the knowledge base. Answer it as helpfully and " +
          "accurately as you can, in a short (1–3 sentences), friendly, " +
          "Burmese-first reply. Use the facts above plus sensible general " +
          "knowledge of how such an app works. Do NOT invent specific prices, " +
          "fees, or policies the app may not have — if you're unsure of a " +
          "specific detail, give general guidance or suggest contacting " +
          "support. Never answer anything unrelated to this app. " +
          'Respond as JSON: {"message": "<reply>"}.'
        : "You are the in-app assistant for TOLY MOLY, a home-service " +
          "marketplace in Yangon, Myanmar. Use ONLY these facts; never invent " +
          "policies:\n- " +
          intent.KNOWLEDGE.join("\n- ") +
          '\nThe user\'s question is already confirmed on-topic and its intent ' +
          'is "' +
          detected +
          '" (user role: ' +
          userRole +
          "). Write a short (1–3 sentences), friendly, Burmese-first reply " +
          "that helps with that intent. Do NOT answer anything unrelated to " +
          'this app. Respond as JSON: {"message": "<reply>"}.';

    const result = await openai.askJson(OPENAI_API_KEY.value(), systemPrompt, {
      message: text,
      intent: detected,
      role: userRole,
      history: recent,
    });
    const candidate = (result.message || "").toString().trim();
    if (intent.isAllowedResponse(candidate)) {
      replyMessage = candidate;
    }
  } catch (err) {
    // Keep the templated message — a wording failure must never fail the call.
  }

  return { intent: detected, action, message: replyMessage };
});

// ── 6. Tasker-Finding: rank a shortlist of taskers, with reasons ────────────
// The APP pre-filters + scores candidates and passes them in. The model ONLY
// ranks and writes a one-line Burmese reason each; it may return AT MOST the
// ids that appear in `candidates` (same "constrain to the provided set" safety
// as suggestCategory). Any id not in the set is dropped, so a hallucinated
// tasker can never reach the UI. Every stat shown to the user is app data — the
// model never invents numbers. The Flutter app falls back to its deterministic
// offline sort if this fails, so it never hangs.
exports.matchTaskers = onCall(taskOptions, async (request) => {
  const { task, candidates } = request.data || {};
  if (!task || !Array.isArray(candidates) || candidates.length === 0) {
    throw new HttpsError("invalid-argument", "task and candidates required.");
  }

  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You match taskers to a home-service TASK for a Yangon, Myanmar marketplace. " +
      "You are given the task and a list of candidate taskers, each with an id and " +
      "REAL stats (skill, rating, distanceMiles, currentTier, completedTasks, " +
      "isAvailableNow, isVerified, township). Pick the BEST up to 3 candidates and, " +
      "for each, write a SHORT one-line reason in BURMESE that cites their real " +
      "strengths (skill match, high rating, nearby, availability, trust tier, " +
      "experience). You MUST only use ids that appear in the candidates list, and " +
      "you MUST NOT invent taskers or change any stat. Order best first. " +
      'Respond as JSON: {"matches": [{"id": <id from list>, "reason": "<burmese>"}]}, ' +
      "at most 3 items.",
    { task, candidates }
  );

  // Constrain to the provided set: map stringified id -> original id value so we
  // return the id in the same form the app sent (its int), and drop any id the
  // model made up or repeated.
  const byId = new Map(candidates.map((c) => [String(c && c.id), c && c.id]));
  const seen = new Set();
  const matches = [];
  const rawMatches = Array.isArray(result.matches) ? result.matches : [];
  for (const m of rawMatches) {
    if (!m) continue;
    const key = String(m.id);
    if (!byId.has(key) || seen.has(key)) continue;
    const reason = (m.reason || "").toString().trim();
    if (!reason) continue;
    seen.add(key);
    matches.push({ id: byId.get(key), reason });
    if (matches.length >= 3) break;
  }

  return { matches };
});

// ── 7. Onboarding voice mode: extract signup fields from a spoken sentence ───
// The user introduces themselves by voice (Burmese/English); this pulls out the
// onboarding fields so a non-typer can still register. It extracts ONLY what was
// actually said (never invents), constrains `gender` to a fixed set and `skills`
// to the app's known skill ids (same "constrain to the provided list" safety as
// suggestCategory), and validates `age`/`phone`. The app still lands the user on
// the real, editable form pre-filled — nothing is submitted here. The Flutter
// app falls back to its offline keyword extractor if this fails, so it never
// hangs. Password is intentionally NOT extracted (typed privately).
exports.extractOnboarding = onCall(taskOptions, async (request) => {
  const { role, transcript, knownSkills } = request.data || {};
  const text = (transcript || "").toString().trim();
  if (!text) {
    throw new HttpsError("invalid-argument", "transcript required.");
  }
  const isTasker = role === "tasker";
  const skillList = Array.isArray(knownSkills) ? knownSkills : [];
  const allowedSkillIds = new Set(
    skillList.map((s) => String(s && s.id)).filter((s) => s && s !== "null")
  );

  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "You extract onboarding fields from a spoken self-introduction (Burmese or " +
      "English) for a Yangon home-service app. Extract ONLY what the user actually " +
      "said; never guess or invent. Fields: name (string; '' if not said), gender " +
      "(EXACTLY one of 'male','female','other', or '' if unclear), age (integer " +
      "years, or null if not said), phone (digits only; '' if not said)" +
      (isTasker
        ? ", skills (array of ids chosen ONLY from the provided knownSkills list; " +
          "[] if none mentioned)."
        : ".") +
      ' Respond as JSON: {"name": "", "gender": "", "age": null, "phone": ""' +
      (isTasker ? ', "skills": []' : "") +
      "}.",
    { transcript: text, role: isTasker ? "tasker" : "client", knownSkills: skillList }
  );

  const name = (result.name || "").toString().trim();
  const genderRaw = (result.gender || "").toString().toLowerCase();
  const gender = ["male", "female", "other"].includes(genderRaw) ? genderRaw : "";
  let age = Math.round(Number(result.age));
  if (!Number.isFinite(age) || age < 1 || age > 120) age = null;
  const phone = (result.phone || "").toString().replace(/\D/g, "");

  let skills = [];
  if (isTasker && Array.isArray(result.skills)) {
    const picked = result.skills
      .map((s) => String(s))
      .filter((s) => allowedSkillIds.has(s));
    skills = [...new Set(picked)];
  }

  return { name, gender, age, phone, skills };
});

// ── 8. Task-Handling: gentle stale-post fixes for a task with no taker ───────
// Wording only — the app decides WHEN to ask (time-since-post in Dart). Returns
// 2–4 short Burmese suggestions to make a waiting post more attractive (raise
// budget, widen tier, clarify, mark urgent). Falls back to a templated list.
exports.suggestTaskFixes = onCall(taskOptions, async (request) => {
  const { task, ageHours } = request.data || {};
  if (!task) {
    throw new HttpsError("invalid-argument", "task required.");
  }
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "A client's task on a Yangon home-service app has waited " +
      Math.round(Number(ageHours) || 0) +
      " hours with no worker. Suggest 2–4 SHORT, concrete, friendly BURMESE fixes " +
      "to attract a worker faster (e.g. raise the budget, widen the accepted " +
      "worker tier, add detail/photos, mark urgent). Base them on the task fields; " +
      "never invent facts. " +
      'Respond as JSON: {"tips": ["<burmese>", ...]}.',
    { task, ageHours: Math.round(Number(ageHours) || 0) }
  );
  const tips = Array.isArray(result.tips)
    ? result.tips.map((t) => String(t).trim()).filter(Boolean).slice(0, 4)
    : [];
  return { tips };
});

// ── 9. Task-Handling: completion summary + SUGGESTED tier move ───────────────
// The model SUMMARIZES completion evidence and RECOMMENDS a tier delta; it never
// applies it. The real tier change is the backend's transparent rules + client
// rating (spec §4.4 Phase 3 / §8). suggestedTierDelta is constrained to -1..+1.
exports.summarizeCompletion = onCall(taskOptions, async (request) => {
  const { task, timing, review } = request.data || {};
  if (!task) {
    throw new HttpsError("invalid-argument", "task required.");
  }
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "Summarize a completed home-service task for a Yangon marketplace, then " +
      "RECOMMEND (do not apply) a worker trust-tier move. Consider time taken vs " +
      "estimate and the client's rating/review. Give a short BURMESE summary and a " +
      "plain-language BURMESE rationale. suggestedTierDelta MUST be one of -1, 0, " +
      "or 1 (a mere suggestion; transparent rules + the client rating decide the " +
      'real tier). Respond as JSON: {"summary": "", "suggestedTierDelta": 0, "rationale": ""}.',
    { task, timing: timing || {}, review: review || {} }
  );
  const summary = (result.summary || "").toString().trim();
  const rationale = (result.rationale || "").toString().trim();
  let delta = Math.round(Number(result.suggestedTierDelta));
  if (!Number.isFinite(delta)) delta = 0;
  delta = Math.max(-1, Math.min(1, delta));
  return { summary, suggestedTierDelta: delta, rationale };
});

// ── 10. Task-Handling (tasker): per-task brief — what the client wants + prep ─
// A short BURMESE summary of the task plus suggested prep/tools, read aloud in
// the app. Wording only; falls back to a templated brief from the task fields.
exports.briefTasker = onCall(taskOptions, async (request) => {
  const { task } = request.data || {};
  if (!task) {
    throw new HttpsError("invalid-argument", "task required.");
  }
  const result = await openai.askJson(
    OPENAI_API_KEY.value(),
    "Brief a worker before they start a home-service task in Yangon. Give a short " +
      "BURMESE summary of what the client wants, then 2–4 SHORT suggested prep/tools " +
      "items in BURMESE. Base everything on the task fields; never invent specifics. " +
      'Respond as JSON: {"summary": "", "suggestions": ["<burmese>", ...]}.',
    { task }
  );
  const summary = (result.summary || "").toString().trim();
  const suggestions = Array.isArray(result.suggestions)
    ? result.suggestions.map((s) => String(s).trim()).filter(Boolean).slice(0, 4)
    : [];
  return { summary, suggestions };
});
