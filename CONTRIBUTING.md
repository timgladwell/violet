# Contributing

Where each kind of information lives, and why. This applies to people and to
Claude Code alike; `CLAUDE.md` imports this file so it is loaded every session.

<!-- TEMPORARY(until: 2026-12-31, issue: https://github.com/timgladwell/homelab/issues/425):
adapted from homelab's CONTRIBUTING.md, where this taxonomy is trialled before
being promoted to the global CLAUDE.md in the dotfiles repo. Where it disagrees
with the global file, this file wins. Retire by promoting it, then replacing
this file with whatever per-repo deltas remain. -->

## The rule

**Everything in source control describes current state.** History, plans,
findings and anything that *should* change live in issues. A file may point at
an issue; it never holds the work itself.

Two exceptions:

- Something known to be temporary (a workaround, a runbook for a long-running
  investigation) stays, but carries a [`TEMPORARY` tag](#temporary-things)
  saying why and until when.
- `docs/decision_log.md` and the early research and content-drafting notes in
  `docs/` predate this convention. They are kept as a historical record and are
  not updated; decisions now live in issues and [ADRs](#adrs).

## Where things live

| Kind | Holds | Never holds |
|---|---|---|
| [Code comment](#code-comments) | Why this code is the way it is, and how to change it without breaking something | History, plans |
| [`CLAUDE.md`](#claudemd) | Repo-wide rules, the development scripts, and an index of change-triggered runbooks | Anything a lower-level home can carry |
| [Current-state docs](#current-state-docs) | The Cloudflare configuration: state that code does not define | Procedures, plans, history |
| [Requirements docs](#requirements-docs) | What the site and business need, and the principles behind it | Procedures, plans, history |
| [`docs/adr/`](#adrs) | The current answer to one design question | Concrete specifications, procedures |
| [`docs/runbooks/`](#runbooks) | A procedure for a specific outcome | One-off history, past-run logs |
| [Issues](#issues) | Plans, tasks, findings, decisions, history | — |
| [Pull requests](#pull-requests) | Why this change is built this way | Analysis results, discovered work |
| Claude's memory | How the user prefers to work | Any technical fact |

Across all of them: describe what is true now, do not restate what `git log`
and `git blame` already answer, and never add a "TODO", "Next steps" or
"Action items" section — those are issues.

### Where a warning goes

A "don't change this without…" warning goes on the **narrowest thing that
exists**, because that is where it is read at the moment it matters:

1. **The line or block** it protects — a code comment.
2. **The file** — a header comment, e.g. at the top of a template or workflow.
3. **A runbook's pre-checks**, when the warning is about a *kind of change*
   rather than any existing line. `CLAUDE.md` indexes it in one line.
4. **A current-state doc**, for state that lives outside the code (Cloudflare).

`CLAUDE.md` holds the warning itself only when it is genuinely repo-wide.

## Code comments

A comment says why the code is the way it is and what else has to change with
it: "keep in sync with the service list in `services.html`; see #123". The
reasoning and history live in the linked issue; the comment carries only what
the next editor needs.

Comment length scales with the level of the code. A line gets one to a few
lines; a template or workflow header may carry dozens.

## `CLAUDE.md`

Loaded into every session, so every line costs tokens on every task. It holds
only what applies repo-wide:

- rules and invariants (branching, signing, environment variables, staging
  parity);
- the development scripts;
- an index of change-triggered runbooks: "before cutting a release, follow
  [runbook]";
- `@CONTRIBUTING.md`.

Anything tied to specific code is a comment on that code instead.

## Current-state docs

Cloudflare holds configuration this repo cannot reproduce: the zone, DNS,
Pages settings and environment variables. `docs/cloudflare-config.md` says
**what** that state is, why, and how to change it without breaking something;
`docs/cloudflare-export/` is the raw export it is checked against
(`./export-cloudflare.sh`, rerun after any Cloudflare change). A procedure for
changing it is a runbook, and the two link to each other.

`cloudflare-config.md` keeps a change table (`| Date | Change |`), because
configuration held outside the repo drifts silently and the table is the only
record of when and why it moved.

## Requirements docs

`docs/project_overview.md` and `docs/website_design.md` describe what the
business and the site need, and the principles every change is held to. They
change when the requirements do, not when the code does.

## ADRs

One ADR per design question — "how is production promoted" — holding the
current answer, its context and the alternatives rejected. The answer is
expected to change; the ADR is revised in place and keeps its question, with
one changelog row per revision. Format and numbering are in
[`docs/adr/README.md`](docs/adr/README.md).

## Runbooks

A procedure for a specific outcome: **pre-checks** confirming scope and
starting state, **steps**, and **post-checks** confirming the outcome. Each is
one file under `docs/runbooks/`, listed in [`docs/runbooks.md`](docs/runbooks.md)
with its kind:

| Kind | For | Examples |
|---|---|---|
| Operational | Running the site day to day, and responding when something happens | Cutting a release, toggling maintenance mode |
| Maintenance | Keeping the site healthy | Upgrades, periodic audits |
| Provisioning | Creating or recreating something | A new environment, a new service |

A runbook may be temporary — written because a process will repeat a few times
during a long piece of work. It carries a `TEMPORARY` tag at the top.

**Retiring a runbook** deletes the file and moves its row to the *Retired*
table in `docs/runbooks.md`, with a one-line summary and a link to the last
commit that contained it, so it can still be found.

## Issues

Everything that should change, and the record of how it got that way: plans,
tasks, findings, decisions, deferred work, and premises that turned out to be
wrong. Issues are cheap to close and expensive to miss.

**An issue must let someone start work from an empty context** — a person new
to it, or an agent with nothing else loaded. Capture enough that the research
does not need redoing: the evidence, the premises that turned out to be wrong,
and the specific measurements, with when and how they were taken.

Items that need Andrea's input are labelled `needs-andrea`.

## Pull requests

The proposed change and nothing else: why it is built this way, the
alternatives rejected, and what a reviewer needs. When a finding drives the
change, the finding goes in an issue and the PR links it. Review replies answer
the review point.

## Temporary things

Anything introduced as temporary carries a machine-readable tag where it lives:

```sh
# TEMPORARY(until: 2026-12-01, issue: #123): <why it exists, what retires it>
```

In Markdown and HTML templates, the same inside `<!-- -->` (or `{{/* */}}` in
Hugo templates). Both fields are required. The issue owns the retirement work.
Extending the date is a commit that changes it, with the reason in the commit
message.
