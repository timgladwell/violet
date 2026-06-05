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
| `HUGO_VERSION` | `0.162.0` |
| `HUGO_PARAMS_BOOKINGURL` | _(secret — see `.env.local.example`)_ |
| `HUGO_PARAMS_INFOCONTACTEMAIL` | _(secret — see `.env.local.example`)_ |
| `HUGO_PARAMS_PRIVACYCONTACTEMAIL` | _(secret — see `.env.local.example`)_ |
