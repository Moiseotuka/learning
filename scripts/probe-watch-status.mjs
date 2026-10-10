import { chromium } from "playwright-core";

const ids = process.argv.slice(2);

const run = async () => {
  const browser = await chromium.launchPersistentContext(
    "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\yt-fresh-profile",
    { executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", headless: false, viewport: { width: 1100, height: 700 } },
  );
  const page = browser.pages()[0] ?? (await browser.newPage());
  page.setDefaultTimeout(45000);

  for (const id of ids) {
    try {
      await page.goto(`https://www.youtube.com/watch?v=${id}`, { waitUntil: "domcontentloaded" });
      await page.waitForTimeout(6000);
      const t = (await page.locator("body").innerText()).replace(/\s+/g, " ");
      let verdict = "INCONNU";
      if (/vérifiez que vous n'êtes pas un robot|confirm you're not a bot|Sign in to confirm/i.test(t)) verdict = "BOT-CHECK";
      else if (/video unavailable|vidéo indisponible|n'est plus disponible|This video is unavailable/i.test(t)) verdict = "MORTE";
      else if (/interdit dans votre pays|not available in your country/i.test(t)) verdict = "GEO-BLOCK";
      else if (await page.locator("video").count()) verdict = "LISIBLE (element video présent)";
      console.log(`${id} => ${verdict} | extrait: ${t.slice(0, 180)}`);
      await page.screenshot({ path: `C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\watch-${id}.png` });
    } catch (e) {
      console.log(`${id} => ERREUR ${e.message.slice(0, 120)}`);
    }
  }
  await browser.close();
};

run().catch((e) => { console.error("ERREUR:", e.message); process.exit(1); });
