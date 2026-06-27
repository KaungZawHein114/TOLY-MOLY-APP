// ============================================================================
// Embedding service — turns text into vectors with OpenAI embeddings.
// ----------------------------------------------------------------------------
// Reuses the cached OpenAI client from openai_service. The same EMBEDDING_MODEL
// (and therefore the same vector dimensionality) is used by BOTH the query path
// (rag_service) and the indexing script, so query and index vectors always
// live in the same space.
// ============================================================================

const { getClient } = require("./openai_service");
const { EMBEDDING_MODEL } = require("./constants");

/**
 * Embed one string or an array of strings.
 * @param {string} apiKey OpenAI API key.
 * @param {string|string[]} input
 * @returns {Promise<number[]|number[][]>} a single vector, or one per input.
 */
async function embed(apiKey, input) {
  const inputs = Array.isArray(input) ? input : [input];
  if (inputs.length === 0) return Array.isArray(input) ? [] : [];
  const res = await getClient(apiKey).embeddings.create({
    model: EMBEDDING_MODEL,
    input: inputs,
  });
  const vectors = res.data.map((d) => d.embedding);
  return Array.isArray(input) ? vectors : vectors[0];
}

module.exports = { embed };
