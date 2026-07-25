# Runbook

## Cutting a new release

Publishing to production happens by pushing a version tag, produced by three
GitHub Actions run in sequence. All are in `.github/workflows/`.

1. **Draft Changelog** (`draft-changelog.yml`) — run manually from the Actions
   tab. Computes the next version (`vYYYY.MM.DD[.N]`), diffs `main` against the
   last `v*` tag, builds a change list (preferring merged PR titles), prepends
   an entry to `CHANGELOG.md`, and opens a PR from a `changelog/<version>-r<run>`
   branch into `main`. Review/edit the entry for anything the commit list
   didn't capture, then merge the PR.

2. **Cut Release** (`cut-release.yml`) — run manually, after step 1's PR is
   merged to `main`. Reads the top `## v...` entry from `CHANGELOG.md` on
   `main` and opens a PR from `main` into `release` titled "Release vX.X.X",
   with the changelog entry as the PR body. `release` is protected, so this
   needs review/approval before merging.

3. **Tag Release** (`tag-release.yml`) — fires automatically on push to
   `release` once step 2's PR is merged. Reads the version from `CHANGELOG.md`
   on `release` and creates/pushes the `vX.X.X` tag. Cloudflare Pages deploys
   production from the `release` branch, so this is the point the new version
   goes live.

Sequence: **Draft Changelog → merge to main → Cut Release → merge to release
→ tag pushed automatically → production deploys.**

## Toggle maintenance mode (no deploy required)

Use this to take the production site down (incident, planned downtime) or bring it
back up. `maintenanceMode` is a Hugo param (`site/hugo.toml`) baked in at build
time, defaulting to `true` in `site/config/production/hugo.toml` — but it can be
overridden per-build via the `HUGO_PARAMS_MAINTENANCEMODE` env var, which lets you
flip it without going through a PR to the protected `release` branch.

When on, every route on the production site shows a fixed "We're almost ready"
placeholder instead of real content, the page is marked `noindex` (meta tag,
`robots.txt`, and `llms.txt` all block/omit indexing), and `nav`/`footer` are
hidden. Page titles/descriptions are left unchanged so any social link
previews cached during the outage stay accurate once the real site is back.

Note: `noindex`/`Disallow` are "stop indexing this" signals, not "temporarily
down, come back later" signals — fine for short outages, but see
[#77](https://github.com/timgladwell/violet/issues/77) for the proper fix
(HTTP 503 at the Cloudflare edge) if an outage runs longer than a day or two.

**To flip it:**

1. Cloudflare dashboard → Pages → `violet` project → Settings → Environment variables → **Production** scope.
2. Set `HUGO_PARAMS_MAINTENANCEMODE` to `true` (down) or `false` (up).
3. Deployments tab → find the latest production deployment → **Retry deployment**. This reruns the build with the new env var — no git push, no PR.
4. Once the new deployment is live, **purge the Cloudflare cache** (Caching → Configuration → Purge Everything). The zone's `browser_cache_ttl` is 4 hours (see `docs/cloudflare-config.md`), so without a purge visitors can keep seeing the old state for up to 4 hours.

Local/CI/staging builds always run with `maintenanceMode = false` regardless of
this env var (see `site/config/development/hugo.toml`, `site/config/staging/hugo.toml`)
— the env var only affects the Cloudflare Pages production build.
