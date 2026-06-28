// ============================================================================
// Pinecone service — single owner of the Pinecone client + index handle.
// ----------------------------------------------------------------------------
// Like the OpenAI service, the API key and index name are passed IN so this
// works both in a Cloud Function (Secret Manager) and in the local indexer
// (.env). Client + index handle are cached for warm-instance reuse; the handle
// resolves the index host lazily on first data-plane call.
// ============================================================================

const { Pinecone } = require("@pinecone-database/pinecone");

let _client = null;
let _clientKey = null;
let _index = null;
let _indexName = null;

/** Lazily build (and cache) a Pinecone client for the given key. */
function getClient(apiKey) {
  if (!apiKey) throw new Error("Pinecone API key missing.");
  if (!_client || _clientKey !== apiKey) {
    _client = new Pinecone({ apiKey });
    _clientKey = apiKey;
    _index = null; // force index handle rebuild if the key changed
  }
  return _client;
}

/** Cached handle to a named index. */
function getIndex(apiKey, indexName) {
  if (!indexName) throw new Error("Pinecone index name missing.");
  const client = getClient(apiKey);
  if (!_index || _indexName !== indexName) {
    _index = client.index(indexName);
    _indexName = indexName;
  }
  return _index;
}

/**
 * Similarity search.
 * @returns {Promise<Array<{id:string, score:number, metadata:object}>>}
 */
async function query(apiKey, indexName, vector, { topK = 5, filter } = {}) {
  const index = getIndex(apiKey, indexName);
  const res = await index.query({
    topK,
    vector,
    includeMetadata: true,
    ...(filter ? { filter } : {}),
  });
  return res.matches || [];
}

module.exports = { getClient, getIndex, query };
