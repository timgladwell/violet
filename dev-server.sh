#!/usr/bin/env bash
# dev-server.sh
#
# Builds the site and starts the Hugo development server in a tmux session.
# Attaches to an existing session if one is already running.
#
# USAGE:
#   ./dev-server.sh        — build, start server, attach to tmux
#   ./dev-server.sh --ci   — build, check if server is running

set -euo pipefail

CI=false
[[ "${1:-}" == "--ci" ]] && CI=true

PORT=1313
URL="http://localhost:${PORT}"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
WORKTREE=$(basename "$(git rev-parse --show-toplevel)")
SESSION="violet-dev-server"
WINDOW_NAME="dev-server: $BRANCH [$WORKTREE]"

if ! $CI; then
  echo "Branch:   $BRANCH"
  echo "Worktree: $WORKTREE"
  echo "URL:      $URL"
  echo ""
fi

# Load env so it's inherited by the tmux session and the hugo server process
# shellcheck disable=SC1091
[ -f .env.local ] && set -a && source .env.local && set +a

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if $CI; then
    # The server is ready for CI
    exit 0
  fi
  echo "Attaching to existing '$SESSION' session..."
  tmux attach-session -t "$SESSION"
  exit 0
elif $CI; then
  # The server isn't running, return failure
  exit 1
fi

HUGO_CMD="hugo server --source site --environment staging --logLevel debug --port $PORT --disableFastRender"

tmux new-session -d -s "$SESSION" -x 220 -y 50
tmux send-keys -t "$SESSION" "$HUGO_CMD" Enter
tmux rename-window -t "$SESSION" "$WINDOW_NAME"
tmux split-window -t "$SESSION" -h -l 75%

if $CI; then
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
