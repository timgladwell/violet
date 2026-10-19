# Runbook

## Cutting a new release

Publishing to production happens through two GitHub Actions run in sequence.
Both are in `.github/workflows/`.

1. **Draft Changelog** (`draft-changelog.yml`) — run manually from the Actions
   tab. Computes the next version (`vYYYY.MM.DD[.N]`), diffs `main` against the
   last `v*` tag, builds a change list (preferring merged PR titles), prepends
   an entry to `CHANGELOG.md`, and opens a PR from a `changelog/<version>-r<run>`
   branch into `main`. Review/edit the entry for anything the commit list
   didn't capture, then merge the PR.

   **Pre-check — Hugo version.** If `git diff release <target> -- .tool-versions`
   shows a Hugo change, set the Cloudflare Pages **Production** `HUGO_VERSION`
   to the same bare `X.Y.Z` now, just before step 2 (Preview was bumped when
   the change merged). The two must match or the production build fails; see
   the header of `.tool-versions`. Rerun `./export-cloudflare.sh` and commit
   the diff. Cut Release refuses a Hugo change unless its
   `hugo_version_set_in_production` input is `yes`.

2. **Cut Release** (`cut-release.yml`) — run manually, after step 1's PR is
   merged to `main`, and after you've verified the change on staging via
   `./deploy-staging.sh`. Reads `CHANGELOG.md` from the target commit (`main`
   HEAD by default; pass the `ref` input to promote an earlier `main` commit
   if a longer-running feature is mid-flight on `main`), then **fast-forwards
   `release` to that exact commit**, tags it, and publishes a GitHub Release
   with the changelog entry as its notes. It refuses to run unless you confirm
   the `verified_on_staging` input, the commit is on `main`, `release` is an
   ancestor of it, and the version's tag doesn't already exist. There is no
   release PR and no `release-candidate` branch — see below.

Sequence: **Draft Changelog → merge to main → verify on staging → Cut Release
→ production deploys, tagged, with a GitHub Release.**

Tagging is part of Cut Release rather than a separate workflow triggered by the
push to `release`. GitHub does not trigger workflows from pushes made with the
default `GITHUB_TOKEN`, so a tag-on-push workflow silently never fires — the
promotion succeeds, production updates, the run goes green, and only the tag and
GitHub Release are missing. That is the revert path, so its absence is invisible
until it is needed ([#145](https://github.com/timgladwell/violet/issues/145)).

### Why `release` is fast-forwarded, not merged

`release` is not a branch anything merges into. It is a pointer that only ever
moves forward to a commit already on `main` — reviewed, signed, and verified on
staging before it moves.

It used to be promoted by PR, for the paperwork. That cannot work, because
**GitHub's merge button has no fast-forward strategy**: all three of its
options mint new commits. Merge commits leave a commit that lives only on
`release`, so the merge base for the next cut stays pinned where the last one
started, and conflicts accumulate (PR #111/#112). Switching to rebase-and-merge
traded that for something worse — it replayed `main`'s commits under fresh
SHAs *and dropped their signatures*, so `release` diverged on every single cut
and every commit on it read `verified=false`.

Fast-forwarding preserves the SHA and the signature, so `release` is always
literally an ancestor of `main` and a promotion can never conflict. The
paperwork moved to the tag, the GitHub Release, and the workflow run — which
records who dispatched it, when, and against which ref. That is stronger
evidence than a PR you approved yourself.

**Branch rulesets this depends on:**

| Branch | Rules |
|---|---|
| `main` | `pull_request` (merge commits only, 0 approvals) · `required_signatures` · `deletion` · `non_fast_forward` |
| `release` | `required_signatures` · `deletion` · `non_fast_forward` |

Neither has a bypass actor, and neither can: app bypass actors require an
organization and this is a user-owned repo. That is the better outcome —
`non_fast_forward` with no bypass means *nobody*, owner included, can rewrite
either branch. `release` deliberately has **no `pull_request` rule**; it would
block the workflow's push, and there is nothing to review there that wasn't
already reviewed on `main`.

Because `main` requires signed commits, re-sign a branch before merging its PR
or the merge is blocked:

```sh
git rebase -f -S main
```

### If Cut Release reports "not a fast-forward"

Something wrote to `release` outside the workflow. Do not force anything first
— find out whether the extra commits are real:

```sh
git fetch origin
git cherry origin/main origin/release
```

A `-` prefix on every line means every commit unique to `release` is already in
`main` under a different SHA, so nothing would be lost by resetting. A `+` means
that commit is genuinely unique and must be brought into `main` first. Confirm
with `git diff --stat origin/release origin/main`, which should show only what
you are about to promote.

To reset, `non_fast_forward` has to come off for exactly one push, then go
straight back on:

```sh
RS=$(gh api repos/timgladwell/violet/rulesets --jq '.[] | select(.name|test("release")) | .id')
set_enforcement() {
  gh api "repos/timgladwell/violet/rulesets/$RS" \
    | jq --arg e "$1" '{name, target, enforcement: $e, conditions, rules, bypass_actors}' \
    | gh api --method PUT "repos/timgladwell/violet/rulesets/$RS" --input -
}
set_enforcement disabled
git push --force origin origin/main:refs/heads/release
set_enforcement active
gh api "repos/timgladwell/violet/rulesets/$RS" --jq .enforcement   # must say "active"
```

Confirm enforcement came back on. Leaving it disabled silently removes all
protection from `release` and nothing will remind you.

Note that `main` carries 17 unsigned commits from the project's earliest
history. `required_signatures` evaluates commits that are new *to the ref*, so
a reset like the one above re-introduces them to `release` and is rejected
while enforcement is on — which is why the toggle exists. Ordinary
fast-forward promotions only ever introduce new, signed commits.

### If prod looks broken right after a release

Check Cloudflare cache propagation before rolling back — `browser_cache_ttl`
is 4 hours (see `docs/cloudflare-config.md`), so a stale asset can look like
a real regression for a while after a deploy that's actually fine. Purge the
cache (Caching → Configuration → Purge Everything) and reload before
assuming the release itself is broken.

## When the Avaros booking page changes size

The booking form on `/book/` (and in the desktop modal) is an iframe of
Avaros's booking page, whose content is edited in Avaros, not here. If that
page grows — longer welcome text, a bigger logo — its "Book an appointment"
button can drop below or past the frame's edge, where phone visitors won't
find it
([#165](https://github.com/timgladwell/violet/issues/165)).

The **Booking Check** workflow (`booking-check.yml`) re-measures the real page
every morning into `a11y/fixtures/avaros-landing.json`, which
`a11y/booking.spec.ts` uses as a stand-in for the iframe on every test run. On
any change it opens, or updates, an **"Avaros booking page changed size"** PR:

- **✅ still fits** — review the numbers and merge; nothing else to do.
- **❌ no longer fits** — the run also fails, which emails you. On the PR's
  branch, adjust the frame in `site/assets/css/main.css` until the booking
  tests pass: its height (`.book-page__frame`, or `.modal--booking
  .modal__panel` for the modal) if the button fell below the bottom edge, or
  the edge-to-edge breakpoint below it if Avaros's minimum width grew and the
  button overhangs the right edge. Then merge and cut a release; production
  shows the hidden button until then.

The job finds the booking URL on production's `/book/`, falling back to
staging; it fails with an error if both are in maintenance mode. To measure by
hand: `npm run avaros:measure -- <booking URL>`.

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

Every other build defaults to `maintenanceMode = false` (`site/hugo.toml`;
`site/config/development/hugo.toml` also sets it explicitly), but the env var
overrides config in **every** environment it is set for, development included.
Local and CI builds stay off only because nothing sets it there. Setting it in
Cloudflare's **Preview** scope puts staging deployments into maintenance mode
too — handy for checking the placeholder on staging, but remove it and
redeploy afterwards: while it is set, staging can't be used to verify a release.
