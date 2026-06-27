// ============================================================================
// Shared constants — NO firebase/secret imports here on purpose.
// ----------------------------------------------------------------------------
// This module is imported by BOTH the deployed Cloud Functions AND the local
// `scripts/index_knowledge.js` indexer. Keeping it free of `firebase-functions`
// means the indexing script can run on a plain Node install without dragging in
// (or trying to resolve) the Functions runtime / secret machinery.
// ============================================================================

module.exports = {
  // OpenAI models. Chat model is unchanged from the original implementation.
  CHAT_MODEL: "gpt-4o-mini",
  EMBEDDING_MODEL: "text-embedding-3-small",
  EMBEDDING_DIMENSIONS: 1536, // text-embedding-3-small -> 1536 dims

  // RAG retrieval tuning.
  RAG_TOP_K: 5, // how many chunks to pull from Pinecone
  // Cosine-similarity floor. Below this, a match is treated as "not in the KB".
  // This is a recall/precision knob: lower => more recall (good for cross-lingual
  // English->Burmese queries), higher => stricter. The strict grounding prompt is
  // the real guard against hallucination, so we keep this modest.
  RAG_MIN_SCORE: 0.25,

  // Shown when the knowledge base has nothing relevant. Bilingual to match the
  // app's Burmese-first, English-in-parentheses style (see OFF_TOPIC_REPLY).
  KB_NOT_FOUND_MESSAGE:
    "ဤမေးခွန်းနှင့်ပတ်သက်သော အချက်အလက်ကို အက်ပ်၏ Knowledge Base ထဲတွင် ရှာမတွေ့ပါ။ " +
    "(I couldn't find information about that in the application knowledge base.)",
};
