#!/usr/bin/env bash
# Log a task to the Revex brain. Captures start time on the first call and
# end time + duration on the second. Same destination as Claude Code's
# global hook → unified team-wide telemetry in claude_task_log.
#
# Usage:
#   ./scripts/log-task.sh start "Brief description of what you're about to do"
#   ./scripts/log-task.sh end "Brief description" "Complications encountered or 'none'"
#
# Required env vars (set once in your shell rc, gitignored .env.local, or
# Cursor's project env):
#   REVEX_TASK_LOG_KEY   — the INTERNAL_API_KEY (ask Zachary)
#
# Optional:
#   REVEX_TASK_LOG_URL   — defaults to revexapi-production.up.railway.app
#   REVEX_AI_TOOL        — defaults to "cursor" (or set to "claude-code", etc.)

set -uo pipefail

CMD="${1:-}"
TASK="${2:-}"
COMPLICATIONS="${3:-none}"

URL="${REVEX_TASK_LOG_URL:-https://revexapi-production.up.railway.app/webhooks/task-log}"
KEY="${REVEX_TASK_LOG_KEY:-}"
TOOL="${REVEX_AI_TOOL:-cursor}"

PROJECT_PATH="$PWD"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

STATE_DIR="${HOME}/.revex/task-state"
mkdir -p "$STATE_DIR" 2>/dev/null || true
# Slugify project + cwd hash so two concurrent projects don't collide
SLUG=$(echo "${PROJECT_PATH}" | shasum 2>/dev/null | awk '{print $1}' | cut -c1-12)
STATE_FILE="${STATE_DIR}/${SLUG}.json"

# JSON escape helper
json_escape() {
  printf '%s' "$1" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null \
    || printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

case "$CMD" in
  start)
    if [ -z "$TASK" ]; then
      echo "Usage: log-task.sh start \"Task description\"" >&2
      exit 1
    fi
    START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"start_time":"%s","task":"%s"}\n' "$START" "$(json_escape "$TASK")" > "$STATE_FILE"
    ;;

  end)
    if [ -z "$TASK" ]; then
      echo "Usage: log-task.sh end \"Task description\" \"Complications or 'none'\"" >&2
      exit 1
    fi
    if [ -z "$KEY" ]; then
      echo "[log-task] REVEX_TASK_LOG_KEY not set — skipping log (non-fatal)" >&2
      exit 0
    fi

    END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if [ -f "$STATE_FILE" ]; then
      START="$(grep -o '"start_time":"[^"]*"' "$STATE_FILE" | sed 's/.*:"\(.*\)"/\1/')"
    else
      # No prior start — log with start=end (zero duration). Better than nothing.
      START="$END"
    fi

    TASK_ESC="$(json_escape "$TASK")"
    COMP_FIELD=""
    if [ -n "$COMPLICATIONS" ] && [ "$COMPLICATIONS" != "none" ] && [ "$COMPLICATIONS" != "None" ]; then
      COMP_FIELD=",\"complications\":\"$(json_escape "$COMPLICATIONS")\""
    fi

    BODY="{\"task\":\"$TASK_ESC\",\"start_time\":\"$START\",\"end_time\":\"$END\",\"tool\":\"$TOOL\",\"project\":\"$PROJECT_NAME\",\"project_path\":\"$PROJECT_PATH\"$COMP_FIELD}"

    # Fire and forget — failures are non-fatal, the task continues.
    curl -sS -X POST "$URL" \
      -H "Content-Type: application/json" \
      -H "X-Internal-Key: $KEY" \
      --max-time 10 \
      -d "$BODY" > /dev/null 2>&1 || true

    rm -f "$STATE_FILE" 2>/dev/null || true
    ;;

  *)
    echo "Usage: log-task.sh <start|end> \"Task description\" [\"Complications or 'none'\"]" >&2
    exit 1
    ;;
esac
