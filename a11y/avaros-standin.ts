import type { Page } from '@playwright/test';
import fixture from './fixtures/avaros-landing.json';

// Replaces whatever the booking iframe loads (the real Avaros page, or CI's
// placeholder URL) with a stand-in sized from the measured Avaros landing page
// (scripts/measure-avaros.mjs), so the booking tests run identically everywhere (#165).
// The stand-in reads its own width and reproduces the button's measured box.
// From the two samples either side of its width it takes the worse value for
// each edge (the larger overhang right and down, the smaller offset left and
// up), which stays safe across an Avaros layout breakpoint.
const STANDIN = `<!doctype html>
<meta name="viewport" content="width=device-width">
<style>
  body { margin: 0; }
  button { position: absolute; }
</style>
<div id="page"></div>
<button type="button">Book an appointment</button>
<script>
  const samples = ${JSON.stringify(fixture.samples)};
  const w = innerWidth;
  const below = [...samples].reverse().find(s => s.width <= w) ?? samples[0];
  const above = samples.find(s => s.width >= w) ?? samples[samples.length - 1];
  // Not \`top\`/\`left\`: those clash with window globals and abort the script.
  const x1 = Math.min(below.buttonLeft, above.buttonLeft);
  const y1 = Math.min(below.buttonTop, above.buttonTop);
  const x2 = w + Math.max(below.buttonRight - below.width, above.buttonRight - above.width);
  const y2 = Math.max(below.buttonBottom, above.buttonBottom);
  document.getElementById('page').style.height = Math.max(below.height, above.height) + 'px';
  const button = document.querySelector('button');
  Object.assign(button.style, {
    left: x1 + 'px', top: y1 + 'px', width: (x2 - x1) + 'px', height: (y2 - y1) + 'px',
  });
  // The tests only accept a placed button, so a broken script fails them
  // instead of passing against an unstyled one.
  button.dataset.placed = '';
</script>`;

// Matches the stand-in's button only once its script has placed it.
export const PLACED_BUTTON = 'button[data-placed]';

export async function useAvarosStandIn(page: Page) {
  await page.route('**/*', (route, request) => {
    if (request.isNavigationRequest() && request.frame().parentFrame()) {
      return route.fulfill({ contentType: 'text/html', body: STANDIN });
    }
    return route.continue();
  });
}
