# Runbook

## Toggle maintenance mode (no deploy required)

Use this to take the production site down (incident, planned downtime) or bring it
back up. `maintenanceMode` is a Hugo param (`site/hugo.toml`) baked in at build
time, defaulting to `true` in `site/config/production/hugo.toml` — but it can be
overridden per-build via the `HUGO_PARAMS_MAINTENANCEMODE` env var, which lets you
flip it without going through a PR to the protected `release` branch.

When on, every route on the production site shows a fixed "We're almost ready"
placeholder instead of real content, the page is marked `noindex` (meta tag,
`robots.txt`, and `llms.txt` all block/omit indexing), and `nav`/`footer` are
hidden. Page titles/descriptions are left unchanged so any social link
previews cached during the outage stay accurate once the real site is back.

Note: `noindex`/`Disallow` are "stop indexing this" signals, not "temporarily
down, come back later" signals — fine for short outages, but see
[#77](https://github.com/timgladwell/violet/issues/77) for the proper fix
(HTTP 503 at the Cloudflare edge) if an outage runs longer than a day or two.

**To flip it:**

1. Cloudflare dashboard → Pages → `violet` project → Settings → Environment variables → **Production** scope.
2. Set `HUGO_PARAMS_MAINTENANCEMODE` to `true` (down) or `false` (up).
3. Deployments tab → find the latest production deployment → **Retry deployment**. This reruns the build with the new env var — no git push, no PR.
4. Once the new deployment is live, **purge the Cloudflare cache** (Caching → Configuration → Purge Everything). The zone's `browser_cache_ttl` is 4 hours (see `docs/cloudflare-config.md`), so without a purge visitors can keep seeing the old state for up to 4 hours.

Local/CI/staging builds always run with `maintenanceMode = false` regardless of
this env var (see `site/config/development/hugo.toml`, `site/config/staging/hugo.toml`)
— the env var only affects the Cloudflare Pages production build.
