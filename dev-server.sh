#!/usr/bin/env bash
# dev-server.sh
#
# Builds the site and starts the Hugo development server in a tmux session.
# Attaches to an existing session if one is already running.
#
# Ownership: a session this script starts gets a lock file (.dev-server.lock).
# --stop only kills the session if that lock is present, so it never kills a
# server someone else started.
#
# USAGE:
#   ./dev-server.sh        — build, start server (or attach if already running)
#   ./dev-server.sh --ci   — ensure server is running headlessly, no attach
#   ./dev-server.sh --stop — stop the server, but only if this script started it

set -euo pipefail

MODE="interactive"
case "${1:-}" in
  --ci) MODE="ci" ;;
  --stop) MODE="stop" ;;
esac

PORT=1313
URL="http://localhost:${PORT}"
SESSION="violet-localdev"
LOCK=".dev-server.lock"

# Load env so it's inherited by the tmux session and the hugo server process
# shellcheck disable=SC1091
[ -f .env.local ] && set -a && source .env.local && set +a

if [ -f .tool-versions ] && command -v hugo >/dev/null 2>&1; then
  PINNED=$(grep '^hugo ' .tool-versions | awk '{print $2}')
  INSTALLED=$(hugo version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | tr -d v)
  if [ -n "$PINNED" ] && [ "$PINNED" != "$INSTALLED" ]; then
    echo "Warning: installed Hugo is $INSTALLED, .tool-versions pins $PINNED" >&2
  fi
fi

if [ "$MODE" = "stop" ]; then
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "No '$SESSION' session running."
    exit 0
  fi
  if [ -f "$LOCK" ]; then
    tmux kill-session -t "$SESSION"
    rm -f "$LOCK"
    echo "Stopped '$SESSION'."
    exit 0
  fi
  echo "'$SESSION' wasn't started by this tooling, not stopping it." >&2
  exit 1
fi

if [ "$MODE" = "interactive" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  WORKTREE=$(basename "$(git rev-parse --show-toplevel)")
  echo "Branch:   $BRANCH"
  echo "Worktree: $WORKTREE"
  echo "URL:      $URL"
  echo ""
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [ "$MODE" = "ci" ]; then
    exit 0
  fi
  echo "Attaching to existing '$SESSION' session..."
  tmux attach-session -t "$SESSION"
  exit 0
fi

HUGO_CMD="hugo server --source site --environment development --logLevel debug --port $PORT --disableFastRender"
WINDOW_NAME="dev-server: $(git rev-parse --abbrev-ref HEAD) [$(basename "$(git rev-parse --show-toplevel)")]"

tmux new-session -d -s "$SESSION" -x 220 -y 50
tmux send-keys -t "$SESSION" "$HUGO_CMD" Enter
tmux rename-window -t "$SESSION" "$WINDOW_NAME"
tmux split-window -t "$SESSION" -h -l 75%
echo "$SESSION" > "$LOCK"

if [ "$MODE" = "ci" ]; then
  echo "Waiting for server at $URL..."
  for i in $(seq 1 15); do
    curl -s --max-time 1 "$URL" > /dev/null 2>&1 && echo "Server ready." && exit 0
    sleep 1
  done
  echo "Error: server did not start in time." >&2
  exit 1
fi

echo "Started tmux session '$SESSION'. Attaching..."
(sleep 1 && open "$URL") &
tmux attach-session -t "$SESSION"
