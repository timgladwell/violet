#!/usr/bin/env bash
# deploy-staging.sh
#
# Pushes committed changes from the current branch to a staging branch.
# Cloudflare Pages detects the push and rebuilds the staging site automatically.
#
# FIRST-TIME SETUP (one-off, done in the Cloudflare Pages dashboard):
#   Settings → Build & deployments → Build configurations → Build command:
#     bash build.sh
#   site/build.sh checks $CF_PAGES_BRANCH and runs Hugo with --environment staging
#   on any branch matching staging*, activating config/staging/hugo.toml overrides:
#     - isStaging = true (staging banner, no indexing, coming-soon bypassed)
#   baseURL is set dynamically from $CF_PAGES_URL so each slot gets its own URL.
#
# USAGE:
#   ./deploy-staging.sh              — push current branch to staging
#   ./deploy-staging.sh staging2     — push current branch to staging2
#   ./deploy-staging.sh staging3     — push current branch to staging3
#   ./deploy-staging.sh --dry-run    — show what would be pushed without doing it
#   ./deploy-staging.sh staging2 --dry-run

set -euo pipefail

TARGET_BRANCH="staging"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    staging|staging[0-9]*) TARGET_BRANCH="$arg" ;;
    *) echo "Error: unknown argument '$arg'" >&2; exit 1 ;;
  esac
done

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_SHA=$(git rev-parse --short HEAD)

if [[ "$CURRENT_BRANCH" == "$TARGET_BRANCH" ]]; then
  echo "Error: already on the $TARGET_BRANCH branch. Check out a feature or topic branch first." >&2
  exit 1
fi

# Warn if there are uncommitted changes (they won't be included in the push)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: you have uncommitted changes. Commit or stash your changes first."
  exit 1
fi

# Cloudflare Pages serves each branch at <branch-name>.<project>.pages.dev
STAGING_URL="https://${TARGET_BRANCH}.violet-6qt.pages.dev/"

echo "Branch : $CURRENT_BRANCH"
echo "Commit : $CURRENT_SHA  $(git log -1 --pretty=%s)"
echo "Target : $TARGET_BRANCH → $STAGING_URL"
echo ""

if $DRY_RUN; then
  echo "[dry-run] Would run: git push origin HEAD:$TARGET_BRANCH --force"
  exit 0
fi

git push origin "HEAD:$TARGET_BRANCH" --force

echo ""
echo "Done. Cloudflare Pages is now building the staging site."
echo "Check build status at: https://dash.cloudflare.com"
