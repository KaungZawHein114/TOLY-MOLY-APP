// ============================================================================
// Prompt service — loads prompt templates from functions/prompts/*.txt.
// ----------------------------------------------------------------------------
// Large prompts live as plain-text files (easy to read/tweak, no escaping,
// reviewable in diffs) instead of being hardcoded inside JS. Templates are read
// once and cached. `{{var}}` placeholders are filled by render().
// ============================================================================

const fs = require("fs");
const path = require("path");

const PROMPTS_DIR = path.join(__dirname, "..", "prompts");
const _cache = new Map();

function load(name) {
  if (_cache.has(name)) return _cache.get(name);
  const text = fs.readFileSync(path.join(PROMPTS_DIR, name), "utf8");
  _cache.set(name, text);
  return text;
}

/** Replace {{ var }} placeholders with values from `vars`. */
function render(template, vars = {}) {
  return template.replace(/\{\{\s*(\w+)\s*\}\}/g, (_, key) =>
    vars[key] != null ? String(vars[key]) : ""
  );
}

module.exports = {
  /** RAG grounding system prompt (assistant persona + strict rules). */
  systemPrompt: () => load("system_prompt.txt"),
  /** RAG user prompt with {{context}} and {{question}} filled in. */
  ragPrompt: (vars) => render(load("rag_prompt.txt"), vars),
};
