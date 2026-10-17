import { test, expect } from '@playwright/test';
import { PAGES } from './pages';

// 320px is the narrowest phone we support (iPhone SE 1st gen); horizontal
// scroll there is a WCAG 1.4.10 Reflow failure as well as a layout bug (#151).
test.describe('no horizontal scroll at 320px', () => {
  test.use({ viewport: { width: 320, height: 568 } });
  for (const pagePath of PAGES) {
    test(pagePath, async ({ page }) => {
      await page.goto(pagePath);
      const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
      expect(scrollWidth).toBeLessThanOrEqual(320);
    });
  }
});

// A 375x667 phone (iPhone SE 2nd/3rd gen) should see the whole hero, and the
// whole first quiz question down to its disclaimer, without scrolling (#114).
test.describe('above the fold at 375x667', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('hero trust bullets', async ({ page }) => {
    await page.goto('/');
    for (const item of await page.locator('.hero__trust-item').all()) {
      await expect(item).toBeInViewport({ ratio: 1 });
    }
  });

  test('quiz first question', async ({ page }) => {
    await page.goto('/quiz/');
    await page.locator('.quiz-page button:visible').first().click();
    await expect(page.locator('.quiz-page .quiz__next')).toBeInViewport({ ratio: 1 });
    await expect(page.locator('.quiz-page .quiz__disclaimer:visible')).toBeInViewport({ ratio: 1 });
  });
});

// Phones always land on /book/. The Avaros landing page is ~683px tall at
// phone widths; a shorter frame hides its "Book an appointment" button below
// the iframe's edge, behind an inner scroll nobody notices (#165).
test.describe('/book/ shows the Avaros booking button', () => {
  // iPhone 16 width; height is Safari's vh there (its 80vh frame measured
  // ~587px on-device), which Chromium's own chrome-less viewport overstates.
  test.use({ viewport: { width: 393, height: 734 } });

  test('frame height floor', async ({ page }) => {
    await page.goto('/book/');
    const box = await page.locator('.book-page__frame').boundingBox();
    expect(box!.height).toBeGreaterThanOrEqual(720);
  });

  // Avaros owns this content, so only a run against real content can catch it
  // growing: BASE_URL=https://staging.ontariomenopauseclinic.ca npm run a11y
  test('live Avaros button inside the frame', async ({ page }) => {
    await page.goto('/book/');
    const frame = page.locator('.book-page__frame');
    const src = (await frame.getAttribute('src')) ?? '';
    test.skip(!src.includes('avaros.ca'), 'placeholder booking URL (CI); run against staging');
    const button = page.frameLocator('.book-page__frame').getByText(/book an appointment/i);
    await button.waitFor({ timeout: 20_000 });
    const f = (await frame.boundingBox())!;
    const b = (await button.boundingBox())!;
    expect(b.y + b.height).toBeLessThanOrEqual(f.y + f.height);
  });
});
