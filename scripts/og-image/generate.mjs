import { chromium } from '@playwright/test';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs/promises';

const dir = path.dirname(fileURLToPath(import.meta.url));
const templatePath = path.join(dir, 'template.html');
const renderPath = path.join(dir, '_render.html');
const outputPath = path.join(dir, '../../site/static/images/og-image.png');
const fontsPath = path.join(dir, '../../site/layouts/partials/fonts.html');

const template = await fs.readFile(templatePath, 'utf8');
const fonts = await fs.readFile(fontsPath, 'utf8');
await fs.writeFile(renderPath, template.replace('FONTS_PLACEHOLDER', fonts), 'utf8');

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
await page.goto(`file://${renderPath}`, { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: outputPath });
await browser.close();
await fs.unlink(renderPath);

console.log(`Wrote ${outputPath}`);
