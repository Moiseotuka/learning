import { chromium } from "playwright-core";

const EDGE = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const track = "http://localhost:3000/app/parcours/developpement-web-moderne";

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  await page.goto("http://localhost:3000/connexion", { waitUntil: "domcontentloaded" });
  await page.fill("#email", "quiz-test@easylearn.dev");
  await page.fill("#password", (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD"));
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", { timeout: 20000 });

  await page.goto(track, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1500);
  const body = await page.innerText("body");
  const titles = [
    "HTML sémantique",
    "CSS moderne",
    "JavaScript et DOM",
    "JavaScript applicatif",
    "Git et npm",
    "React : composants",
    "React avancé",
    "Projet : du design",
  ];
  const missing = titles.filter((t) => !body.includes(t));
  console.log("sidebar — 8 chapitres:", missing.length === 0 ? "OK" : `MANQUANTS ${missing.join(" | ")}`);
  console.log(
    "compteurs visibles:",
    body.includes("16") || body.includes("17") ? "OK" : "KO",
  );

  const samples = [
    { id: "css-mise-en-page", code: "2.2.1", quiz: true },
    { id: "javascript-dom", code: "3.2.1", quiz: true },
    { id: "git-npm", code: "5.2.1", quiz: true },
    { id: "react-fondamentaux", code: "6.2.1", quiz: true },
    { id: "projet-web", code: "8.2.1", quiz: true },
  ];
  for (const s of samples) {
    const base = `${track}/chapitres/${s.id}`;
    await page.goto(`${base}?etape=cours`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    const txt = await page.innerText("body");
    const codeOk = txt.includes(s.code);
    const pagesOk = /Page \d+ sur 1[67]/.test(txt);
    await page.goto(`${base}/quiz`, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(1200);
    const radios = await page.locator("input[type=radio]").count();
    console.log(
      `${s.id} — code ${s.code}: ${codeOk ? "OK" : "KO"} | pagination: ${pagesOk ? "OK" : "KO"} | quiz radios: ${radios}`,
    );
  }

  await page.goto(`${track}/chapitres/react-applications?etape=exercice`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1200);
  console.log("react-applications exercice — éditeur:", await page.locator(".cm-editor").count());
  await page.goto(`${track}/chapitres/css-mise-en-page?etape=ressources`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(1200);
  const rTxt = await page.innerText("main");
  console.log("css ressources — MDN:", rTxt.includes("MDN"), "| web.dev:", rTxt.includes("web.dev"));
} finally {
  await browser.close();
}
