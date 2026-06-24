// AI Task Scoper - frontend logic
// Plain vanilla JS: no frameworks, easy to follow.

const els = {
  input: document.getElementById("task-input"),
  analyzeBtn: document.getElementById("analyze-btn"),
  sampleBtn: document.getElementById("sample-btn"),
  errorBox: document.getElementById("error-box"),
  loading: document.getElementById("loading"),
  results: document.getElementById("results"),
  copyBtn: document.getElementById("copy-btn"),
  improved: document.getElementById("improved-description"),
  scoreValue: document.getElementById("score-value"),
  scoreBar: document.getElementById("score-bar"),
  budgetBadge: document.getElementById("budget-badge"),
  budgetExplanation: document.getElementById("budget-explanation"),
  budgetRange: document.getElementById("budget-range"),
  completionTime: document.getElementById("completion-time"),
  missingList: document.getElementById("missing-list"),
  reasoning: document.getElementById("reasoning"),
};

const SAMPLE =
  "Need someone to fix a leaking kitchen tap this weekend. It drips all the " +
  "time. I live in a downtown apartment. Budget around $30.";

// ---------- Events ----------
els.analyzeBtn.addEventListener("click", analyze);
els.sampleBtn.addEventListener("click", () => {
  els.input.value = SAMPLE;
  els.input.focus();
});
els.copyBtn.addEventListener("click", copyDescription);

// Ctrl/Cmd + Enter submits.
els.input.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "Enter") analyze();
});

// ---------- Main flow ----------
async function analyze() {
  const task = els.input.value.trim();
  hideError();

  if (!task) {
    showError("Please enter a task description first.");
    return;
  }

  setLoading(true);

  try {
    const res = await fetch("/api/scope", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task }),
    });

    const data = await res.json();

    if (!res.ok) {
      throw new Error(data.error || "Something went wrong. Please try again.");
    }

    render(data);
  } catch (err) {
    showError(err.message);
  } finally {
    setLoading(false);
  }
}

// ---------- Rendering ----------
function render(data) {
  els.improved.textContent = data.improved_description || "—";

  // Score + progress bar (animate from 0).
  const score = Number(data.tasker_match_score) || 0;
  els.scoreValue.textContent = score;
  els.scoreBar.style.width = "0%";
  requestAnimationFrame(() => {
    els.scoreBar.style.width = score + "%";
  });

  // Budget badge.
  const status = (data.budget_assessment?.status || "Fair").toString();
  els.budgetBadge.textContent = status;
  els.budgetBadge.className = "badge-status " + status.toLowerCase();
  els.budgetExplanation.textContent = data.budget_assessment?.explanation || "";

  els.budgetRange.textContent = data.suggested_budget_range || "—";
  els.completionTime.textContent = data.estimated_completion_time || "—";

  // Missing information.
  els.missingList.innerHTML = "";
  const missing = data.missing_information || [];
  if (missing.length === 0) {
    els.missingList.classList.add("empty");
    const li = document.createElement("li");
    li.textContent = "Nothing important is missing.";
    els.missingList.appendChild(li);
  } else {
    els.missingList.classList.remove("empty");
    missing.forEach((item) => {
      const li = document.createElement("li");
      li.textContent = item;
      els.missingList.appendChild(li);
    });
  }

  els.reasoning.textContent = data.reasoning || "";

  els.results.hidden = false;
  els.results.scrollIntoView({ behavior: "smooth", block: "start" });
}

// ---------- Copy button ----------
async function copyDescription() {
  const text = els.improved.textContent || "";
  if (!text) return;

  try {
    await navigator.clipboard.writeText(text);
  } catch {
    // Fallback for older browsers / insecure contexts.
    const ta = document.createElement("textarea");
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    document.body.removeChild(ta);
  }

  els.copyBtn.textContent = "Copied!";
  els.copyBtn.classList.add("copied");
  setTimeout(() => {
    els.copyBtn.textContent = "Copy";
    els.copyBtn.classList.remove("copied");
  }, 1600);
}

// ---------- Helpers ----------
function setLoading(isLoading) {
  els.loading.hidden = !isLoading;
  els.analyzeBtn.disabled = isLoading;
  els.analyzeBtn.querySelector(".btn-label").textContent = isLoading
    ? "Analyzing…"
    : "Analyze Task";
  if (isLoading) els.results.hidden = true;
}

function showError(message) {
  els.errorBox.textContent = message;
  els.errorBox.hidden = false;
}

function hideError() {
  els.errorBox.hidden = true;
}
