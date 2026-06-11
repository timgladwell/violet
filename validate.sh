#!/usr/bin/env bash
# validate.sh
#
# Runs the full local validation suite: build, markdown lint, and accessibility.
# Starts the dev server if it isn't already running, and stops it afterwards.
#
# USAGE:
#   ./validate.sh

set -euo pipefail

PASS=0
FAIL=0

step() {
  local name="$1"
  shift
  echo ""
  echo "── $name"
  if "$@"; then
    echo "   ✓ passed"
    PASS=$((PASS + 1))
  else
    echo "   ✗ failed"
    FAIL=$((FAIL + 1))
  fi
}

echo "Validating site..."

step "Build"         hugo build site --source site --environment development --logLevel debug
step "Markdown lint" npm run lint:md

if ! ./dev-server.sh --ci; then
    echo "Running localdev server is required for CI - run ./dev-server.sh and retry"
    echo ""
    exit 1
fi

step "Accessibility" npm run a11y

echo ""
echo "────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL step(s) failed, $PASS passed"
  exit 1
else
  echo "Result: all $PASS steps passed"
fi
