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
