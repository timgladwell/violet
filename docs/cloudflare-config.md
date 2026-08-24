# Cloudflare Configuration

Reference document for the Cloudflare setup for `ontariomenopauseclinic.ca`.

A future Terraform implementation should be able to reconstruct this configuration from scratch — tracked in [#40](https://github.com/timgladwell/violet/issues/40). Until then, `./export-cloudflare.sh` is the continuity plan: it dumps the live config to [`cloudflare-export/`](cloudflare-export/), which is committed.

**Which file to trust:** [`cloudflare-export/SUMMARY.md`](cloudflare-export/) is generated from the API and is authoritative for *what is configured*. This document is hand-written and is authoritative for *why* — the reasoning, the failure modes, and the decisions that are not recoverable from a config dump. When they disagree, the export is right about the facts and this file needs updating.

The export also **probes for features nobody recorded** (email routing, page rules, workers routes, analytics, Turnstile, and so on) and lists anything it finds, because the dashboard has been changed by hand over time without notes.

---

## Change history

Only changes with consequences — something that altered behaviour, or that would
bite someone rebuilding this. Routine edits are `git log`'s job, not this table.

| Date | Change |
|------|--------|
| 2026-06-05 | Initial capture of the Cloudflare configuration. |
| 2026-07-28 | Cloudflare Fonts enabled, in response to a PageSpeed render-blocking finding. Rewrites Google Fonts to same-origin `/cf-fonts/` — and, unremarked at the time, replaces the `<link>` with inline CSS carrying `font-display: swap`, which is why #128's blocking-link revert is a no-op in production. |
| 2026-07-28 | `www`-to-apex Redirect Rule added, after Search Console flagged duplicate `www` content ([#124](https://github.com/timgladwell/violet/issues/124)). |
| 2026-08-24 | `www` removed from the Pages custom domains; removing it also deleted its DNS record, replaced by a proxied A record to `192.0.2.1`. |
| 2026-08-24 | `staging.ontariomenopauseclinic.ca` added as an in-zone staging hostname, so staging inherits zone-level features that `*.pages.dev` cannot. |

---

## Zone

| Field | Value |
|-------|-------|
| Zone name | `ontariomenopauseclinic.ca` |
| Zone ID | `df4711b6c10cf3043898e21d6c23f007` |
| Plan | Free |
| Status | Active |

---

## DNS Records

| Type | Name | Content | Proxied | TTL |
|------|------|---------|---------|-----|
| CNAME | `ontariomenopauseclinic.ca` | `violet-6qt.pages.dev` | Yes | Auto |
| A | `www` | `192.0.2.1` (RFC 5737 TEST-NET-1 — never reached; see Redirect Rules) | **Yes (required)** | Auto |
| CNAME | `staging` | `staging.violet-6qt.pages.dev` | **Yes (required)** | Auto |
| CNAME | `autodiscover` | `autodiscover.outlook.com` | No | 3600 |
| CNAME | `selector1._domainkey` | `selector1-ontariomenopauseclinic-ca._domainkey.ontariomenopauseclinic.a-v1.dkim.mail.microsoft` | No | Auto |
| CNAME | `selector2._domainkey` | `selector2-ontariomenopauseclinic-ca._domainkey.ontariomenopauseclinic.a-v1.dkim.mail.microsoft` | No | Auto |
| MX | `ontariomenopauseclinic.ca` | `ontariomenopauseclinic-ca.mail.protection.outlook.com` | No | 3600 |
| TXT | `ontariomenopauseclinic.ca` | `v=spf1 include:spf.protection.outlook.com ~all` | No | 3600 |
| TXT | `ontariomenopauseclinic.ca` | `MS=ms74690258` (Microsoft domain verification) | No | 3600 |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:cea6b6a7fa294e928c7497395cfd0d92@dmarc-reports.cloudflare.net` | No | Auto |

### Notes
- The apex CNAME points to the Pages project subdomain (`violet-6qt.pages.dev`), proxied through Cloudflare.
- `www` is **not** a CNAME to the project. It is a proxied A record to a
  documentation address that is routable nowhere. Its only job is to put
  Cloudflare in the request path so the Redirect Rule can answer; nothing ever
  travels to the address itself.
- The DKIM `selector1`/`selector2` records are managed by Microsoft 365. They will rotate automatically; the DNS records must be updated when Microsoft rotates them.
- The DMARC reporting address (`...@dmarc-reports.cloudflare.net`) is Cloudflare's managed DMARC reporting — reports are viewable in the Cloudflare dashboard.
- `MS=ms74690258` is the Microsoft 365 domain verification TXT record. It can be removed once verification is no longer required, but removing it is low priority.

---

## Redirect Rules

| Field | Value |
|-------|-------|
| Rule name | `www to apex redirect` |
| When incoming requests match | Hostname equals `www.ontariomenopauseclinic.ca` |
| Then | Dynamic redirect to `concat("https://ontariomenopauseclinic.ca", http.request.uri.path)`, preserve query string |
| Status code | 301 (permanent) |
| Created via | Cloudflare's built-in "Redirect www to root" template (Rules → Redirect Rules → Create rule → Templates) — still requires entering the matching hostname and target expression, but the template makes clear where each piece of info goes |

### Notes
- Required because the `www` and apex DNS records both resolve independently (see DNS Records above) — without this rule, both hostnames serve identical content as separate 200 responses.
- Google Search Console flagged this as a duplicate/canonical issue in July 2026 (`www` page shown as "Alternate page with proper canonical tag", and several apex pages as "Crawled - currently not indexed") — see [#124](https://github.com/timgladwell/violet/issues/124).
- The site's own canonical `<link>` tags (baseURL `https://ontariomenopauseclinic.ca/` in `site/hugo.toml`) are a signal, not a redirect — they don't stop crawlers or browsers from independently loading the `www` host. This Cloudflare rule is what actually consolidates the two hosts at the edge.
- **`www` is not a Pages custom domain**, and must not be added as one. A
  Redirect Rule only needs a *proxied DNS record* on the hostname so Cloudflare
  is in the request path; the CNAME target is never used, because the 301 is
  answered at the edge and the request never reaches Pages.
- If `www` is added to the Pages project's custom domains, it will sit at
  **"Verifying" forever.** Pages verifies a custom domain by requesting the
  hostname and expecting to reach the project — but this rule returns a 301
  first, so the probe never gets there. The rule that makes `www` correct is the
  same thing that blocks verification. Remove it from the custom domains list;
  do not try to make it verify, and do not disable the rule to let it through.
- **Removing `www` from the Pages custom domains also deletes its DNS record.**
  The confirmation dialog says so in passing: "The CNAME record pointing to your
  project will be removed to make this change." Without a proxied record on
  `www`, Cloudflare is no longer in the request path, this rule cannot fire, and
  `www` stops resolving altogether — NXDOMAIN, not a redirect. **Recreate a
  proxied record for `www` immediately afterwards**, then confirm:

  ```sh
  curl -sI https://www.ontariomenopauseclinic.ca/services/ | grep -i '^location'
  # expect: location: https://ontariomenopauseclinic.ca/services/
  ```

- The replacement is an A record to `192.0.2.1` rather than a CNAME back to the
  project or the apex, so that losing this Redirect Rule fails **loudly** (522 —
  nothing answers at that address) instead of quietly serving a second copy of
  the site. Silent duplicate `www` content is what GSC flagged in the first
  place, so the noisy failure is the one worth having.

---

## Zone Settings

| Setting | Value | Notes |
|---------|-------|-------|
| `always_use_https` | `on` | |
| `ssl` | `full` | Certificate active |
| `min_tls_version` | `1.0` | Consider raising to `1.2` |
| `email_obfuscation` | **on** | Rewrites email addresses in HTML before delivery to prevent scraping |
| `brotli` | `on` | |
| `http2` | `on` | Not editable |
| `browser_cache_ttl` | `14400` (4 hours) | |
| `rocket_loader` | `off` | Cloudflare's async JS loader — off is appropriate for a Hugo static site |
| `fonts` (Speed → Optimization → Fonts) | **on** | Rewrites Google Fonts requests (`fonts.googleapis.com`/`fonts.gstatic.com`) to serve from the same origin via Cloudflare's edge, removing the extra third-party DNS/TLS hops. Enabled 2026-07-28 in response to a PageSpeed Insights finding — see `site/layouts/partials/fonts.html` for the paired non-blocking `<link>` change. |

`min_tls_version` is `1.0`; raising it to `1.2` is tracked in
[#143](https://github.com/timgladwell/violet/issues/143).

---

## Staging in-zone (`staging.ontariomenopauseclinic.ca`)

The default `staging` slot is served from a hostname inside this zone so it gets
the zone's settings — Cloudflare Fonts, cache rules, redirect rules — and
therefore behaves like production. `*.pages.dev` sits outside the zone and gets
none of them, which is how a font change once passed review on staging and was a
no-op in production (see #128).

Setup, per Cloudflare's [custom branch aliases](https://developers.cloudflare.com/pages/how-to/custom-branch-aliases/):

1. Pages project → Custom domains → add `staging.ontariomenopauseclinic.ca`.
2. Cloudflare adds a CNAME pointing at `violet-6qt.pages.dev`. **Edit it** to
   target the branch alias `staging.violet-6qt.pages.dev`.

That is the whole Cloudflare-side setup. The hostname itself lives in the repo
(`site/config/staging/hugo.toml`), the same way production's lives in
`site/hugo.toml` — it is a constant, not a secret, so there is no dashboard
variable to keep in sync.

**The record must stay proxied (orange cloud).** An unproxied or external-DNS
record does not reach the branch alias — Cloudflare routes it to the project's
**production** branch instead. That would serve production content, built with
the production environment and therefore *without* `noindex` or
`Disallow: /`, on a hostname search engines can reach. The failure is silent:
the site looks correct, it is just the wrong one. After any change to this
record, confirm the staging banner is present and:

```sh
curl -s https://staging.ontariomenopauseclinic.ca/robots.txt   # must say Disallow: /
```

### Why the record must be proxied — the short version

A CNAME is a **DNS-layer alias, not a redirect.** The resolver follows the chain
only to reach an IP address, then discards the intermediate names. The browser
connects to that IP and sends TLS SNI and an HTTP `Host:` header built from *the
URL the user typed* — never from the CNAME target. The URL bar does not change,
because nothing redirected. So `staging.violet-6qt.pages.dev` is a signpost the
resolver reads and throws away; the origin never learns it existed.

Pages decides which deployment to serve from that `Host` header. You can see it
with one IP and two hostnames:

```sh
IP=$(dig +short violet-6qt.pages.dev A | head -1)
curl -s --resolve "violet-6qt.pages.dev:443:$IP"         https://violet-6qt.pages.dev/robots.txt          # Allow: /
curl -s --resolve "staging.violet-6qt.pages.dev:443:$IP" https://staging.violet-6qt.pages.dev/robots.txt  # Disallow: /
```

Same IP, same connection — only `Host` differs, and you get two different sites.

Since the CNAME target never reaches the origin, something must read it *inside*
the request path. That is the entire job of the orange cloud:

- **Proxied** — Cloudflare terminates TLS itself, so it is a decision point in
  the path. It can consult the zone record, see the target is the branch alias,
  and route accordingly.
- **DNS-only** — Cloudflare is just a nameserver. It answers the query and drops
  out. Nothing is left in the path to override anything, so the request arrives
  at Pages carrying only a custom-domain `Host` — which serves production.

Put another way: a proxy is a decision point; a nameserver is a lookup that has
already finished by the time the request happens.

**Confidence:** the *outcome* is documented verbatim by Cloudflare (see the
quotes in the setup steps above, plus [preview deployments](https://developers.cloudflare.com/pages/configuration/preview-deployments/):
"Any custom domains, as well as your `user-example.pages.dev` site, will not be
affected by preview deployments"). The *mechanism* above — Host matched against
registered custom domains, which bind to production — is a working model
consistent with observed behaviour, not a published spec; the custom domains
reference page does not state it. Treat the documented sentence as the binding
one, and keep the `robots.txt` check: this is a technique that leans on proxy
placement rather than a first-class feature, so it could change without a
changelog entry.

### Additional staging slots

Numbered slots (`staging2`, `staging3`, …) stay on `stagingN.violet-6qt.pages.dev`
and need no DNS. They are outside the zone, so use them for comparing UX
concepts, not for anything depending on zone-level behaviour. To bring one
in-zone, repeat steps 1–2 with `stagingN` and give it a `baseURL`; `build.sh`
takes the config `baseURL` only for the branch named exactly `staging`, and
falls back to the per-deployment `$CF_PAGES_URL` for every other slot, so a new
in-zone slot needs that condition widened.

## Pages Project

| Field | Value |
|-------|-------|
| Project name | `violet` |
| Pages subdomain | `violet-6qt.pages.dev` |
| Production branch | `release` |
| Build image | v3 |
| Compatibility date | 2026-04-16 |

### Custom domains

| Hostname | Serves | Notes |
|----------|--------|-------|
| `ontariomenopauseclinic.ca` | production (`release`) | The canonical site |
| `staging.ontariomenopauseclinic.ca` | `staging` branch | Via the branch-alias CNAME — see "Staging in-zone" above |
| ~~`www.ontariomenopauseclinic.ca`~~ | — | Removed 2026-08-24. Its DNS record was deleted with it and replaced by a proxied A record — see DNS Records. |

`www` was registered as a custom domain when the project was first set up, and
served the site directly — which is why both hostnames once returned identical
200 responses (see Redirect Rules → Notes). Once the `www`-to-apex Redirect Rule
was added in July 2026, the registration became both unnecessary and impossible
to verify: Pages verifies by requesting the hostname, and the rule answers with a
301 before the request reaches Pages, so the dashboard shows it stuck at
"Verifying". Removing it from the custom domains list is the fix; the proxied
DNS record stays.

### Build command
Configured via `site/build.sh` (checked into the repo). Cloudflare Pages build root is `site/`.

### Environment variables

Both production and preview environments are configured identically.

| Variable | Value |
|----------|-------|
| `HUGO_VERSION` | `0.162.0` (must be kept in sync with `.tool-versions` at repo root — Cloudflare Pages reads this dashboard value directly, it can't read the repo file) |
| `HUGO_PARAMS_BOOKINGURL` | _(secret — see `.env.local.example`)_ |
| `HUGO_PARAMS_INFOCONTACTEMAIL` | _(secret — see `.env.local.example`)_ |
| `HUGO_PARAMS_PRIVACYCONTACTEMAIL` | _(secret — see `.env.local.example`)_ |
