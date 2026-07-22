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

# shellcheck disable=SC1091
[ -f .env.local ] && set -a && source .env.local && set +a

step "Build"         hugo build site --source site --environment development --logLevel debug
step "Environments"  ./check-environments.sh
step "Markdown lint" npm run lint:md

./dev-server.sh --ci
STARTED_SERVER=false
[ -f .dev-server.lock ] && STARTED_SERVER=true

step "Accessibility" npm run a11y

if $STARTED_SERVER; then
  ./dev-server.sh --stop
fi

echo ""
echo "────────────────────────────────"
if [ "$FAIL" -gt 0 ]; then
  echo "Result: $FAIL step(s) failed, $PASS passed"
  exit 1
else
  echo "Result: all $PASS steps passed"
fi
