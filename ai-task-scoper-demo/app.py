"""AI Task Scoper - Flask entry point.

Run with:
    pip install -r requirements.txt
    python app.py

Then open http://localhost:5000 in your browser.
"""

import os

from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request

# Load variables from .env into the environment before anything else.
load_dotenv()

from services.task_scoper_service import scope_task  # noqa: E402

app = Flask(__name__)


@app.route("/")
def index():
    """Serve the single-page app."""
    return render_template("index.html")


@app.route("/api/scope", methods=["POST"])
def api_scope():
    """Analyze a task posting and return structured JSON."""
    payload = request.get_json(silent=True) or {}
    task_text = payload.get("task", "")

    try:
        result = scope_task(task_text)
    except ValueError as exc:
        # Expected, user-facing problems.
        return jsonify({"error": str(exc)}), 400
    except Exception:  # noqa: BLE001 - last-resort safety net
        return jsonify({"error": "Something went wrong. Please try again."}), 500

    return jsonify(result), 200


if __name__ == "__main__":
    port = int(os.getenv("FLASK_PORT", "5000"))
    debug = os.getenv("FLASK_DEBUG", "true").lower() == "true"
    app.run(host="127.0.0.1", port=port, debug=debug)
