# Cloudflare Configuration

Reference document for the Cloudflare setup for `ontariomenopauseclinic.ca`. Captured 2026-06-05.

A future Terraform implementation should be able to reconstruct this configuration from scratch. See the GitHub issue for that work.

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
| CNAME | `www` | `violet-6qt.pages.dev` | Yes | Auto |
| CNAME | `autodiscover` | `autodiscover.outlook.com` | No | 3600 |
| CNAME | `selector1._domainkey` | `selector1-ontariomenopauseclinic-ca._domainkey.ontariomenopauseclinic.a-v1.dkim.mail.microsoft` | No | Auto |
| CNAME | `selector2._domainkey` | `selector2-ontariomenopauseclinic-ca._domainkey.ontariomenopauseclinic.a-v1.dkim.mail.microsoft` | No | Auto |
| MX | `ontariomenopauseclinic.ca` | `ontariomenopauseclinic-ca.mail.protection.outlook.com` | No | 3600 |
| TXT | `ontariomenopauseclinic.ca` | `v=spf1 include:spf.protection.outlook.com ~all` | No | 3600 |
| TXT | `ontariomenopauseclinic.ca` | `MS=ms74690258` (Microsoft domain verification) | No | 3600 |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:cea6b6a7fa294e928c7497395cfd0d92@dmarc-reports.cloudflare.net` | No | Auto |

### Notes
- The apex and `www` CNAMEs both point to the Pages project subdomain (`violet-6qt.pages.dev`), proxied through Cloudflare.
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
- Google Search Console flagged this as a duplicate/canonical issue in July 2026 (`www` page shown as "Alternate page with proper canonical tag", and several apex pages as "Crawled - currently not indexed") — see closed issue for details.
- The site's own canonical `<link>` tags (baseURL `https://ontariomenopauseclinic.ca/` in `site/hugo.toml`) are a signal, not a redirect — they don't stop crawlers or browsers from independently loading the `www` host. This Cloudflare rule is what actually consolidates the two hosts at the edge.

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

### Action items
- **Consider raising `min_tls_version` to `1.2`** — TLS 1.0 and 1.1 are deprecated and not used by any current browser. Low urgency but a straightforward hardening step.

---

## Pages Project

| Field | Value |
|-------|-------|
| Project name | `violet` |
| Pages subdomain | `violet-6qt.pages.dev` |
| Production branch | `release` |
| Build image | v3 |
| Compatibility date | 2026-04-16 |

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
