# Website Aesthetics

* Initial aesthic guidance from Andrea: "As for colours for the website - I prefer black, white, baby pink, sand and forest green. Like classy, calm with a touch of girly. "

## Design Attempt 1

* Captured as branch `design-attempt-1` / https://github.com/timgladwell/violet/pull/32
* Andrea's feedback: "It's too green"

## Design Attempt 2

* Inspirataion picture @docs/design_attempt_2_inspo.png
* Toned down the green and replaced with shades of pink
* Captured as branch `claude/intelligent-chatelet` / https://github.com/timgladwell/violet/pull/27
* Andrea's feedback: "I still think it's too much green. Like maybe more pink…"

## Design Attempt 3

* Restarted from scratch with new prompt:

```
❯ Please develop a branding and marketing website for Andrea's business. Ignore any previously developed UX and start from scratch - we are trying to generate an alternative implementation to show Andrea
  * the brand relates to medicine - the website should be clean and bold to reflect confidence and change
  * the brand relates to menopause - the website should be soft and feminine, with a healing energy
  * Andrea prefers pink as a thematic colour - she specifically references lily flowers, but **not** the leaves, Andrea doesn't like green.
  * Use Andrea's headshot only in relation to "About Andrea".
```

* Captured as branch `feat/alternative-design` / https://github.com/timgladwell/violet/pull/28
* Andrea's feedback: "I like the lighter pink one over all."

## Palm Trees Beach Theme

* Andrea's guidance: "I want the website to feel calming. Like you are at the beach."
* Inspiration picture @docs/beach_theme_palm_trees_inspo.png **Ignore text, focus on the picture's colour pallete and the aesthetics**
* Use Andrea's headshot only in relation to "About Andrea".

### Canva-determined template style
* Fonts
    * Open Sans
    * Playlist Script
* Colours:
    * #C4BEAC
    * #4A99AB
    * #29647A
    * #D0EAF0
    * #FFFFFF

### Canva-dermined photo colours

* Light Azure #c9ebf1
* Pastel Grey Yellow #c7c2b1
* Azure #1aa96aa9
* Dark Azure #046c85
* Gray Olive #97974f
* Dark gray brown #58572b

## Seascape Beach Theme

* Andrea's guidance: "I want the website to feel calming. Like you are at the beach."
* Inspiration picture @docs/beach_theme_seascape_inspo.png **Ignore text, focus on the picture's colour pallete and the aesthetics**

### Canvaa-determined template style
* TBD

### Canva-determined photo colours
* White #ffffff
* Pastel gray orange #c2b1aaa9
* Light orange #dfcabb
* Pastel gray orange #dabcac
* Gray orange #ad9a94
* Gray orange #b18e7e

### Design results
Design direction: "Pacific Shore" — the feeling of early morning on a calm beach, where medical confidence and healing softness coexist.

Key design decisions:

- Typography: Dancing Script (700) for all display/emotional text — hero headline, CTA heading, symptoms closing line, the "how it works" sign-off, about quote. Open Sans (300–600) for all body/UI. The contrast between flowing
script and clean sans-serif is the visual metaphor for Andrea's whole-person approach.
- Colour palette: Deep ocean teal #29647A as the authority/action colour; azure #4A99AB as accent; light azure #D0EAF0 for backgrounds; warm sand #C4BEAC/#F0EDE5 for softness; charcoal #1C2F38 for text. Every colour is drawn
directly from the Canva palette in the design notes.
- Wave divider: An organic SVG wave at the bottom of the hero section transitions from the ocean teal to the warm sand background — the literal visual metaphor of ocean meeting shore.
- Frosted-glass nav: Semi-transparent with backdrop-filter: blur that becomes fully opaque on scroll.
- Hero trust bar: Three short trust signals below the CTAs ("No referral needed", "Virtual care across Ontario", "Menopause Society Certified") — replaces the headshot with credential confidence.
- About preview: Cert badges in a teal panel replace Andrea's headshot, per the new requirement that her photo only appears on the About page.
- Andrea's headshot: Removed from hero and home page about-preview; remains on the About page only.


---

## Prompt-based attempts

Please develop a branding and marketing website for Andrea's business. Ignore any previously developed UX and start from scratch - we are trying to generate an
  alternative implementation to show Andrea

  Focus on _only_ the "Palm Trees Beach Theme" in @docs/website_aesthetic_design_notes.md.

  Andrea's business is based on providing a whole-person approach to menopause. For her clients, this is the intersection of medicine, change, and
  self-actualization - the website should be soft and feminine, with a healing energy. The website's undertone needs to reflect Andrea's expertise and
  capabilities - she is a confident medical professional.

