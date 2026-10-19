#!/usr/bin/env bash
# cloudflare-build-log.sh
#
# Prints the Cloudflare Pages build log for the latest deployment of a branch,
# waiting for it to finish if it is still building. Useful straight after
# ./deploy-staging.sh: the log shows which Hugo was installed and which ran.
#
# USAGE
#   ./cloudflare-build-log.sh             # branch: staging
#   ./cloudflare-build-log.sh release     # any branch Cloudflare builds
#
# TOKEN
#   The same read-only token as ./export-cloudflare.sh (needs Account ->
#   Cloudflare Pages -> Read), found the same way - see cloudflare-token.sh.

set -euo pipefail

BRANCH="${1:-staging}"
ZONE_ID="${CF_ZONE_ID:-df4711b6c10cf3043898e21d6c23f007}"
API=https://api.cloudflare.com/client/v4

command -v jq >/dev/null || { echo "ERROR: jq is required (brew install jq)" >&2; exit 1; }

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cloudflare-token.sh"
auth=(-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

ACCOUNT_ID=$(curl -s "${auth[@]}" "$API/zones/$ZONE_ID" | jq -r '.result.account.id // empty')
[[ -n "$ACCOUNT_ID" ]] || { echo "ERROR: could not read the zone - check the token." >&2; exit 1; }
DEPLOYS="$API/accounts/$ACCOUNT_ID/pages/projects/violet/deployments"

while :; do
  D=$(curl -s "${auth[@]}" "$DEPLOYS" | jq -c --arg b "$BRANCH" \
    '[.result[] | select(.deployment_trigger.metadata.branch == $b)][0] // empty')
  [[ -n "$D" ]] || { echo "ERROR: no recent deployment for branch '$BRANCH'." >&2; exit 1; }
  STATUS=$(jq -r '.latest_stage.status' <<<"$D")
  STAGE=$(jq -r '.latest_stage.name' <<<"$D")
  # Done when it has failed anywhere, or the final deploy stage has succeeded.
  [[ "$STATUS" == "failure" || ( "$STAGE" == "deploy" && "$STATUS" == "success" ) ]] && break
  echo "… $BRANCH is at $STAGE ($STATUS); checking again in 10s" >&2
  sleep 10
done

jq -r '"Deployment \(.id)\nCommit     \(.deployment_trigger.metadata.commit_hash[0:7]) \(.deployment_trigger.metadata.commit_message | split("\n")[0])\nResult     \(.latest_stage.name): \(.latest_stage.status)\n"' <<<"$D"
curl -s "${auth[@]}" "$DEPLOYS/$(jq -r .id <<<"$D")/history/logs" | jq -r '.result.data[].line'
[[ "$STATUS" == "success" ]]
