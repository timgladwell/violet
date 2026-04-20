import { test } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import * as fs from 'fs';
import * as path from 'path';
import type { Result } from 'axe-core';
import axeConfig from '../.axe.json';

const PAGES = [
  '/',
  '/about/',
  '/services/',
  '/what-we-treat/',
  '/faq/',
  '/privacy/',
  '/medical-disclaimer/',
];

interface PageResult {
  path: string;
  violations: Result[];
}

test('wcag-2.1-aa', async ({ page }) => {
  const results: PageResult[] = [];

  for (const pagePath of PAGES) {
    await page.goto(pagePath);
    const { violations } = await new AxeBuilder({ page })
      .withTags(axeConfig.runOnly.values)
      .analyze();
    results.push({ path: pagePath, violations });
  }

  fs.writeFileSync(
    path.join(__dirname, 'violations.json'),
    JSON.stringify(results, null, 2),
  );

  const total = results.reduce((n, r) => n + r.violations.length, 0);
  if (total > 0) {
    const summary = results
      .filter(r => r.violations.length > 0)
      .map(r => `  ${r.path}: ${r.violations.length} violation(s)`)
      .join('\n');
    throw new Error(`Found ${total} accessibility violation(s):\n${summary}\n\nSee violations.json for details.`);
  }
});
