# Project Tracking

## Domains

- Decide on domain names for both brands
  - *Blocked by: domain name question*
- Choose a domain registrar
  - *Blocked by: registrar question*
- Register domains
  - *Blocked by: domain name and registrar decisions*
- Configure DNS records
  - *Blocked by: domain registration, email setup, and hosting decision*

## Email

- Purchase Microsoft 365 Hosted Exchange Plan 1
  - *Blocked by: domain registration*
- Configure custom domain in Exchange
  - *Blocked by: Exchange purchase*
- Set up initial aliases (e.g. billing@, info@)
  - *Blocked by: Exchange domain config, alias question*
- Configure email on Andrea's devices (iPhone, Outlook)
  - *Blocked by: Exchange domain config*
- Document email SLA and recovery procedures
  - *Blocked by: Exchange domain config*

## Website

- ~~Decide site architecture (one site vs two, technology, hosting)~~ ✓
  - One site (Ontario Menopause Clinic), Hugo, Cloudflare Pages
- Finalize services list content
  - *Andrea to provide*
- Write "About Andrea" copy
  - *Rough notes exist in website_design.md*
- Write "Who is a good candidate?" copy
  - *Andrea to provide*
- Design visual identity (logo, colours, typography)
  - *Blocked by: brand identity question*
- Build website
  - *Blocked by: architecture decision, content, visual identity*
- Configure SEO (meta tags, structured data, sitemap, robots.txt)
  - *Blocked by: website build*
- Set up analytics
  - *Blocked by: analytics tool question, website build*
- Integrate Avaros intake link
  - *Blocked by: website build, intake URL question*
- ~~Deploy website (staging) to Cloudflare Pages~~ ✓
  - Staging: https://staging.violet-nzf.pages.dev — branch: `staging`
  - Production (no custom domain yet): https://violet-nzf.pages.dev — branch: `release`
  - `release` branch is PR-only (branch protection enabled, enforce_admins: true)
- Deploy website (production) and configure DNS
  - *Blocked by: website build, domain registration*

## Avaros

- Contact Avaros support re: OHIP billing changes
- Determine billing configuration path (new config vs modify existing)
  - *Blocked by: Avaros support response*
- Configure patient self-scheduling (15-min intake appointments)
- Create/configure intake form
  - *Blocked by: intake form fields question*
- Test self-scheduling flow end-to-end
  - *Blocked by: self-scheduling config, intake form*
- Coordinate OHIP billing cutover
  - *Blocked by: billing config path decision; deadline April 1st*

## Marketing

- Determine advertising platforms and budget
  - *Blocked by: platform and budget questions*
- Set up advertising accounts
  - *Blocked by: platform decision, website live*
- Create initial ad campaigns
  - *Blocked by: ad accounts*
- Set up conversion tracking
  - *Blocked by: analytics setup, ad accounts*
- Monitor and assess initial campaign results
  - *Blocked by: campaigns launched*

## Operations

- Define SLAs for all services (website, email, Avaros)
- Determine if privacy policy / terms of service are required
  - *Blocked by: privacy question*
