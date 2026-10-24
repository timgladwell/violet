# Competitive Analysis and Site Recommendations

This document captures the research and strategic rationale behind the recommended website structure. It is a reference for the build team — Andrea's working document is `website_content_draft.md`.

---

## Competitor Sites Analyzed

| Business | URL | Notes |
|----------|-----|-------|
| Modern Menopause | modernmenopause.ca | Strong symptom-led messaging, clean single-page flow |
| Bravella | bravellahealth.com | WordPress/Elementor — could not extract content (JS-rendered) |
| Coral | coral.ca | Excellent eligibility criteria section, transparent process |
| Blair Health | blairhealth.ca | Shows pricing, strong "How It Works" section |
| Medcan | medcan.com | Large multi-service clinic, enterprise feel |
| Midi Health | joinmidi.com | Best-in-class structure; insurance-led, symptom cards, testimonials |
| Bria | betterbria.com | Mental health angle, certification program |
| Virtual Menopause Clinic | virtualmenopauseclinic.com | Wix — could not extract content (JS-rendered) |
| Signature Wellness | signaturewellness.ca | Solo practitioner, simpler site, personal tone |

---

## Common Patterns Across All Competitors

Every competitor site follows a similar playbook:

- **Hero section** with a clear headline, short tagline, and a prominent "Book" call-to-action
- **Services listed** as visual cards or tiles, each linking to a detail page or section
- **"How it works"** section explaining the 3-4 step patient journey
- **About / team section** with practitioner credentials and a personal philosophy
- **Testimonials / social proof** from patients
- **Persistent call-to-action** — a "Book" button visible at all times (header or sticky element)
- **FAQ section** addressing common concerns (eligibility, virtual care, pricing, what to expect)
- **Footer** with contact info, legal links, and social media

## What Differentiates the Stronger Sites

The best-performing sites (Modern Menopause, Coral, Midi Health) do these things well:

- **Symptom-led messaging** — they lead with the patient's experience ("Are you experiencing hot flashes, brain fog, weight changes?") rather than clinical language
- **Clear eligibility criteria** — they tell visitors upfront who is and isn't a good fit
- **Transparent process** — they explain exactly what happens after booking (no surprises)
- **Credentials woven into story** — rather than listing certifications, they tell the practitioner's "why" story and embed credentials naturally
- **Single clear conversion path** — every page funnels to one action: book an appointment

---

## Recommended Site Structure

### Navigation

| Menu Item | Type | Notes |
|-----------|------|-------|
| Home | Page | Landing page |
| Services | Page (scrollable sections or linked cards) | Lists all services across both brands |
| About Andrea | Page | Practitioner story, credentials, philosophy |
| How It Works | Section on homepage (or standalone page) | 3-step patient journey |
| FAQ | Page | Common questions |
| Book Now | Button (styled differently from other nav items) | Links to Avaros intake |

**Footer links:** Contact, Privacy Policy, Terms of Service (if applicable), social media icons

### Navigation Design Notes

- Keep the navigation flat. No dropdowns, no sub-menus. A simple horizontal menu with 4-5 items plus a prominent "Book Now" button is the standard pattern across all competitors.
- "Book Now" should be visually distinct (e.g., a filled button vs. plain text links for the other items).
- On mobile, the navigation collapses to a hamburger menu, but "Book Now" remains visible at all times.

### Homepage Section Flow

The homepage is the most important page. Most visitors from ads will land here. It needs to accomplish four things within the first screen: (1) say who you are, (2) say who you help, (3) say why you're different, (4) make it easy to take the next step.

| # | Section | Purpose |
|---|---------|---------|
| 1 | Hero | Immediate clarity — who you are, what you do, a path to book |
| 2 | "Is This You?" symptom check-in | Help visitors self-identify with their lived experience |
| 3 | Services overview (cards) | Show the range, organized by brand (Ontario Menopause Clinic / Violet) |
| 4 | How It Works (3 steps) | Remove uncertainty about what happens after booking |
| 5 | About Andrea (preview) | Build personal connection and trust; links to full About page |
| 6 | Testimonials | Social proof from real patients |
| 7 | "Who Is a Good Candidate?" | Pre-qualify visitors and set expectations |
| 8 | Final call-to-action banner | Last conversion push |

### Other Pages

- **About Andrea (full page):** Story-driven, not a CV. First-person voice, credentials woven into narrative, philosophy of care, photos, and a booking button.
- **Services (full page):** Full descriptions for each service, organized by brand. Clear OHIP vs. patient-paid separation. Each service gets its own heading, 2-3 paragraph description, what to expect, and a booking button.
- **FAQ:** Organized by category (Practice, Services, Appointments, OHIP). Should use FAQ structured data (schema.org) for search engine visibility.

---

## Content Principles

Guidelines for writing content across the site:

1. **Write to the patient, not about the medicine.** Lead with "you" language ("Are you experiencing...") not clinical language ("Menopause is characterized by...").
2. **Keep it warm but professional.** The strongest competitor sites feel like a trusted friend who also happens to be a clinician. Avoid being overly clinical or overly casual.
3. **One call-to-action per page section.** Every section should end with either "Book Now" or "Learn More." Don't make the visitor figure out what to do next.
4. **Short paragraphs and scannable layouts.** Most visitors will scan, not read. Use headings, short paragraphs (2-3 sentences), bullet points, and visual cards.
5. **Be transparent about process, cost, and eligibility.** The competitors that do this well earn more trust. Don't make visitors hunt for basic information.
6. **Credentials support the story, they don't replace it.** "I trained at Sinai because..." is more compelling than a bullet list of certifications.

---

## SEO and Discoverability Notes

- Every page needs a unique title tag and meta description targeting relevant search terms (e.g., "menopause treatment Ontario," "menopause specialist near me," "OHIP menopause clinic")
- The Services page should use individual heading tags (H2) for each service to help search engines index them
- An FAQ page with structured data (FAQ schema) helps surface answers in Google's featured snippets and AI overviews
- A sitemap.xml and robots.txt will be auto-generated by Hugo
- Consider a blog or resources section in a future phase for ongoing SEO value (competitors like Modern Menopause and Midi Health use blogs to attract organic traffic)

---

## Advertising Landing Page Considerations

Since Andrea plans to run online ad campaigns immediately:

- The homepage is the default landing page for brand-awareness ads
- For targeted ads (e.g., "menopause treatment in Ontario"), consider creating dedicated landing pages that match the ad's specific messaging. These can be simple variations of the homepage with a more specific headline and a single CTA.
- Ensure the "Book Now" button is visible above the fold on mobile (this is where most ad traffic will arrive)
- Install analytics and conversion tracking before launching any campaigns

---

## Open Questions Affecting This Document

These are tracked in `decision_log.md`:

1. **One website or two?** This document assumes a single site with two branded sections. Can be split if preferred.
2. **Domain names** — not yet decided.
3. **Avaros intake URL** — needed for all "Book Now" buttons.
4. **Logo / brand identity** — structure works with logo or text-only.
5. **Analytics tool** — not yet decided.
6. **Privacy policy / terms of service** — to be determined (healthcare context in Ontario).
