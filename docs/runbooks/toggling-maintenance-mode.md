# Toggling Maintenance Mode

Takes the production site down (incident, planned downtime) or brings it back
up, without a deploy.

`maintenanceMode` is a Hugo param (`site/hugo.toml`) baked in at build time,
defaulting to `true` in `site/config/production/hugo.toml`. The
`HUGO_PARAMS_MAINTENANCEMODE` env var overrides it per build, so it can be
flipped without a PR or a release.

When on, every route on production shows a fixed "We're almost ready"
placeholder instead of real content, the page is marked `noindex` (meta tag,
`robots.txt` and `llms.txt` all block or omit indexing), and the nav and footer
are hidden. Page titles and descriptions are unchanged, so social link previews
cached during the outage stay accurate once the site is back.

`noindex`/`Disallow` mean "stop indexing this", not "temporarily down, come back
later". That is fine for short outages; for anything over a day or two, see
[#77](https://github.com/timgladwell/violet/issues/77) (HTTP 503 at the
Cloudflare edge).

## Pre-checks

1. **You are changing the Production scope.** The env var overrides config in
   **every** environment it is set for. Setting it in Cloudflare's **Preview**
   scope puts staging into maintenance mode too — useful for checking the
   placeholder on staging, but remove it and redeploy afterwards: while it is
   set, staging can't be used to verify a release. Local and CI builds stay off
   only because nothing sets it there.

## Steps

1. Cloudflare dashboard → Pages → `violet` project → Settings → Environment
   variables → **Production** scope.
2. Set `HUGO_PARAMS_MAINTENANCEMODE` to `true` (down) or `false` (up).
3. Deployments tab → the latest production deployment → **Retry deployment**.
   This reruns the build with the new env var — no git push, no PR.
4. Once the new deployment is live, **purge the Cloudflare cache** (Caching →
   Configuration → Purge Everything). The zone's `browser_cache_ttl` is 4 hours
   (see [`cloudflare-config.md`](../current-state/cloudflare-config.md)), so without a purge
   visitors can keep seeing the old state for up to 4 hours.

## Post-checks

1. **The homepage shows the expected state**, in a private window so nothing is
   served from your browser cache: the placeholder when down, the real homepage
   when up.
2. **Indexing signals match.** When up, `robots.txt` allows crawling and there
   is no `noindex`:

   ```sh
   curl -s https://ontariomenopauseclinic.ca/robots.txt | head -3
   curl -s https://ontariomenopauseclinic.ca/ | grep -c noindex   # 0 when up
   ```
