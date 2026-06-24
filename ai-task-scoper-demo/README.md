# AI Task Scoper — Demo

A small standalone web app that analyzes a task posting (e.g. "fix my leaking
tap") and uses the OpenAI API to return:

1. An improved task description
2. Missing information the customer should add
3. A budget assessment (**Low / Fair / High**)
4. A suggested budget range
5. An estimated completion time
6. A tasker match score (0–100)
7. Short reasoning

> This is a self-contained demo. It does **not** modify or depend on the
> Flutter TOLY MOLY project it sits beside.

## Tech stack

- **Python + Flask** — backend and JSON API
- **HTML / CSS / vanilla JavaScript** — single-page frontend
- **OpenAI API** — the AI analysis

## Project structure

```
ai-task-scoper-demo/
├── app.py                          # Flask entry point + routes
├── services/
│   └── task_scoper_service.py      # talks to the OpenAI API
├── prompts/
│   └── task_scoper_prompt.py       # the AI prompt
├── templates/
│   └── index.html                  # single-page UI
├── static/
│   ├── css/style.css
│   └── js/main.js
├── requirements.txt
├── .env.example
└── README.md
```

## Setup & run

1. **Create the environment file.** Copy `.env.example` to `.env` and add your
   OpenAI key:

   ```bash
   cp .env.example .env
   ```

   Then edit `.env`:

   ```
   OPENAI_API_KEY=sk-...your-key...
   ```

2. **Install dependencies** (a virtual environment is recommended):

   ```bash
   pip install -r requirements.txt
   ```

3. **Run the app:**

   ```bash
   python app.py
   ```

4. Open **http://localhost:5000** in your browser.

## How it works

- The frontend sends your task text to `POST /api/scope` as JSON.
- `app.py` passes it to `services/task_scoper_service.py`.
- The service builds a prompt (`prompts/task_scoper_prompt.py`), calls the
  OpenAI API in JSON mode, validates the response, and returns a clean dict.
- The frontend renders the results: copy button for the improved description,
  a progress bar for the match score, and a colored badge for the budget
  status.

## Configuration

Set these in `.env` (all optional except the key):

| Variable | Default | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | _(required)_ | Your OpenAI API key |
| `OPENAI_MODEL` | `gpt-4o-mini` | Which chat model to use |
| `FLASK_PORT` | `5000` | Local port |
| `FLASK_DEBUG` | `true` | Flask debug mode |

## Notes

- `.env` is git-ignored so your key is never committed. Keep it private — if a
  key is ever exposed, rotate it at https://platform.openai.com/api-keys.
- Errors (missing key, network issues, bad input) are shown in the UI rather
  than crashing the page.
