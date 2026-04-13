## Decisions

| Category | Description                                             | Status | Decision                                                   | Notes                                                                                 |
|----------|---------------------------------------------------------|--------|------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Email    | Which email provider to use?                            | Closed | Microsoft 365 Hosted Exchange Plan 1                       | IMAP, works with iPhone and Outlook, supports aliases convertible to shared mailboxes |
| EMR      | Which electronic medical records provider to use?       | Closed | Avaros                                                     | Already in use                                                                        |
| Website  | What site design technology?                            | Closed | No dedicated design tool — use SSG template, customize in code | Solo build workflow; templates solve 80% of design; eliminates design-to-code export friction; zero cost |
| Website  | Which static site technology?                           | Closed | Hugo                                                       | Largest marketing theme ecosystem, single binary (no JS/Node dependency), sub-second builds, mature community. See investigation_notes.md for full comparison. |
| Hosting  | Which hosting platform?                                 | Closed | Cloudflare Pages                                           | Fastest TTFB (~57ms), free built-in analytics, unlimited bandwidth, auto-detects Hugo, automatic deploy previews. See investigation_notes.md. |
| Domains  | Which specific domain names to register for each brand? | Closed   | Only launching one brand - ontariomenopauseclinic.ca       | Two brands: "Ontario Menopause Clinic" and "Violet"                |
| Domains  | Which domain register to use?                           | Closed   | Cloudflare                                                           ||
| Website  | One website with two sections, or two separate websites? | Closed | One website to start, for Ontario Menopause Clinic         | Violet brand deferred; revisit when scope warrants a second site   |
| Website  | What is the specific list of services to display?       | Open   |                                                           | Andrea to provide                                                  |
| Website  | What is the "who is a good candidate?" content?         | Open   |                                                           | Andrea to provide                                                  |
| Website  | Will there be a logo/brand identity, or text-only?      | Open   |                                                           |                                                                    |
| Website  | How will site traffic be tracked?                       | Open   |                                                           | e.g. Google Analytics, Plausible, etc.                             |
| Website  | Is a privacy policy or terms of service required?       | Open   |                                                           | Healthcare context in Ontario                                      |
| Email    | Which domain(s) should email be configured on?          | Closed   |  Only one domain to launch                                 | Depends on domain name decisions                                   |
| Email    | What specific aliases are needed at launch?             | Open   |                                                           | e.g. billing@, info@, etc.                                         |
| EMR      | What is the Avaros patient intake URL to link from the website? | Open   |          | Needed for website CTA                                             |
| EMR      | What fields are required on the intake form?                    | Open   |          | Andrea to define                                                   |
| EMR      | Has Avaros support been contacted about OHIP billing changes?   | Closed   |  OHIP direct billing delayed        |                                                                    |
| EMR      | What is the cutover timeline for OHIP billing?                  | Closed   |  OHIP direct billing delayed        | Regulatory date is April 1st                                       |
| Marketing | Which advertising platforms?                                   | Open   |          | e.g. Google Ads, Meta/Instagram, etc.                              |
| Marketing | What is the initial marketing budget?                          | Open   |           |                                                                    |
| Marketing | What is the target geography/audience?                         | Open   |           |                                                                    |
