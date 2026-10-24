# Deploying to Staging

Puts the current branch on a staging site, to check a change before it is
released.

There are two kinds of staging slot, and they verify different things:

| Slot | URL | Use for |
|---|---|---|
| Default (`staging`) | `https://staging.ontariomenopauseclinic.ca/` | Anything that will be released. It is served **in-zone**, so it gets the zone's Cloudflare settings (redirect rules, cache rules) and behaves like production. |
| Numbered (`staging<slug>`) | `https://staging<slug>.violet-6qt.pages.dev/` | Comparing UX concepts side by side. These are outside the zone, so zone-level behaviour does **not** apply and cannot be verified there. |

Why the default slot is in-zone:
[Cloudflare configuration](../current-state/cloudflare-config.md).

## Pre-checks

1. **Everything you want to deploy is committed.** The script pushes `HEAD`
   and refuses to run with uncommitted changes.
2. **You know which slot.** Each push replaces whatever that slot was showing,
   so check nobody else is using it for a comparison.

## Steps

1. Preview what will be pushed:

   ```sh
   ./deploy-staging.sh [slug] --dry-run
   ```

2. Deploy. No slug means the default slot:

   ```sh
   ./deploy-staging.sh [slug]
   ```

   This force-pushes the current branch to `staging[slug]`, and Cloudflare
   Pages rebuilds that slot.

## Post-checks

1. **The build finished.** `./cloudflare-build-log.sh staging[slug]` waits for
   it and prints the log.
2. **The slot serves your commit.** Every page carries a build identifier with
   the commit SHA:

   ```sh
   curl -s https://staging.ontariomenopauseclinic.ca/ | grep -o '<meta name="build"[^>]*>'
   ```

3. **The staging banner shows**, and the page is `noindex`. Those are the only
   permitted differences from production
   ("Staging mirrors production" in [CLAUDE.md](../../CLAUDE.md#principles)).
