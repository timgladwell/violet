# 0001 — How code is released to production

- **Status:** Accepted
- **Date:** 2026-08-23
- **Deciders:** Tim and Claude

## Changelog

| Date | By | Description |
| --- | --- | --- |
| 2026-08-23 | Tim and Claude | Fast-forward `release` from a workflow instead of merging a release PR (#133) |
| 2026-08-24 | Tim and Claude | Tagging and the GitHub Release folded into the same workflow (#145, #146) |
| 2026-10-18 | Tim and Claude | Recorded as an ADR, moved from `docs/runbook.md` |
| 2026-10-22 | Tim and Claude | Rescoped from promoting `main` to releasing code: trunk-based development with a human release gate; implementation detail moved to code and current-state docs |

## Context

The site is the top of a medical practice's customer funnel, built and
reviewed by one developer, often with Claude. Production has to change only
when someone has decided it should, and has to be recoverable when a change
turns out wrong.

Requirements:

- **Every change to `main` goes through a PR.** With one developer, the PR is
  what separates the developer's hat from the reviewer's. It is also where the
  *why* of a change is recorded for future readers; commit messages do not
  carry enough.
- **Releasing to production is a human decision.** Nothing reaches visitors
  because a merge happened to land.
- **A change is verified on staging before it is released.** CI catches what
  can be automated; staging is checked by hand, with or without Claude, for
  what cannot.
- **Every release has a safe revert path.**
- **Nothing but the release gate changes what production serves.**
- **GitHub enforces the process** — rulesets and workflows — rather than local
  scripts or remembered manual steps.

Cloudflare Pages deploys whichever branch is configured as its production
branch. Here that branch is named `release`.

## Decision

**Trunk-based development with a defined release gate.** Work lands on `main`
in short-lived branches through PRs. Production is the `release` branch, and
the only thing that moves it is the release gate: a workflow a person
dispatches, which advances `release` to a commit already on `main`.

- **`release` only ever moves forward, to a commit already on `main`.** It is
  never merged into, so it is always an ancestor of `main`, and a release can
  never conflict or introduce code that `main` does not have.
- **CI runs on every PR, and again on what is released.** CI is not the only
  check: the commit is deployed to staging and validated there first.
- **A person dispatches every release**, after confirming it was verified on
  staging.
- **Every release is identifiable and revertible**: a version, its changelog
  entry, and a record of what was released, by whom and when, so production
  can be returned to any earlier release.
- **Branch protection is as strong as the platform allows**: neither `main`
  nor `release` can be rewritten or deleted by anyone, owner included, and
  every commit on them is signed.

## Consequences

### Positive

- A release is a pointer move, not a merge, so releasing has no merge
  mechanics to go wrong.
- `main` and `release` cannot diverge, so the next release is always a plain
  step forward from the last.
- The release record (version, changelog, who and when) is produced by the
  gate itself rather than kept by hand.

### Negative / risks

- Production lags `main` until someone releases, so a merged fix is not live
  until a human acts.
- Reverting is a release of an earlier commit, not an automatic rollback.

## Alternatives considered

- **Continuous deployment from `main`.** Every merge goes to production.
  Rejected: releasing must be a human decision, and staging verification has
  to happen before release, not after.
- **Long-running feature branches** merged to `main` in one large change and
  released together. Rejected: large merges conflict, are hard to review, and
  make each release riskier and harder to revert.
- **Promoting by PR into `release`.** Gives a review screen for every release,
  but GitHub's merge button has no fast-forward option: every strategy mints
  new commits, so `release` diverges from `main`, and rebase-and-merge also
  drops signatures (PRs #111/#112). The review a release PR would add has
  already happened on `main`.
