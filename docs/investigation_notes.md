# Email

- Microsoft's Hosted Exchange Plan 1 seems to be the best fit - cheap, high service level, expandable, and technology agnostic
- [https://www.microsoft.com/en-ca/microsoft-365/exchange/exchange-online](https://www.microsoft.com/en-ca/microsoft-365/exchange/exchange-online)

# Website Technology

## Design tool

For a solo developer building a simple marketing site, a dedicated design tool (Figma, Canva, etc.) adds a design-to-code export step with no clear benefit. Pre-built SSG themes handle layout, typography, and responsive design. Customization happens directly in code with immediate browser feedback.

- **Figma**: Free tier sufficient, good for stakeholder review, but plugin-based code export requires cleanup. Adds time without a collaborator who needs mockups.
- **Canva**: Easy to use but exports to Canva-hosted sites only — doesn't produce static HTML for a custom SSG.
- **AI tools (v0.dev, Relume, Framer)**: v0.dev generates clean React code but is React-specific. Relume ($32/mo) and Framer are hosted platforms, not static site pipelines.
- **Template-first (chosen)**: Skip the design tool entirely. Pick a polished SSG theme, customize colours/fonts/content in code. Zero cost, no export friction.

## Static site generator

Evaluated Hugo, Astro, Eleventy, Next.js, Jekyll, and plain HTML against project requirements: simple marketing site, low cost, low maintenance, YAGNI, senior backend dev with rusty JS skills.

| | Hugo | Astro | Eleventy | Next.js | Jekyll | Plain HTML |
|---|---|---|---|---|---|---|
| Marketing themes | Excellent (40+) | Very good, growing | Smaller | Moderate | Moderate | External |
| Learning curve | Go templates | JS components | Minimal | React (steep) | Ruby/Liquid | Easy but fragile |
| Build speed | <1s | Fast | Fast | Medium | Slow | N/A |
| Runtime dependency | Single binary | Node/npm | Node/npm | Node/npm | Ruby | None |
| YAGNI alignment | High | High | Highest | Low | High | Low |

**Chose Hugo** because:
- Largest ecosystem of free, polished marketing themes (Advance, Serif, Airspace, Andromeda, etc.)
- Single Go binary — no Node/npm/Ruby dependency to manage
- Sub-second builds
- Mature: 86k+ GitHub stars, well-documented, stable release cycle

**Astro was the runner-up** — modern component model, zero-JS-by-default philosophy, rapidly growing theme ecosystem. Would be the pick if JS/Node were a strength or if interactive components (forms, dynamic content) were needed. Worth revisiting if Hugo proves frustrating.

**Ruled out:**
- **Next.js**: Full-stack React framework, overkill for static marketing pages
- **Jekyll**: Aging ecosystem, slower builds, requires Ruby
- **Eleventy**: Excellent minimalism but fewer marketing-ready themes
- **Plain HTML**: No templating means duplicated headers/footers across every page — maintenance scales poorly

## Hosting (not yet decided)

Top candidates for Hugo:
- **GitHub Pages** (free, via GitHub Actions) — simplest since repo is already on GitHub
- **Netlify** (free tier) — adds deploy previews, built-in form handling
- **Cloudflare Pages** (free tier) — fastest CDN, more infrastructure-oriented

All are free for this use case. Decision deferred.
