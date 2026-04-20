# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Technical processes

* Always work in a feature branch or a worktree - do not work directly in the `main` branch

## Building

* Always confirm that changes to the site build correctly by running `hugo --source <directory with hugo site>`. In this repo, the Hugo site is located under the `site` folder

## Starting the localdev server

* Ensure the localdev server is running when working on anything by using the ./localdev.sh script

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
* Use `./deploy-staging.sh staging<slug>` to push all commits on the local branch to the named local, then remote, staging branch. Use the `slug` value provided by the user.
* Staging site is published at `https://staging<slug>.violet-6qt.pages.dev/`

### Starting the localdev server

* Ensure the localdev server is running when working on anything by using the ./localdev.sh script
* If Claude has started the localdev server, on exit Claude must make sure the localdev server has been stopped

### Validating a11y requirements

* Validate a11y requirements by running `npm run a11y`. Consume the output and automatically suggest fixes.
* This requires that the localdev server is running first

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
site/                                             # Hugo-based website
```

