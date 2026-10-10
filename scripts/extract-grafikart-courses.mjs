import { chromium } from "playwright-core";

const run = async () => {
  const browser = await chromium.launch({
    executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
    headless: true,
  });
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  await page.goto("https://www.youtube.com/@grafikart/courses", { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(5000);

  // Titres des cours (liens vers playlists)
  const items = await page.evaluate(() => {
    const out = [];
    const anchors = document.querySelectorAll('a#video-title, a[href*="list"], a.yt-lockup-metadata-view-model-wiz__title');
    for (const a of anchors) {
      const t = (a.textContent || "").trim();
      const href = a.getAttribute("href") || "";
      if (t && href.includes("list=")) out.push({ title: t, href });
    }
    return out;
  });
  console.log("found:", items.length);
  const seen = new Set();
  for (const it of items) {
    if (seen.has(it.title)) continue;
    seen.add(it.title);
    const id = (it.href.match(/list=([^&]+)/) || [])[1] || "";
    console.log(`${it.title} | ${id}`);
  }
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
