#!/usr/bin/env bash
# localdev.sh
#
# Starts the Hugo development server using the staging environment config,
# matching what Cloudflare Pages builds on the staging branch.
#
# USAGE:
#   ./localdev.sh

set -euo pipefail

PORT=1313
URL="http://localhost:${PORT}"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Set terminal title to branch name — persists in the title bar regardless of scroll
printf '\033]0;localdev: %s\007' "$BRANCH"

echo "Branch: $BRANCH"
echo "URL:    $URL"
echo ""

# Open the browser once Hugo is ready
(sleep 1 && open "$URL") &

hugo server \
  --source site \
  --environment staging \
  --port "$PORT" \
  --disableFastRender
