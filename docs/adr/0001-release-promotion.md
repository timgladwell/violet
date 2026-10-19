# 0001 — Promoting `main` to production

- **Status:** Accepted
- **Date:** 2026-08-23
- **Deciders:** Tim and Claude

## Changelog

| Date | By | Description |
| --- | --- | --- |
| 2026-08-23 | Tim and Claude | Fast-forward `release` from a workflow instead of merging a release PR (#133) |
| 2026-08-24 | Tim and Claude | Tagging and the GitHub Release folded into the same workflow (#145, #146) |
| 2026-10-18 | Tim and Claude | Recorded as an ADR, moved from `docs/runbook.md` |

## Context

Cloudflare Pages deploys production from the `release` branch. Whatever moves
`release` decides what reaches visitors, so it has to:

- promote only commits already reviewed, signed and verified on staging;
- never conflict, so a release is never blocked by merge mechanics;
- leave a revert path: a tag and a GitHub Release per promotion.

`main` requires a PR (merge commits only) and signed commits.

## Decision

`release` is not a branch anything merges into. It is a pointer that only ever
moves forward to a commit already on `main`. The **Cut Release** workflow
(`cut-release.yml`) fast-forwards it to an exact `main` commit, then tags that
commit and publishes a GitHub Release from its `CHANGELOG.md` entry. The
procedure is [Cutting a Release](../runbooks/cutting-a-release.md).

Branch rulesets this depends on:

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

Tagging is part of Cut Release, not a separate workflow triggered by the push to
`release`. GitHub does not trigger workflows from pushes made with the default
`GITHUB_TOKEN`, so a tag-on-push workflow silently never fires — the promotion
succeeds, production updates, the run goes green, and only the tag and GitHub
Release are missing. That is the revert path, so its absence would be invisible
until it was needed (#145).

## Consequences

- Fast-forwarding preserves the SHA and the signature, so `release` is always
  literally an ancestor of `main` and a promotion can never conflict.
- The paperwork is the tag, the GitHub Release and the workflow run, which
  records who dispatched it, when and against which ref. That is stronger
  evidence than a PR approved by its own author.
- Every branch to be merged must be re-signed first (`git rebase -f -S main`).
- `main` carries 17 unsigned commits from the project's earliest history.
  `required_signatures` evaluates commits new *to the ref*, so resetting
  `release` to `main` re-introduces them and needs the ruleset briefly disabled.
  The runbook covers this; ordinary promotions only introduce new, signed
  commits.

## Alternatives considered

- **A release PR, merged with a merge commit.** GitHub's merge button has no
  fast-forward strategy; all three options mint new commits. A merge commit
  lives only on `release`, so the merge base for the next cut stays pinned where
  the last one started, and conflicts accumulate (PRs #111/#112).
- **A release PR, rebase-and-merge.** Replayed `main`'s commits under fresh SHAs
  and dropped their signatures, so `release` diverged on every cut and every
  commit on it read `verified=false`.
- **A tag-on-push workflow.** Never fires, for the `GITHUB_TOKEN` reason above.
