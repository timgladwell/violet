#!/usr/bin/env bash
# Runs a WCAG 2.1 AA accessibility check against the local dev server.
#
# USAGE:
#   ./a11y.sh
#
# Requires the dev server to be running (./localdev.sh).
#
# To suppress a specific rule, add it to the "rules" object in .axe.json:
#   "rules": { "color-contrast": { "enabled": false } }

set -euo pipefail

BASE="http://localhost:1313"

if ! curl -s --max-time 2 "$BASE" > /dev/null; then
  echo "Error: No server found at $BASE" >&2
  echo "Start the dev server with ./localdev.sh first" >&2
  exit 1
fi

TAGS=$(node -e "const c=require('./.axe.json'); console.log(c.runOnly.values.join(','))")
DISABLED=$(node -e "const c=require('./.axe.json'); const d=Object.entries(c.rules||{}).filter(([,v])=>v.enabled===false).map(([k])=>k); if(d.length) console.log(d.join(','))")

echo "Running WCAG 2.1 AA check against $BASE"
echo ""

DISABLE_ARGS=()
[ -n "$DISABLED" ] && DISABLE_ARGS=(--disable "$DISABLED")

npx axe \
  "${BASE}/" \
  "${BASE}/about/" \
  "${BASE}/services/" \
  "${BASE}/what-we-treat/" \
  "${BASE}/faq/" \
  "${BASE}/privacy/" \
  "${BASE}/medical-disclaimer/" \
  --tags "$TAGS" \
  ${DISABLE_ARGS[@]+"${DISABLE_ARGS[@]}"} \
  --exit
