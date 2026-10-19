# Architecture decision records

An ADR records one design question about the site and its tooling: given these
requirements, this is the decision, and these are the alternatives rejected.
ADRs exist so that every change reaches for the same patterns, and so that a
decision is not re-litigated without its context.

They are not where current state is described (`docs/current-state/cloudflare-config.md`) or
requirements are set (`docs/website_design.md`), where a procedure
is written down (`docs/runbooks/`), or where work is queued (issues).
`docs/decision_log.md` is the frozen record of decisions made before ADRs and
issues were used.

## Format

One file per decision, `NNNN-short-title.md`, with:

- a header listing **Status** (`Proposed`, `Accepted` or `Deprecated`),
  **Date** and **Deciders**;
- **Changelog** — directly after the header, one row per change, newest last:

  ```markdown
  ## Changelog

  | Date | By | Description |
  | --- | --- | --- |
  | 2026-10-18 | Tim and Claude | Accepted (#123) |
  ```

  Keep descriptions to one line.
- **Context** — the requirements and constraints;
- **Decision**;
- **Consequences** — positive, and negative or risks;
- **Alternatives considered** — what was rejected, and why.

Refer to this repo's ADRs by relative link, and to another repo's by full URL
naming the repo, since each repo numbers its ADRs independently.

## Numbering and revision

Numbers are assigned in the order decisions are written down here, not the
order they were made. Many decisions were made before this convention existed,
so a low number does not mean an early or foundational decision.

Revising an ADR is expected, not a failure. If the chosen answer turns out to
be wrong, the ADR is revised in place with a changelog row: it is still the
same question. An ADR is `Deprecated` only when its question has gone out of
scope.
