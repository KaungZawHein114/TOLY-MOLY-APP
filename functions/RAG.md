# TOLY MOLY — Chatbot RAG (Pinecone + OpenAI)

Phase 2 upgrade of the in-app assistant (`chatAssistant`). **Knowledge / FAQ /
help / platform questions** are now answered with Retrieval-Augmented Generation
(RAG): the question is embedded, the most relevant chunks of the Markdown
knowledge base are retrieved from Pinecone, and OpenAI answers **only** from that
retrieved context. Everything else is unchanged.

> All other chatbot behaviour — off-topic refusal, **post-task** / **find-task**
> intent, action buttons, greetings, and the offline mock fallback — works
> exactly as before. The response shape `{ intent, action, message }` is
> identical, so the Flutter app needs **no changes**.

---

## 1. Architecture

```
Flutter (chatbot_screen.dart)
        │  httpsCallable('chatAssistant')
        ▼
Cloud Function: chatAssistant            ← functions/index.js
        │
   intent_service  (RULE-BASED, authoritative — never the model)
        │
        ├─ off-topic                → refuse (no model/Pinecone call)
        ├─ post_task / find_task    → existing wording + action button  (NO RAG)
        ├─ greeting                 → friendly worded reply             (NO RAG)
        └─ knowledge question ──────────────────────────────┐
                                                            ▼
                                              rag_service (the pipeline)
                                                 1. embedding_service → OpenAI embeddings
                                                 2. pinecone_service  → similarity search
                                                 3. score filter (RAG_MIN_SCORE)
                                                 4. prompt_service    → grounded prompt
                                                 5. openai_service    → answer from context
                                                            │
                              no relevant chunks ──→ polite "not found" (no LLM call)
                                                            ▼
                                          { intent:'general', action:null, message }
```

**Module layout** (single responsibility each):

```
functions/
├── index.js                     # entry: the 5 callable functions + wiring
├── services/
│   ├── constants.js             # models, dims, RAG tuning (no firebase imports)
│   ├── openai_service.js        # OpenAI client + askJson / askText
│   ├── embedding_service.js     # OpenAI embeddings
│   ├── pinecone_service.js      # Pinecone client + similarity search
│   ├── prompt_service.js        # loads prompts/*.txt, fills {{vars}}
│   ├── rag_service.js           # embed → retrieve → ground → answer
│   └── intent_service.js        # topic + intent rules (mirrors ai_mock.dart)
├── prompts/
│   ├── system_prompt.txt        # assistant persona + strict grounding rules
│   └── rag_prompt.txt           # {{context}} + {{question}} template
├── scripts/
│   └── index_knowledge.js       # LOCAL indexer (reads ../knowledge/*.md)
└── .env.local.example            # local indexer keys (copy to .env.local)

knowledge/                       # the Markdown knowledge base (one doc per topic)
```

**Models:** chat `gpt-4o-mini` (unchanged), embeddings `text-embedding-3-small`
(1536 dims). Tunables live in `services/constants.js` (`RAG_TOP_K`,
`RAG_MIN_SCORE`).

---

## 2. Secrets (Firebase Secret Manager)

The deployed function reads three secrets. **Never hardcode keys.**

Current status in project `tolymolyapp-94594`:

| Secret | Needed for | Status |
|---|---|---|
| `OPENAI_API_KEY` | embeddings + chat | ✅ already set |
| `PINECONE_API_KEY` | Pinecone access | ❌ **create it** |
| `PINECONE_INDEX` | index name, e.g. `tolymoly-knowledge` | ❌ **create it** |

Create the two missing secrets (you'll be prompted to paste each value):

```bash
firebase functions:secrets:set PINECONE_API_KEY
firebase functions:secrets:set PINECONE_INDEX
```

> `PINECONE_INDEX` is just the index **name** (a short string like
> `tolymoly-knowledge`), not a URL. Use the same name everywhere.

Verify any secret exists:

```bash
firebase functions:secrets:get PINECONE_API_KEY
```

---

## 3. One-time setup

```bash
# A) Pinecone account → https://app.pinecone.io → create an API key.
#    You do NOT need to create the index by hand — the indexer creates a
#    serverless index automatically if it's missing (aws / us-east-1, free tier).

# B) Install the new function dependencies
cd functions
npm install            # adds @pinecone-database/pinecone + dotenv

# C) Local indexer keys (NOT used by the deployed function — `.env.local`
#    is never loaded by `firebase deploy`, unlike `.env`)
cp .env.local.example .env.local   # then edit .env.local and paste your real keys
#   OPENAI_API_KEY=sk-...
#   PINECONE_API_KEY=pcsk_...
#   PINECONE_INDEX=tolymoly-knowledge
```

---

## 4. Build the knowledge index

From `functions/`:

```bash
# Preview what will be indexed (parse + chunk only, no network):
npm run index:knowledge:dry

# Full rebuild (wipe + re-add every chunk) — the normal command:
npm run index:knowledge

# Add/update only, keep existing vectors:
node scripts/index_knowledge.js --no-clean
```

The script reads every `knowledge/*.md`, chunks it, embeds the chunks, and
upserts them to Pinecone with metadata. Re-run it whenever the knowledge base
changes.

---

## 5. Deploy

Create the Pinecone secrets first (section 2), then:

```bash
firebase deploy --only functions:chatAssistant
# or deploy everything:
firebase deploy --only functions
```

Test in the app: open the chatbot and ask a knowledge question, e.g.
*“Verification ဘယ်လိုလုပ်ရမလဲ”* or *“How do payments work?”* → a grounded answer
from the KB. Ask an on-topic question the KB doesn’t cover → a helpful general
answer from the assistant (NOT a “couldn’t find” dead-end). Ask *“fix my sink”*
→ still the **Post a Task** button (unchanged). Ask something off-topic
(*“capital of France?”*) → still politely refused.

---

## 6. Updating the knowledge base later

The whole point of the design: **add knowledge without touching chatbot code.**

1. Add or edit a Markdown file in `knowledge/` (e.g. `knowledge/refunds.md`).
2. (Optional) Add frontmatter to control metadata:
   ```markdown
   ---
   title: Refund Policy
   category: payments
   language: my
   ---
   # ပြန်အမ်းငွေ မူဝါဒ
   ...
   ```
   Without frontmatter, the indexer derives: **title** from the first `#`
   heading (else the filename), **category** from the filename, **language** by
   auto-detecting Burmese vs English.
3. Re-run `npm run index:knowledge`.

That's it — no Cloud Function redeploy is needed for content-only changes (the
function queries Pinecone live). Redeploy only when you change *code*.

### Metadata stored per vector

`title`, `category`, `language`, `source` (filename), `chunk` (number),
`chunks` (total), and `text` (the chunk itself, so retrieval needs no re-read).
`pinecone_service.query(...)` accepts an optional `filter`, so you can later
restrict retrieval by metadata (e.g. `{ language: 'my' }`).

---

## 7. Grounding vs. helpfulness (how the two are balanced)

The KB answer is kept strictly grounded; when the KB has nothing, the assistant
still helps (app-scoped) instead of dead-ending.

- **Rule gate first:** off-topic questions are refused before any model call —
  the general fallback can *never* be reached by an off-topic question.
- **Score floor:** if no retrieved chunk clears `RAG_MIN_SCORE`, the RAG step
  reports `found: false` **without** calling the LLM.
- **Strict KB prompt:** when the KB *does* match, the system prompt forbids
  using anything outside the retrieved context, and emits the not-found sentinel
  when the context is insufficient — so KB answers never invent platform facts.
- **General fallback:** when RAG reports `found: false`, the chatbot answers the
  on-topic question from its own understanding of how the app works, in a short
  Burmese-first reply. It is told NOT to invent specific prices, fees, or
  policies — for unknown specifics it gives general guidance / suggests support.
- **Graceful degrade:** any RAG infrastructure error also falls through to this
  general path, so the chatbot never breaks.

> Want strict "KB-only" behaviour back (return “couldn’t find” instead of a
> general answer)? In `functions/index.js`, `chatAssistant` step 4, return the
> not-found message on `!result.found` rather than falling through.
