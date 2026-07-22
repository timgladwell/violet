# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Technical processes

* Always work in a feature branch or a worktree - do not work directly in the `main` branch

## Development scripts

All local development is managed through these scripts. Do not construct raw `hugo` commands.

| Script | Purpose |
|--------|---------|
| `./dev-server.sh` | Build and start the Hugo dev server in a tmux session (`violet-localdev`). Attaches if already running. Requires tmux (`brew install tmux`). |
| `./validate.sh` | Full validation suite: build + environment checks + markdown lint + a11y. Starts the dev server automatically if needed, stops it when done. |
| `./check-environments.sh` | Builds development/staging/production (staging and production via `site/build.sh`, simulating Cloudflare's `CF_PAGES_BRANCH`) and asserts each produces the expected output. Catches a typo'd `--environment` value before it ships. Runs in CI on every PR (`.github/workflows/check-environments.yml`). |
| `./deploy-staging.sh <slug>` | Push current branch to a staging environment. |

* **Before pushing a PR**, run `./validate.sh` and fix any failures.
* **If you start the dev server** (`./dev-server.sh`), stop it before exiting by running `./dev-server.sh --stop`. This is ownership-safe: it only stops a session `dev-server.sh` itself started (tracked via `.dev-server.lock`), so it will never kill a server someone else already had running.
* **A11y only**: `npm run a11y` (requires dev server running first). One-time setup on a new machine: `npx playwright install chromium`.
* **Markdown lint only**: `npm run lint:md`.
* Hugo version is pinned in `.tool-versions` and used by CI; `dev-server.sh`/`validate.sh` warn (don't fail) if your local `hugo` doesn't match it.

## Environment variables

* All Hugo site parameters that must not be committed to the repo are managed as environment variables.
* `.env.local.example` (repo root) is the **canonical list** of all required environment variables, with safe placeholder values.
* `.env.local` (repo root, gitignored) holds the real values for local development.
* CI (GitHub Actions) loads `.env.local.example` directly — placeholder values are sufficient for builds and tests.
* Cloudflare Pages holds the real values as environment variables configured in the dashboard (Settings → Environment variables).
  * **Cloudflare Pages has separate env var scopes for Production and Preview (staging).** A variable added under one scope is not available to the other. Whenever a new env var is added to Cloudflare, it must be added under **both** scopes.
* **Whenever a new Hugo parameter is added to `hugo.toml` that is sourced from an env var, `.env.local.example` must be updated in the same PR, and the variable must be added to Cloudflare Pages under both Production and Preview scopes.** This keeps CI and all deployment environments in sync.

## Publishing

* Website is hosted by Cloudflare. Website publishing is performed by pushing code to specific git branches.

### Pushing to production
* Production publishing happens when code is merged from `main` to `release` branch. The process is assisted by Github actions:
  * All releases have a CHANGELOG. Generation of the changelog is assisted by a Github action.
  * All pushes to `release` branch are tagged for easy reverts. Creating and tagging the `release` branch update is assisted by a Github action.
  * `release` branch is protected and requires a pull request - no direct pushes are allowed.
* Production site is published at `https://www.ontariomenopauseclinic.ca`

### Pushing to staging

* Staging publishing happens when any code is pushed to a remote branch matching the `staging*` pattern.
* Use `./deploy-staging.sh <slug>` to push all commits on the local branch to the named local, then remote, staging branch (e.g. `./deploy-staging.sh 4` deploys to `staging4`). Use the `slug` value provided by the user.
* Staging site is published at `https://staging<slug>.violet-6qt.pages.dev/`

## Project Context and Guiding Principles.

See @docs/project_overview.md

## Website Requirements

See @docs/website_design.md

## Planning and Project Management

* Record all questions that need to be answered in @docs/decision_log.md
* Record all project tasks in @docs/project_tracking.md

## Repository Structure

```
assets/                                           # Original asset files for the website - Andrea's headshot, logo file, etc
docs/
  project_overview.md                             # Business context, scope, and technical principles.
  project_tracking.md                             # Project tasks with associated status and dependencies
  decision_log.md                                 # Tracks project questions as they become decisions
  website_design.md                               # Website requirements, content notes, reference sites
  investigation_notes.md                          # Research notes on technical decisions, process experiments, etc.
  competitive_analysis_and_recommendations.md     # Claude-authored analysis of similar websites
  website_content_draft.md                        # Claude-authored worksheet for gathering Andrea's notes on website content and structure
  "Website Content Draft.md"                      # Andrea's notes into the `website_content_draft.md` worksheet
  runbook.md                                       # Operational procedures (e.g. toggling maintenance mode)
site/                                             # Hugo-based website
```
