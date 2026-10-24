# Cutting a Release

Moves production to a commit already on `main`, by fast-forwarding `release`
and tagging it. Why releases work this way:
[ADR 0001](../adr/0001-releasing-to-production.md). The rulesets that enforce
it: [GitHub configuration](../current-state/github-config.md).

## Pre-checks

1. **The commit has been verified on staging**
   ([Deploying to Staging](deploying-to-staging.md), default slot). Cut
   Release asks you to confirm this and refuses without it.

2. **Hugo version.** If `git diff release <target> -- .tool-versions` shows a
   Hugo change, set the Cloudflare Pages **Production** `HUGO_VERSION` to the
   same bare `X.Y.Z` now, just before Cut Release (Preview was bumped when the
   change merged). The two must match or the production build fails; see the
   header of `.tool-versions`. Rerun `./export-cloudflare.sh` and commit the
   diff. Cut Release refuses a Hugo change unless its
   `hugo_version_set_in_production` input is `yes`.

## Steps

1. **Draft Changelog** (`draft-changelog.yml`): run it from the Actions tab.
   It computes the next version (`vYYYY.MM.DD[.N]`), diffs `main` against the
   last `v*` tag, builds a change list (preferring merged PR titles), prepends
   an entry to `CHANGELOG.md`, and opens a PR from a
   `changelog/<version>-r<run>` branch into `main`. Edit the entry for anything
   the PR titles didn't capture, then merge the PR.

2. **Cut Release** (`cut-release.yml`): run it from the Actions tab and set
   `verified_on_staging`. It reads `CHANGELOG.md` from the target commit
   (`main` HEAD by default; pass `ref` to promote an earlier `main` commit if a
   longer-running feature is mid-flight on `main`), then fast-forwards `release`
   to that exact commit, tags it, and publishes a GitHub Release with the
   changelog entry as its notes.

   It refuses to run unless `verified_on_staging` is confirmed, the commit is on
   `main`, `release` is an ancestor of it, and the version's tag doesn't already
   exist.

## Post-checks

1. **Production serves the promoted commit.** Every page carries a build
   identifier; once Cloudflare's build finishes, its version and SHA match the
   release:

   ```sh
   curl -s https://ontariomenopauseclinic.ca/ | grep -o '<meta name="build"[^>]*>'
   ```

2. **The tag and GitHub Release exist** for the version:

   ```sh
   gh release view <version>
   ```

### If production looks broken right after a release

Check Cloudflare cache propagation before rolling back — `browser_cache_ttl`
is 4 hours (see [`cloudflare-config.md`](../current-state/cloudflare-config.md)), so a stale
asset can look like a real regression for a while after a deploy that's
actually fine. Purge the cache (Caching → Configuration → Purge Everything) and
reload before assuming the release itself is broken.

## If Cut Release reports "not a fast-forward"

Something wrote to `release` outside the workflow. **Do not force anything
yet.** Find out whether the extra commits are real:

```sh
git fetch origin
git cherry origin/main origin/release
```

- **Every line starting `-`**: every commit unique to `release` is already in
  `main` under a different SHA, so nothing would be lost by resetting.
- **Any line starting `+`**: that commit exists only on `release` and must be
  brought into `main` through a PR first.

Confirm with `git diff --stat origin/release origin/main`, which should show
only what you are about to promote.

### Resetting `release` to `main`

`non_fast_forward` has to come off for exactly one push, then go straight back
on. `main`'s 17 early unsigned commits are also why a reset is rejected while
enforcement is on ([#196](https://github.com/timgladwell/violet/issues/196)).
The rulesets themselves are described in
[GitHub configuration](../current-state/github-config.md).

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
```

**Post-check — required.** Leaving enforcement disabled silently removes all
protection from `release`, and nothing will remind you:

```sh
gh api "repos/timgladwell/violet/rulesets/$RS" --jq .enforcement   # must say "active"
```

Then `./export-github.sh` must leave `docs/current-state/github-export/`
unchanged: any diff means a ruleset did not come back exactly as it was.
