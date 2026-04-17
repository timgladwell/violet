#!/usr/bin/env bash
# build.sh — Cloudflare Pages build entry point.
#
# This file lives in site/, which is configured as the Cloudflare Pages
# build root directory. Hugo is invoked from here with no --source flag.
#
# Cloudflare sets CF_PAGES_BRANCH to the branch being built and CF_PAGES_URL
# to the full deployment URL. We use these to select the correct Hugo environment
# so that config/staging/hugo.toml overrides are applied on any staging* branch,
# with the baseURL set dynamically so each staging slot gets its own URL.
#
# In the Cloudflare Pages dashboard, set the build command to:
#   bash build.sh

set -euo pipefail

if [[ "${CF_PAGES_BRANCH:-}" == staging* ]]; then
  echo "Building for staging (branch: $CF_PAGES_BRANCH, url: ${CF_PAGES_URL:-unknown})"
  hugo --environment staging --baseURL "${CF_PAGES_URL:-/}"
else
  echo "Building for production (branch: ${CF_PAGES_BRANCH:-unknown})"
  hugo
fi
