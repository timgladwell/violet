#!/usr/bin/env bash
# cloudflare-sweep.sh
#
# Finds Cloudflare configuration that export-cloudflare.sh doesn't capture.
#
# WHY THIS EXISTS
#   The export's list of API calls is hand-kept, and each gap so far (fonts,
#   DNSSEC, preview branch control, the registrar) was found by tripping over
#   it. This GETs every zone- and account-level endpoint in Cloudflare's
#   OpenAPI schema (github.com/cloudflare/api-schemas) that needs no extra path
#   parameter, and lists the ones that return data the export doesn't fetch.
#   The output is a list to triage, not something to commit: most of it is
#   catalogs, analytics and paid features. Add what matters to the export.
#
# USAGE
#   ./cloudflare-sweep.sh        # token as for export-cloudflare.sh; ~5 minutes
#
#   GET only, so a read-only token is enough. Raw responses go to a temp
#   directory outside the repo, because they can hold what the export redacts
#   (Pages env var values, member and billing details). Don't commit or paste
#   them. Settings reachable only through /settings/{setting_id} can't be
#   listed from the schema (it has no enum of names), so they stay invisible.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API=https://api.cloudflare.com/client/v4
ZONE_ID="${CF_ZONE_ID:-df4711b6c10cf3043898e21d6c23f007}"
OUT="$(mktemp -d -t cloudflare-sweep)"

command -v jq >/dev/null || { echo "ERROR: jq is required (brew install jq)" >&2; exit 1; }
. "$REPO_ROOT/cloudflare-token.sh"
auth=(-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
ACCOUNT_ID=$(jq -r '.result.account.id' "$REPO_ROOT/docs/current-state/cloudflare-export/zone.json")
mkdir -p "$OUT/raw"

echo "== schema"
curl -sfL -o "$OUT/openapi.json" https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json \
  || { echo "ERROR: could not download the schema" >&2; exit 1; }

# Paths the export already fetches, in schema form.
grep -oE '"(zones|accounts)/\$(ZONE_ID|ACCOUNT_ID)[^"?]*' "$REPO_ROOT/export-cloudflare.sh" \
  | sed -e 's/^"/\//' -e 's/\$ZONE_ID/{zone_id}/' -e 's/\$ACCOUNT_ID/{account_id}/' | sort -u > "$OUT/captured.txt"
# The export fetches these individual settings in a loop, so name them too.
sed -n 's/^for s in \(.*\); do$/\1/p; /^for s in/,/; do$/p' "$REPO_ROOT/export-cloudflare.sh" \
  | tr -s ' \\;' '\n' | grep -E '^[a-z0-9_]+$' | grep -vxE 'for|s|in|do' \
  | sed 's|^|/zones/{zone_id}/settings/|' >> "$OUT/captured.txt"

# Candidate GETs: path, free-plan flag, read permission groups.
jq -r '.paths | to_entries[] | select(.value.get) |
  select(.key | test("^/(zones/\\{zone_id\\}|accounts/\\{account_id\\})(/|$)")) |
  select(.key | sub("^/(zones/\\{zone_id\\}|accounts/\\{account_id\\})"; "") | test("\\{") | not) |
  [.key, (.value.get["x-cfPlanAvailability"].free // "?" | tostring),
   ((.value.get["x-api-token-group"] // []) | map(select(test("Read"))) | join(","))] | @tsv' \
  "$OUT/openapi.json" | sort > "$OUT/candidates.tsv"
echo "  $(wc -l < "$OUT/candidates.tsv" | tr -d ' ') endpoints"

echo "== sweep"
printf 'path\tcaptured\tfree\thttp\tresult\thint\ttoken_group\n' > "$OUT/summary.tsv"
i=0
while IFS=$'\t' read -r path free group; do
  i=$((i + 1)); printf '\r  %d' "$i" >&2
  url="${path/\{zone_id\}/$ZONE_ID}"; url="${url/\{account_id\}/$ACCOUNT_ID}"
  f="$OUT/raw/$(echo "$path" | tr '/{}' '_  ' | tr -d ' ').json"
  code=$(curl -s -m 20 -o "$f" -w '%{http_code}' "${auth[@]}" "$API$url")
  captured=$(grep -qxF "$path" "$OUT/captured.txt" && echo yes || echo no)
  # Shape only, never values: array length, or the enabled/status/value of an object.
  read -r result hint < <(jq -r '
    if (.result|type)=="array" then "array:\(.result|length) -"
    elif (.result|type)=="object" then
      "object \(.result | (if has("enabled") then .enabled elif has("status") then .status
        elif (.value|type)=="string" then .value else "-" end) | tostring | .[0:30] | gsub("\\s";"_"))"
    elif .result == null then "null -" else "\(.result|type) -" end' "$f" 2>/dev/null || echo "non-json -")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$path" "$captured" "$free" "$code" "$result" "$hint" "$group" >> "$OUT/summary.tsv"
  sleep 0.3 # Cloudflare allows 1200 requests per 5 minutes
done < "$OUT/candidates.tsv"
echo >&2

echo "== returned data, not in the export"
awk -F'\t' 'NR>1 && $2=="no" && $4=="200" && $5!="array:0" && $5!="null -" && $5!="null" {print $5"\t"$6"\t"$1}' "$OUT/summary.tsv" \
  | column -t -s $'\t'
echo
echo "== counts by http status"
awk -F'\t' 'NR>1 {c[$4]++} END {for (k in c) print "  " k ": " c[k]}' "$OUT/summary.tsv" | sort
echo
echo "Full table: $OUT/summary.tsv"
echo "Raw bodies: $OUT/raw (outside the repo; do not commit or paste)"
