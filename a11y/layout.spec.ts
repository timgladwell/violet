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
