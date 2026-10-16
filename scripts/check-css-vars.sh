#!/usr/bin/env bash
# Fails if any var(--x) has no matching --x: definition. An undefined custom
# property makes its declaration silently compute to `unset` (#157) — nothing
# else in the build or a11y checks notices.

set -euo pipefail
cd "$(dirname "$0")/.."

dirs=(site/assets site/layouts site/content)
used=$(grep -rhoE 'var\(--[A-Za-z0-9_-]+' "${dirs[@]}" | sed 's/^var(//' | sort -u)
defined=$(grep -rhoE -- '--[A-Za-z0-9_-]+[[:space:]]*:' "${dirs[@]}" | sed -E 's/[[:space:]]*:$//' | sort -u)
missing=$(comm -23 <(echo "$used") <(echo "$defined"))

if [ -n "$missing" ]; then
  echo "Undefined CSS custom properties:"
  for v in $missing; do
    grep -rnF "var($v" "${dirs[@]}" | sed 's/^/  /'
  done
  exit 1
fi
echo "All $(echo "$used" | wc -l | tr -d ' ') CSS custom properties are defined."
