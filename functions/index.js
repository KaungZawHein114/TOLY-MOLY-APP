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
