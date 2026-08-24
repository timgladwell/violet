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
# CF_PAGES_URL is the *per-deployment* hash URL (https://39f9da42.violet-6qt.pages.dev),
# not the branch alias, so anything built from it has canonical/og:url/JSON-LD
# pointing at a hostname that changes every build. The default `staging` slot is
# served in-zone at a fixed hostname, so it takes its baseURL from
# config/staging/hugo.toml instead - the same way production takes its own from
# hugo.toml. Only the numbered slots, which have no fixed hostname, fall back to
# CF_PAGES_URL.
#
# In the Cloudflare Pages dashboard, set the build command to:
#   bash build.sh

set -euo pipefail

if [[ "${CF_PAGES_BRANCH:-}" == staging* ]]; then
  if [[ "${CF_PAGES_BRANCH:-}" == "staging" ]]; then
    echo "Building for staging (branch: $CF_PAGES_BRANCH, baseURL from config/staging/hugo.toml)"
    hugo --environment staging
  else
    echo "Building for staging (branch: $CF_PAGES_BRANCH, url: ${CF_PAGES_URL:-/})"
    hugo --environment staging --baseURL "${CF_PAGES_URL:-/}"
  fi
else
  echo "Building for production (branch: ${CF_PAGES_BRANCH:-unknown})"
  hugo
fi
