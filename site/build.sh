#!/usr/bin/env bash
# build.sh — Cloudflare Pages build entry point.
#
# This file lives in site/, which is configured as the Cloudflare Pages
# build root directory. Hugo is invoked from here with no --source flag.
#
# Cloudflare sets CF_PAGES_BRANCH to the branch being built.
# We use this to select the correct Hugo environment so that
# config/staging/hugo.toml overrides are applied on the staging branch.
#
# In the Cloudflare Pages dashboard, set the build command to:
#   bash build.sh

set -euo pipefail

if [[ "${CF_PAGES_BRANCH:-}" == "staging" ]]; then
  echo "Building for staging (branch: $CF_PAGES_BRANCH)"
  hugo --environment staging
else
  echo "Building for production (branch: ${CF_PAGES_BRANCH:-unknown})"
  hugo
fi
