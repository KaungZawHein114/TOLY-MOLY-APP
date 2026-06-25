// ============================================================================
// TOLY MOLY — AI Task Scoper Cloud Functions
// ----------------------------------------------------------------------------
// Four callable functions that proxy OpenAI so the API key NEVER ships in the
// Flutter app. The app (lib/core/utils/ai_service.dart) calls these by name and
// automatically falls back to its offline mock if any of them fail — so a
// missing key, a cold start, or a rate limit can never break the demo.
//
// Functions (each takes JSON in, returns JSON out):
//   suggestCategory({ title, categories })        -> { category }
//   rewriteDescription({ title, category, ... })   -> { description }
//   analyzePrice({ title, category, ... })         -> { low, high, currency }
//   evaluateTask({ title, category, ... })         -> { score, strengths, ... }
//
// Setup is in functions/README.md.
// ============================================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const OpenAI = require("openai");

// The OpenAI key lives in Firebase's encrypted secret store, never in code.
// Set it once with:  firebase functions:secrets:set OPENAI_API_KEY
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

const MODEL = "gpt-4o-mini";

// Shared options: attach the secret, keep instances small/cheap for a demo.
const callOptions = {
  secrets: [OPENAI_API_KEY],
  timeoutSeconds: 30,
  memory: "256MiB",
};

/**
 * Sends a system prompt + JSON payload to OpenAI and parses a JSON object back.
 * Uses response_format json_object so the model must return valid JSON.
 */
async function askJson(systemPrompt, userPayload) {
  const client = new OpenAI({ apiKey: OPENAI_API_KEY.value() });
  const completion = await client.chat.completions.create({
    model: MODEL,
    temperature: 0.4,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: JSON.stringify(userPayload) },
    ],
  });
  const text = completion.choices?.[0]?.message?.content ?? "{}";
  return JSON.parse(text);
}

// ── 1. Suggest a category from the task title ───────────────────────────────
exports.suggestCategory = onCall(callOptions, async (request) => {
  const { title, categories } = request.data || {};
  if (!title || !Array.isArray(categories) || categories.length === 0) {
    throw new HttpsError("invalid-argument", "title and categories required.");
  }
  const result = await askJson(
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
exports.rewriteDescription = onCall(callOptions, async (request) => {
  const { title, category, location, urgent, currentText } = request.data || {};
  const result = await askJson(
    "You write clear, polite, professional task descriptions in BURMESE for a " +
      "Yangon home-service marketplace. Improve clarity, structure and " +
      "completeness without inventing facts the user did not provide. Keep it " +
      "to 2–4 short sentences. Respond as JSON: {\"description\": \"<burmese text>\"}.",
    { title, category, location, urgent: !!urgent, currentText: currentText || "" }
  );
  const description = (result.description || "").toString().trim();
  if (!description) {
    throw new HttpsError("internal", "Empty description from model.");
  }
  return { description };
});

// ── 3. Recommend a price band (MMK) ─────────────────────────────────────────
exports.analyzePrice = onCall(callOptions, async (request) => {
  const { title, category, description, location, urgent } = request.data || {};
  const result = await askJson(
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
exports.evaluateTask = onCall(callOptions, async (request) => {
  const task = request.data || {};
  const result = await askJson(
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
