# cloudflare-token.sh - sourced, not run. Sets CLOUDFLARE_API_TOKEN for
# export-cloudflare.sh and cloudflare-build-log.sh, from the first of:
#   1. CLOUDFLARE_API_TOKEN already in the environment;
#   2. 1Password, via the `op` CLI (brew install 1password-cli, then enable
#      Settings -> Developer -> Integrate with 1Password CLI in the desktop app);
#   3. a hidden prompt, when stdin is a terminal.
# Never pass the token inline on the command line: it lands in shell history.
#
# The token is the READ-ONLY one described in export-cloudflare.sh's header.

# TEMPORARY(until: 2027-01-31, issue: #182): `op` can read the whole 1Password
# account, not just this item - least-privilege violation; #182 replaces it.
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]] && command -v op >/dev/null; then
  CLOUDFLARE_API_TOKEN="$(op read 'op://violet/Cloudflare Read All Token/credential')" || {
    echo "ERROR: op read failed - is the 1Password CLI integration enabled?" >&2
    exit 1
  }
fi
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  if [[ -t 0 ]]; then
    printf 'Cloudflare API token (read-only; input hidden): ' >&2
    read -rs CLOUDFLARE_API_TOKEN
    printf '\n' >&2
  else
    echo "ERROR: CLOUDFLARE_API_TOKEN is not set, op is not installed, and stdin is not a terminal." >&2
    exit 1
  fi
fi
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "ERROR: no token supplied." >&2
  exit 1
fi
