// ============================================================================
// RAG service — the full Retrieval-Augmented Generation pipeline.
// ----------------------------------------------------------------------------
// Used ONLY for knowledge/FAQ/help/platform questions (decided upstream by
// intent_service.isKnowledgeQuestion). Post-task / find-task / navigation /
// action-button flows DO NOT come through here — they keep their existing
// rule-based logic.
//
// Pipeline:
//   1. embed the question            (embedding_service -> OpenAI)
//   2. query Pinecone                (pinecone_service)
//   3. keep only relevant chunks     (cosine score >= RAG_MIN_SCORE)
//   4. build a grounded context prompt (prompt_service)
//   5. ask OpenAI to answer ONLY from that context (openai_service)
//
// If nothing relevant is retrieved we return the polite "not found" message
// WITHOUT calling the LLM — so the model can never invent platform facts.
// ============================================================================

const { embed } = require("./embedding_service");
const pinecone = require("./pinecone_service");
const openai = require("./openai_service");
const prompts = require("./prompt_service");
const { RAG_TOP_K, RAG_MIN_SCORE, KB_NOT_FOUND_MESSAGE } = require("./constants");

/**
 * True if the model's reply is effectively "I couldn't find it" — either the
 * exact sentinel from the system prompt or a close paraphrase. Used to detect
 * when retrieved chunks didn't actually answer the question, so the caller can
 * fall back to the general assistant instead of showing a dead-end.
 */
function isNotFoundReply(text) {
  const t = (text || "").toLowerCase();
  return (
    text.includes("ရှာမတွေ့") || // Burmese "couldn't find"
    t.includes("couldn't find information") ||
    t.includes("could not find information") ||
    t.includes("couldn't find any information") ||
    t.includes("not in the application knowledge base") ||
    t.includes("not in the knowledge base")
  );
}

/** Format retrieved matches into a numbered, titled context block. */
function buildContext(matches) {
  return matches
    .map((m, i) => {
      const md = m.metadata || {};
      const title = md.title || md.source || `Document ${i + 1}`;
      const text = (md.text || "").toString().trim();
      return `[#${i + 1} — ${title}]\n${text}`;
    })
    .join("\n\n");
}

/**
 * Answer an app-knowledge question via RAG.
 *
 * @param {object} args
 * @param {string} args.openAiKey
 * @param {string} args.pineconeKey
 * @param {string} args.pineconeIndex
 * @param {string} args.question
 * @param {number} [args.topK]
 * @param {object} [args.filter] optional Pinecone metadata filter
 * @returns {Promise<{found:boolean, message:string, sources:string[]}>}
 *   `message` is ALWAYS a non-empty string (an answer, or the polite fallback),
 *   so the Cloud Function can return it directly and the Flutter app keeps the
 *   live reply instead of dropping to its offline mock.
 */
async function answer({
  openAiKey,
  pineconeKey,
  pineconeIndex,
  question,
  topK = RAG_TOP_K,
  filter,
}) {
  // 1) Embed the question.
  const vector = await embed(openAiKey, question);

  // 2) Retrieve candidate chunks.
  const matches = await pinecone.query(pineconeKey, pineconeIndex, vector, {
    topK,
    filter,
  });

  // 3) Drop weak matches. If nothing is relevant, signal "not found" WITHOUT
  //    the LLM — the caller decides what to do (here: fall back to the general
  //    assistant). The model is still never allowed to fabricate from thin air.
  const relevant = matches.filter((m) => (m.score ?? 0) >= RAG_MIN_SCORE);
  if (relevant.length === 0) {
    return { found: false, message: KB_NOT_FOUND_MESSAGE, sources: [] };
  }

  // 4) Build the grounded prompt from retrieved context.
  const context = buildContext(relevant);
  const userPrompt = prompts.ragPrompt({ context, question });

  // 5) Ask OpenAI to answer strictly from the context.
  const reply = await openai.askText(openAiKey, prompts.systemPrompt(), userPrompt, {
    temperature: 0.2,
  });
  const message = (reply || "").trim();

  // If the retrieved context didn't actually answer the question (empty reply
  // or the not-found sentinel), report found:false so the caller can fall back
  // to the general assistant rather than dead-ending the user.
  if (!message || isNotFoundReply(message)) {
    return { found: false, message: KB_NOT_FOUND_MESSAGE, sources: [] };
  }

  const sources = [
    ...new Set(relevant.map((m) => (m.metadata && m.metadata.source) || "")),
  ].filter(Boolean);

  return { found: true, message, sources };
}

module.exports = { answer };
