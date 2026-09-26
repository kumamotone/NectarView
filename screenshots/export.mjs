import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

const LANGUAGES = [
  'en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'fr', 'de', 'es',
  'pt-BR', 'th', 'vi', 'id', 'it', 'pl', 'tr', 'ru',
  'ms', 'nl', 'sv', 'da', 'nb', 'fi',
  'ar-SA', 'ca', 'cs', 'el', 'en-AU', 'en-CA', 'en-GB',
  'es-MX', 'fr-CA', 'he', 'hi', 'hr', 'hu', 'no',
  'pt-PT', 'ro', 'sk', 'uk'
];

const SLIDES = ['slide-1', 'slide-2', 'slide-3', 'slide-4'];

const outDir = join(__dirname, 'export');
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1400, height: 4000 }, deviceScaleFactor: 1 });

// Load the HTML file
await page.goto(`file://${join(__dirname, 'feature-graphic.html')}`, {
  waitUntil: 'networkidle'
});

// Wait for Lucide icons to render
await page.waitForTimeout(1500);

let total = 0;

for (const lang of LANGUAGES) {
  const langDir = join(outDir, lang);
  mkdirSync(langDir, { recursive: true });

  // Switch language
  await page.evaluate((l) => {
    switchLang(l, null);
  }, lang);
  await page.waitForTimeout(300);

  for (const slideId of SLIDES) {
    const slide = page.locator(`#${slideId}`);
    const filename = join(langDir, `${slideId}.png`);

    await slide.screenshot({
      path: filename,
      type: 'png',
      scale: 'device'  // Use device pixel ratio for crisp images
    });
    total++;
  }

  console.log(`✓ ${lang} (4 slides)`);
}

await browser.close();
console.log(`\nDone! Exported ${total} images to ${outDir}`);
