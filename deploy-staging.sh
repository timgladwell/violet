#!/usr/bin/env bash
# deploy-staging.sh
#
# Pushes committed changes from the current branch to the staging branch.
# Cloudflare Pages detects the push and rebuilds the staging site automatically.
#
# FIRST-TIME SETUP (one-off, done in the Cloudflare Pages dashboard):
#   Settings → Build & deployments → Build configurations → Build command:
#     bash build.sh
#   build.sh checks $CF_PAGES_BRANCH and runs Hugo with --environment staging
#   on the staging branch, activating site/config/staging/hugo.toml overrides:
#     - baseURL points to the staging domain
#     - isStaging = true (staging banner, no indexing, coming-soon bypassed)
#
# USAGE:
#   ./deploy-staging.sh           — push current branch to staging
#   ./deploy-staging.sh --dry-run — show what would be pushed without doing it

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_SHA=$(git rev-parse --short HEAD)

if [[ "$CURRENT_BRANCH" == "staging" ]]; then
  echo "Error: already on the staging branch. Check out a feature or topic branch first." >&2
  exit 1
fi

# Warn if there are uncommitted changes (they won't be included in the push)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: you have uncommitted changes. Commit or stash your changes first."
  exit 1
fi

echo "Branch : $CURRENT_BRANCH"
echo "Commit : $CURRENT_SHA  $(git log -1 --pretty=%s)"
echo "Target : staging → https://staging.violet-6qt.pages.dev/"
echo ""

if $DRY_RUN; then
  echo "[dry-run] Would run: git push origin HEAD:staging --force"
  exit 0
fi

git push origin HEAD:staging --force

echo ""
echo "Done. Cloudflare Pages is now building the staging site."
echo "Check build status at: https://dash.cloudflare.com"
