# Recreating the Cloudflare Read-Only Token

Creates the read-only API token that `./export-cloudflare.sh`,
`./cloudflare-build-log.sh` and `./cloudflare-sweep.sh` use, when it has been
lost, revoked or needs rotating. The scripts get it through
`cloudflare-token.sh`: from the environment, then 1Password, then a hidden
prompt.

How to create a token is Cloudflare's to document:
[Create an API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/).
This runbook covers only the choices specific to this repo.

## Pre-checks

1. **You can log in to the Cloudflare account** that owns the
   `ontariomenopauseclinic.ca` zone and the `violet` Pages project.
2. **You know whether the old token still exists.** If it does, note it in
   **My Profile → API Tokens** so it can be revoked once the new one works.

## Steps

1. Create the token from the **Read all resources** template. It is broad, but
   read-only: the export reads zone, DNS, account, registrar and Pages
   settings, and `cloudflare-sweep.sh` GETs every endpoint Cloudflare
   publishes, so a narrower custom token silently drops parts of the export.
   Leave every permission at **Read**; nothing in this repo writes to
   Cloudflare.
2. Store it in 1Password as the `credential` field of the
   **Cloudflare Read All Token** item in the `violet` vault. That is the path
   `cloudflare-token.sh` reads; if the item or field is named differently,
   `op read` fails.
3. Revoke the old token, if there was one.

## Post-checks

1. **The export runs cleanly and finds no drift.** No `FAIL` lines, and the
   export directory is unchanged:

   ```sh
   ./export-cloudflare.sh
   git status --short docs/current-state/cloudflare-export/   # empty
   ```

   A `FAIL` on one endpoint usually means the token is missing a permission
   that endpoint needs; recreate it from the template rather than adding
   permissions one at a time.
2. **The build log is readable**, which exercises the account-scoped Pages
   permission:

   ```sh
   ./cloudflare-build-log.sh
   ```
