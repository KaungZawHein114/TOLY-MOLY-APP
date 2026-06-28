// ============================================================================
// index_knowledge.js — build/refresh the Pinecone knowledge index.
// ----------------------------------------------------------------------------
// Run this LOCALLY whenever the Markdown knowledge base changes. It is SEPARATE
// from the chatbot (the Cloud Function only QUERIES Pinecone; it never writes).
//
//   1. read every *.md under the knowledge folder
//   2. parse optional YAML frontmatter, derive metadata
//   3. chunk each document
//   4. embed chunks with OpenAI (text-embedding-3-small)
//   5. upsert vectors + metadata into Pinecone
//
// Keys come from functions/.env (git-ignored) or the shell environment — NOT
// from Firebase Secret Manager (that's only for the deployed function). Needs:
//   OPENAI_API_KEY, PINECONE_API_KEY, PINECONE_INDEX
// Optional: PINECONE_CLOUD (default aws), PINECONE_REGION (default us-east-1),
//           KNOWLEDGE_DIR (default ../../knowledge)
//
// Usage (from functions/):
//   node scripts/index_knowledge.js            # full rebuild (wipe + re-add)
//   node scripts/index_knowledge.js --no-clean # add/update only, keep existing
//   node scripts/index_knowledge.js --dry-run  # parse + chunk, no network
// ============================================================================

const fs = require("fs");
const path = require("path");
const { Pinecone } = require("@pinecone-database/pinecone");
const OpenAI = require("openai");

// Load functions/.env.local without adding a hard dependency on dotenv.
try {
  require("dotenv").config({ path: path.join(__dirname, "..", ".env.local") });
} catch (_) {
  /* dotenv optional — env may already be set in the shell */
}

const {
  EMBEDDING_MODEL,
  EMBEDDING_DIMENSIONS,
} = require("../services/constants");

const args = process.argv.slice(2);
const CLEAN = !args.includes("--no-clean");
const DRY_RUN = args.includes("--dry-run");

const KNOWLEDGE_DIR =
  process.env.KNOWLEDGE_DIR || path.join(__dirname, "..", "..", "knowledge");
const PINECONE_CLOUD = process.env.PINECONE_CLOUD || "aws";
const PINECONE_REGION = process.env.PINECONE_REGION || "us-east-1";

// Chunking knobs. The KB docs are small (often one chunk each) but this scales.
const MAX_CHARS = 1200; // ~ a few short paragraphs per chunk
const OVERLAP_CHARS = 150; // carry context across chunk boundaries
const EMBED_BATCH = 96; // inputs per OpenAI embeddings request

// ── helpers ─────────────────────────────────────────────────────────────────

/** Parse very small YAML frontmatter (key: value lines) if present. */
function parseFrontmatter(raw) {
  if (!raw.startsWith("---")) return { meta: {}, body: raw };
  const end = raw.indexOf("\n---", 3);
  if (end === -1) return { meta: {}, body: raw };
  const block = raw.slice(3, end).trim();
  const body = raw.slice(end + 4).replace(/^\s*\n/, "");
  const meta = {};
  for (const line of block.split("\n")) {
    const m = line.match(/^\s*([\w-]+)\s*:\s*(.+?)\s*$/);
    if (m) meta[m[1].toLowerCase()] = m[2].replace(/^["']|["']$/g, "");
  }
  return { meta, body };
}

/** Detect language: Burmese (my) if it contains Myanmar-script characters. */
function detectLanguage(text) {
  return /[က-႟]/.test(text) ? "my" : "en";
}

/** First "# Heading" -> title, else the file name. */
function deriveTitle(body, source) {
  const m = body.match(/^#\s+(.+)$/m);
  return m ? m[1].trim() : source.replace(/\.md$/i, "").replace(/[_-]/g, " ");
}

/**
 * Chunk on blank lines (paragraph boundaries), greedily packing paragraphs up
 * to MAX_CHARS, with a small character overlap so context isn't cut mid-idea.
 */
function chunk(text) {
  const paras = text
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter(Boolean);

  const chunks = [];
  let current = "";
  for (const para of paras) {
    if (current && current.length + para.length + 2 > MAX_CHARS) {
      chunks.push(current.trim());
      const tail = current.slice(-OVERLAP_CHARS);
      current = `${tail}\n\n${para}`;
    } else {
      current = current ? `${current}\n\n${para}` : para;
    }
  }
  if (current.trim()) chunks.push(current.trim());
  return chunks;
}

/** Read + parse one markdown file into indexable chunk records. */
function loadFile(file) {
  const raw = fs.readFileSync(path.join(KNOWLEDGE_DIR, file), "utf8");
  const { meta, body } = parseFrontmatter(raw);
  const content = body.trim();
  if (!content) return []; // skip empty files (e.g. an unfinished doc)

  const source = file;
  const title = meta.title || deriveTitle(content, source);
  const category = meta.category || source.replace(/\.md$/i, "");
  const pieces = chunk(content);

  return pieces.map((piece, i) => ({
    id: `${source}::${i}`,
    text: piece,
    metadata: {
      title,
      category,
      language: meta.language || detectLanguage(piece),
      source,
      chunk: i,
      chunks: pieces.length,
      text: piece, // stored so the retriever can build context without a re-read
    },
  }));
}

function requireEnv(name) {
  const v = process.env[name];
  if (!v) {
    console.error(
      `\n✖ Missing ${name}.\n  Create functions/.env (git-ignored) with:\n` +
        `    OPENAI_API_KEY=sk-...\n    PINECONE_API_KEY=pcn-...\n    PINECONE_INDEX=tolymoly-knowledge\n`
    );
    process.exit(1);
  }
  return v;
}

async function ensureIndex(pc, indexName) {
  const { indexes = [] } = await pc.listIndexes();
  if (indexes.some((ix) => ix.name === indexName)) return;
  console.log(`• Creating serverless index "${indexName}" (${PINECONE_CLOUD}/${PINECONE_REGION})…`);
  await pc.createIndex({
    name: indexName,
    dimension: EMBEDDING_DIMENSIONS,
    metric: "cosine",
    spec: { serverless: { cloud: PINECONE_CLOUD, region: PINECONE_REGION } },
    waitUntilReady: true,
  });
  console.log("• Index ready.");
}

async function embedAll(openai, records) {
  for (let i = 0; i < records.length; i += EMBED_BATCH) {
    const batch = records.slice(i, i + EMBED_BATCH);
    const res = await openai.embeddings.create({
      model: EMBEDDING_MODEL,
      input: batch.map((r) => r.text),
    });
    res.data.forEach((d, j) => {
      batch[j].values = d.embedding;
    });
    console.log(`  embedded ${Math.min(i + EMBED_BATCH, records.length)}/${records.length}`);
  }
}

// ── main ──────────────────────────────────────────────────────────────────────
async function main() {
  if (!fs.existsSync(KNOWLEDGE_DIR)) {
    console.error(`✖ Knowledge folder not found: ${KNOWLEDGE_DIR}`);
    process.exit(1);
  }

  const files = fs.readdirSync(KNOWLEDGE_DIR).filter((f) => f.toLowerCase().endsWith(".md"));
  const records = files.flatMap(loadFile);
  console.log(`Read ${files.length} markdown file(s) -> ${records.length} chunk(s).`);

  if (records.length === 0) {
    console.error("✖ No content to index.");
    process.exit(1);
  }

  if (DRY_RUN) {
    for (const r of records) {
      console.log(`  ${r.id}  [${r.metadata.category}/${r.metadata.language}]  ${r.metadata.title}`);
    }
    console.log("\n(dry run — no embeddings, no upload)");
    return;
  }

  const openaiKey = requireEnv("OPENAI_API_KEY");
  const pineconeKey = requireEnv("PINECONE_API_KEY");
  const indexName = requireEnv("PINECONE_INDEX");

  const openai = new OpenAI({ apiKey: openaiKey });
  const pc = new Pinecone({ apiKey: pineconeKey });

  await ensureIndex(pc, indexName);
  const index = pc.index(indexName);

  if (CLEAN) {
    console.log("• Clearing existing vectors (full rebuild)…");
    try {
      await index.deleteAll();
    } catch (err) {
      // A brand-new index has no vectors yet -> deleteAll can 404; that's fine.
      console.log("  (nothing to clear)");
    }
  }

  console.log("• Embedding chunks…");
  await embedAll(openai, records);

  console.log("• Upserting to Pinecone…");
  const vectors = records.map((r) => ({ id: r.id, values: r.values, metadata: r.metadata }));
  for (let i = 0; i < vectors.length; i += 100) {
    await index.upsert(vectors.slice(i, i + 100));
  }

  console.log(`\n✓ Indexed ${vectors.length} chunk(s) from ${files.length} file(s) into "${indexName}".`);
}

main().catch((err) => {
  console.error("\n✖ Indexing failed:", err.message || err);
  process.exit(1);
});
