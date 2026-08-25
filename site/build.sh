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

# Build identifier, surfaced as <meta name="build"> on every page and in the
# staging banner so a deployed page can be traced back to an exact commit.
#
# Exported as HUGO_PARAMS_* rather than read in the template with getenv, which
# Hugo allowlists to ^HUGO_ names by default — getenv "CF_PAGES_COMMIT_SHA"
# would silently return empty. These are derived here rather than configured in
# the Cloudflare dashboard, so there is nothing to keep in sync across the
# Production and Preview scopes.
#
# CHANGELOG.md is at the repo root; this script runs from site/.
export HUGO_PARAMS_BUILDSHA="${CF_PAGES_COMMIT_SHA:-}"
export HUGO_PARAMS_BUILDVERSION="$(sed -n 's/^## \(v[0-9][^ ]*\)$/\1/p' ../CHANGELOG.md | head -1)"

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
