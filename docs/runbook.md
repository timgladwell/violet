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
   merged to `main`, and after you've verified the change on staging via
   `./deploy-staging.sh`. Reads `CHANGELOG.md` from the target commit (`main`
   HEAD by default; pass the `ref` input to promote an earlier `main` commit
   if a longer-running feature is mid-flight on `main`), pushes it to a
   `release-candidate/<version>` branch, and opens a PR from that branch into
   `release`. Before doing any of that it checks `release` is an ancestor of
   the target commit — if it isn't, it fails with an error instead of opening
   a PR that would hit conflicts (see "Why release must stay rebase-clean"
   below). Merge the PR — the `release` branch rule only permits the
   **Rebase and merge** strategy, so this always fast-forwards `release`
   rather than creating a merge commit.

3. **Tag Release** (`tag-release.yml`) — fires automatically on push to
   `release`. Reads the version from `CHANGELOG.md` on `release`, creates and
   pushes the `vX.X.X` tag, and publishes a GitHub Release with the changelog
   entry as its notes. Merging step 2's PR is the point the new version goes
   live (Cloudflare Pages deploys production from `release`) — this step
   just records it.

Sequence: **Draft Changelog → merge to main → verify on staging → Cut Release
→ merge the release PR (rebase-merge only) → tag + GitHub Release created
automatically → production deploys.**

### Why release must stay rebase-clean

Earlier versions of this workflow merged the release PR with a regular merge
commit. Every such merge creates a commit that lives only on `release` — so
on the *next* cut, `release` and `main` have structurally diverged even
though their content matches, and the merge-base for that next promotion
stays pinned at wherever the previous cut started. Combined with a long gap
between cuts, that produced a real pile of conflicts once (see PR #111/#112).

The fix: `release`'s branch rule now only allows **Rebase and merge**, and
nothing is ever committed to `release` outside that one PR. As long as
`release`'s tip is always an ancestor of whatever's being promoted, a
rebase-merge has nothing to replay — it's a fast-forward, not a real rebase,
so there's nothing to conflict. `cut-release.yml`'s ancestor check exists to
catch the one way this can still go wrong: if `release` ever drifts (e.g.
someone merges a stray PR into it directly), the workflow refuses to open a
PR that can't rebase cleanly, rather than letting you discover the conflicts
by hand. If that check fails, reset `release` to a known-good point on `main`
(`git push origin <main-sha>:release --force`) before re-running Cut Release.
Cutting releases often keeps that check trivially true and keeps each PR's
diff small enough to sanity-check on staging.

### If prod looks broken right after a release

Check Cloudflare cache propagation before rolling back — `browser_cache_ttl`
is 4 hours (see `docs/cloudflare-config.md`), so a stale asset can look like
a real regression for a while after a deploy that's actually fine. Purge the
cache (Caching → Configuration → Purge Everything) and reload before
assuming the release itself is broken.

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
