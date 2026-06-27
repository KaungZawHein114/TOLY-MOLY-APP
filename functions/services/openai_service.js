// ============================================================================
// OpenAI service — single owner of the OpenAI client + completion helpers.
// ----------------------------------------------------------------------------
// The API key is passed IN by the caller (never read from here) so this module
// works both inside a Cloud Function (key from Secret Manager via
// OPENAI_API_KEY.value()) and inside the local indexing script (key from a
// .env / process.env). The client is cached per-key for warm-instance reuse.
// ============================================================================

const OpenAI = require("openai");
const { CHAT_MODEL } = require("./constants");

let _client = null;
let _clientKey = null;

/** Lazily build (and cache) an OpenAI client for the given key. */
function getClient(apiKey) {
  if (!apiKey) throw new Error("OpenAI API key missing.");
  if (!_client || _clientKey !== apiKey) {
    _client = new OpenAI({ apiKey });
    _clientKey = apiKey;
  }
  return _client;
}

/**
 * JSON-mode chat completion. Used by the Task Scoper functions and the chat
 * wording path. `response_format: json_object` forces valid JSON back.
 */
async function askJson(apiKey, systemPrompt, userPayload, { temperature = 0.4 } = {}) {
  const completion = await getClient(apiKey).chat.completions.create({
    model: CHAT_MODEL,
    temperature,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: JSON.stringify(userPayload) },
    ],
  });
  const text = completion.choices?.[0]?.message?.content ?? "{}";
  return JSON.parse(text);
}

/**
 * Plain-text chat completion. Used by RAG to produce a grounded answer from the
 * retrieved context. Lower default temperature for factual, on-context output.
 */
async function askText(apiKey, systemPrompt, userPrompt, { temperature = 0.2 } = {}) {
  const completion = await getClient(apiKey).chat.completions.create({
    model: CHAT_MODEL,
    temperature,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ],
  });
  return (completion.choices?.[0]?.message?.content ?? "").trim();
}

module.exports = { getClient, askJson, askText };
