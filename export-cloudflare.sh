#!/usr/bin/env bash
# export-cloudflare.sh
#
# Exports the live Cloudflare configuration for ontariomenopauseclinic.ca into
# docs/cloudflare-export/ so it is committed to the repo.
#
# WHY THIS EXISTS
#   Cloudflare holds configuration that is not reproducible from this repo: DNS
#   records, the www-to-apex redirect rule, zone settings, and the Pages project
#   (custom domains, build config). Losing the account, or rebuilding the site
#   from scratch, means recreating all of it by hand. This export is the record
#   to rebuild from. There is deliberately no Terraform - see the GitHub issue -
#   so this script is the continuity plan.
#
#   A previous version of this script was never committed and is gone. That is
#   the reason it now lives here rather than in someone's home directory.
#
# WHAT IT DOES NOT CAPTURE
#   Secret values. Pages environment variable *names* are exported; their values
#   are not - those live in 1Password, with placeholders in .env.local.example.
#   The API token itself is never written anywhere.
#
# USAGE
#   ./export-cloudflare.sh          # prompts for the token; hidden, no shell history
#
#   With the 1Password CLI (brew install 1password-cli, then enable
#   Settings -> Developer -> Integrate with 1Password CLI in the desktop app):
#     CLOUDFLARE_API_TOKEN="$(op read 'op://Private/Cloudflare Read All Token/credential')" ./export-cloudflare.sh
#
#   The last path segment is the FIELD name, and it varies by item type:
#     API Credential item -> credential      Login item -> password
#   Confirm with: op item get "Cloudflare Read All Token" --format json | jq -r ".fields[].label"
#
#   Passing the token inline puts it in shell history verbatim; prefer the
#   prompt, or `op`, which substitutes at run time.
#
#   Then review and commit the diff. `git status` after a run IS the drift
#   check: if the export changes, Cloudflare changed since the last commit.
#
# TOKEN
#   A READ-ONLY token is sufficient and is what should be used. Create at
#   dash.cloudflare.com -> My Profile -> API Tokens. The "Read all resources"
#   template works; a minimal custom token needs:
#     Zone    -> Zone           -> Read
#     Zone    -> DNS            -> Read
#     Zone    -> Zone Settings  -> Read
#     Zone    -> Config Rules   -> Read
#     Account -> Cloudflare Pages -> Read
#   The Pages permission is account-scoped; zone permissions alone will not
#   return the Pages project, which is the most common reason for a partial run.

set -uo pipefail

ZONE_ID="${CF_ZONE_ID:-df4711b6c10cf3043898e21d6c23f007}"
API=https://api.cloudflare.com/client/v4
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$REPO_ROOT/docs/cloudflare-export"

command -v jq >/dev/null || { echo "ERROR: jq is required (brew install jq)" >&2; exit 1; }

# Prompt rather than require the token on the command line: a read-only token is
# still a credential, and `CLOUDFLARE_API_TOKEN=... ./export-cloudflare.sh` lands
# it in shell history verbatim. Reading it here keeps it out of history entirely.
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  if [[ -t 0 ]]; then
    printf 'Cloudflare API token (read-only; input hidden): ' >&2
    read -rs CLOUDFLARE_API_TOKEN
    printf '\n' >&2
  else
    echo "ERROR: CLOUDFLARE_API_TOKEN is not set and stdin is not a terminal." >&2
    echo "       See the header of this script." >&2
    exit 1
  fi
fi
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "ERROR: no token supplied." >&2
  exit 1
fi

auth=(-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json")
FAILED=0

get() { # get <api-path> <outfile> <label>
  local code
  code=$(curl -s -o "$OUT/$2" -w '%{http_code}' "${auth[@]}" "$API/$1")
  if [[ "$code" == "200" ]] && jq -e '.success == true' "$OUT/$2" >/dev/null 2>&1; then
    # Strip response envelope noise that churns between runs for no reason.
    jq 'del(.result_info, .messages)' "$OUT/$2" > "$OUT/$2.tmp" && mv "$OUT/$2.tmp" "$OUT/$2"
    printf '  ok    %s\n' "$3"
  else
    printf '  FAIL  %-26s (http %s) %s\n' "$3" "$code" \
      "$(jq -r '[.errors[]?.message] | join("; ")' "$OUT/$2" 2>/dev/null)" >&2
    rm -f "$OUT/$2"
    FAILED=1
  fi
}

mkdir -p "$OUT"

echo "== token"
curl -s "${auth[@]}" "$API/user/tokens/verify" \
  | jq -r 'if .success then "  valid" else "  INVALID: " + ([.errors[]?.message]|join("; ")) end'

echo "== zone"
get "zones/$ZONE_ID"                          zone.json     "zone"
get "zones/$ZONE_ID/dns_records?per_page=200" dns.json      "dns records"
get "zones/$ZONE_ID/settings"                 settings.json "zone settings"

echo "== rulesets"
get "zones/$ZONE_ID/rulesets" rulesets.json "ruleset index"
if [[ -f "$OUT/rulesets.json" ]]; then
  # The index lists rulesets but not their rules; fetch each one that has any.
  rm -f "$OUT/ruleset_"*.json
  for rs in $(jq -r '.result[]? | select(.kind=="zone") | .id' "$OUT/rulesets.json"); do
    phase=$(jq -r --arg id "$rs" '.result[] | select(.id==$id) | .phase' "$OUT/rulesets.json")
    get "zones/$ZONE_ID/rulesets/$rs" "ruleset_${phase}.json" "rules: $phase"
  done
fi

# Optional endpoints: features that may or may not be in use. A 403/404 here is
# information ("not enabled / not permitted"), not an error - so these are
# probed rather than required. This exists because nobody has been tracking what
# was turned on in the dashboard; the point is to discover it, not assume it.
probe() { # probe <api-path> <outfile> <label>
  local code
  code=$(curl -s -o "$OUT/$2" -w '%{http_code}' "${auth[@]}" "$API/$1")
  if [[ "$code" == "200" ]] && jq -e '.success == true' "$OUT/$2" >/dev/null 2>&1; then
    local n in_use
    n=$(jq -r 'if (.result|type)=="array" then (.result|length|tostring) else "present" end' "$OUT/$2")
    # A 200 only means the endpoint answered. Several features respond happily
    # while switched off (email routing returns enabled:false when unconfigured,
    # and ships a disabled catch-all rule), so "responded" is not "in use" -
    # reporting it as found sends you chasing config that does not exist.
    in_use=$(jq -r '
      def live: if type=="object" and has("enabled") then .enabled else true end;
      if (.result|type)=="array"
        then ((.result | map(select(live)) | length) > 0)
        else (.result | live) end' "$OUT/$2")
    if [[ "$n" == "0" || "$in_use" != "true" ]]; then
      # Keep the file when the endpoint answered but the feature is off: knowing
      # it is off is itself worth recording. Just do not list it as in use.
      if [[ "$n" == "0" ]]; then
        rm -f "$OUT/$2"; printf '  none  %s\n' "$3"
      else
        jq 'del(.result_info, .messages)' "$OUT/$2" > "$OUT/$2.tmp" && mv "$OUT/$2.tmp" "$OUT/$2"
        printf '  off   %-30s (present but disabled)\n' "$3"
      fi
    else
      jq 'del(.result_info, .messages)' "$OUT/$2" > "$OUT/$2.tmp" && mv "$OUT/$2.tmp" "$OUT/$2"
      printf '  FOUND %-30s (%s)\n' "$3" "$n"
      DISCOVERED="${DISCOVERED}${3}\n"
    fi
  else
    rm -f "$OUT/$2"
    printf '  n/a   %-30s (http %s)\n' "$3" "$code"
  fi
}
DISCOVERED=""

echo "== mail (non-DNS: routing. SPF/DKIM/DMARC are DNS and are in dns.json)"
probe "zones/$ZONE_ID/email/routing"        email_routing.json       "email routing settings"
probe "zones/$ZONE_ID/email/routing/rules"  email_routing_rules.json "email routing rules"
probe "zones/$ZONE_ID/email/routing/dns"    email_routing_dns.json   "email routing required DNS"

echo "== other zone features (discovery)"
probe "zones/$ZONE_ID/pagerules"            pagerules.json           "page rules (legacy)"
probe "zones/$ZONE_ID/workers/routes"       workers_routes.json      "workers routes"
probe "zones/$ZONE_ID/firewall/access_rules/rules" firewall_access.json "firewall access rules"
probe "zones/$ZONE_ID/ssl/certificate_packs" cert_packs.json         "certificate packs"
probe "zones/$ZONE_ID/custom_certificates"  custom_certs.json        "custom certificates"

echo "== pages"
ACCOUNT_ID=$(jq -r '.result.account.id // empty' "$OUT/zone.json" 2>/dev/null)
if [[ -n "$ACCOUNT_ID" ]]; then
  raw=$(mktemp)
  code=$(curl -s -o "$raw" -w '%{http_code}' "${auth[@]}" "$API/accounts/$ACCOUNT_ID/pages/projects")
  if [[ "$code" == "200" ]] && jq -e '.success == true' "$raw" >/dev/null 2>&1; then
    # Redact before anything touches the working tree: the raw response contains
    # env var VALUES (booking URL, contact addresses).
    jq '{result: [.result[] | {
          name, subdomain, production_branch, created_on,
          build_config,
          domains,
          deployment_configs: (.deployment_configs | with_entries(.value |= {
            compatibility_date,
            compatibility_flags,
            build_image_major_version,
            env_var_names: ((.env_vars // {}) | keys)
          }))
        }]}' "$raw" > "$OUT/pages_project.json"
    printf '  ok    pages project (env var values redacted)\n'
  else
    printf '  FAIL  %-26s (http %s) %s\n' "pages project" "$code" \
      "$(jq -r '[.errors[]?.message] | join("; ")' "$raw" 2>/dev/null)" >&2
    printf '        most likely cause: token lacks Account -> Cloudflare Pages -> Read\n' >&2
    FAILED=1
  fi
  rm -f "$raw"

  echo "== account features (discovery)"
  probe "accounts/$ACCOUNT_ID/email/routing/addresses" email_dest_addresses.json "email destination addresses"
  probe "accounts/$ACCOUNT_ID/rules/lists"             rules_lists.json          "bulk redirect / IP lists"
  probe "accounts/$ACCOUNT_ID/rum/site_info/list"      web_analytics.json        "web analytics sites"
  probe "accounts/$ACCOUNT_ID/challenges/widgets"      turnstile.json            "turnstile widgets"
  probe "accounts/$ACCOUNT_ID/access/apps"             access_apps.json          "access applications"
else
  echo "  SKIP  pages + account features - no account id in zone.json" >&2
  FAILED=1
fi

# ---------------------------------------------------------------- summary
# Facts are generated here so they cannot drift; the reasoning behind them
# stays hand-written in docs/cloudflare-config.md.
if [[ -f "$OUT/dns.json" ]]; then
  {
    echo "# Cloudflare export"
    echo
    echo "Generated by \`export-cloudflare.sh\`. **Do not hand-edit** - rerun the script."
    echo "Narrative and rationale live in [cloudflare-config.md](../cloudflare-config.md)."
    echo
    echo "Exported: $(date -u +%Y-%m-%d)"
    echo
    echo "## DNS records"
    echo
    echo "| Type | Name | Content | Proxied | TTL |"
    echo "|------|------|---------|---------|-----|"
    jq -r '.result | sort_by(.type, .name)[] |
      "| \(.type) | `\(.name)` | `\(.content)` | \(if .proxied then "**Yes**" else "No" end) | \(if .ttl == 1 then "Auto" else (.ttl|tostring) end) |"' \
      "$OUT/dns.json"
    echo

    if [[ -f "$OUT/pages_project.json" ]]; then
      echo "## Pages custom domains"
      echo
      jq -r '.result[0].domains[]? | "- `\(.)`"' "$OUT/pages_project.json"
      echo
      echo "## Pages project"
      echo
      jq -r '.result[0] | "- Project: `\(.name)`\n- Subdomain: `\(.subdomain)`\n- Production branch: `\(.production_branch)`"' "$OUT/pages_project.json"
      echo
      echo "Environment variable names (values in 1Password / \`.env.local.example\`):"
      echo
      jq -r '.result[0].deployment_configs | to_entries[] | "- **\(.key)**: " + ((.value.env_var_names // []) | map("`"+.+"`") | join(", "))' "$OUT/pages_project.json"
      echo
    fi

    if [[ -f "$OUT/email_routing.json" ]]; then
      echo "## Email routing"
      echo
      jq -r '.result | "- enabled: `\(.enabled)`  status: `\(.status // "?")`  name: `\(.name // "?")`"' "$OUT/email_routing.json"
      if [[ -f "$OUT/email_routing_rules.json" ]]; then
        jq -r '.result[]? | "- rule: `\(.name // .tag)` -> " + ((.actions // []) | map((.value // [])|join(",")) | join("; ")) + " (enabled: `\(.enabled)`)"' "$OUT/email_routing_rules.json"
      fi
      echo
    fi

    if [[ -n "$DISCOVERED" ]]; then
      echo "## Other features found"
      echo
      printf '%b' "$DISCOVERED" | sed 's/^/- /' 
      echo
      echo "Raw responses are alongside this file. Anything listed here is in use"
      echo "and must be recreated when rebuilding."
      echo
    fi

    if [[ -f "$OUT/ruleset_http_request_dynamic_redirect.json" ]]; then
      echo "## Redirect rules"
      echo
      jq -r '.result.rules[]? |
        "- **\(.description // "(unnamed)")** — `\(.expression)`\n  - action: `\(.action)`, status: `\(.action_parameters.from_value.status_code // "?")`, preserve query: `\(.action_parameters.from_value.preserve_query_string // false)`\n  - target: `\(.action_parameters.from_value.target_url.expression // .action_parameters.from_value.target_url.value // "?")`\n  - enabled: `\(.enabled)`"' \
        "$OUT/ruleset_http_request_dynamic_redirect.json"
      echo
    fi

    if [[ -f "$OUT/settings.json" ]]; then
      echo "## Zone settings (non-default / notable)"
      echo
      echo "| Setting | Value |"
      echo "|---------|-------|"
      jq -r '.result[] | select(.id | IN("always_use_https","ssl","min_tls_version","email_obfuscation","brotli","http2","browser_cache_ttl","rocket_loader","fonts","automatic_https_rewrites","security_level")) |
        "| `\(.id)` | `\(.value|tostring)` |"' "$OUT/settings.json" | sort
      echo
    fi
  } > "$OUT/SUMMARY.md"
  echo "  ok    SUMMARY.md"
fi

# ---------------------------------------------------------------- leak check
echo
echo "== secret check"
LEAKS=$(grep -rlEi 'avaros|@ontariomenopauseclinic\.ca|Bearer ' "$OUT" 2>/dev/null || true)
if [[ -n "$LEAKS" ]]; then
  echo "  REFUSING TO LEAVE THESE IN PLACE - secret-looking content found:" >&2
  echo "$LEAKS" | sed 's/^/    /' >&2
  echo "  Inspect before committing." >&2
  FAILED=1
else
  echo "  clean - no booking URL, contact address, or token in the export"
fi

echo
echo "Wrote $OUT"
ls -1 "$OUT" | sed 's/^/  /'
echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "Completed WITH ERRORS - the export is incomplete, do not treat it as a full backup." >&2
  exit 1
fi
echo "Review with: git diff --stat docs/cloudflare-export/"
