/**
 * Vérification du bouton « Certificat de test » (page Profil, compte test) :
 * bouton visible → clic → téléchargement du PDF → capture de la page.
 */
import { chromium } from "playwright-core";
import { existsSync, readFileSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? "QuizTest2026!";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.TEMP ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

let failures = 0;
const check = (label, ok, detail = "") => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
  page.on("download", (d) => {
    console.log("  [download] démarré :", d.url());
    d.failure().then((f) => console.log("  [download] failure :", f));
  });
  page.on("requestfailed", (r) =>
    console.log("  [requestfailed]", r.url(), r.failure()?.errorText),
  );
  page.on("request", (r) => {
    if (r.url().includes("certificats")) {
      console.log("  [request]", r.method(), r.url());
      console.log("     headers:", JSON.stringify(r.headers()));
    }
  });
  page.on("response", async (r) => {
    if (r.url().includes("certificats")) {
      console.log("  [response]", r.status(), r.url());
      try {
        console.log("     headers:", JSON.stringify(await r.allHeaders()));
      } catch {
        void 0;
      }
    }
  });

  console.log("\n1. Connexion + page Profil");
  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  await page.goto(`${BASE}/app/profil`, { waitUntil: "networkidle" });
  const main = await page.innerText("main");
  const lower = main.toLowerCase();
  check("bouton « Certificat de test » visible", lower.includes("certificat de test"));
  check("bloc démonstration affiché", lower.includes("démonstration"));

  console.log("\n1b. Diagnostic fetch API (session active)");
  const info = await page.evaluate(async () => {
    const probe = async (url, opts) => {
      try {
        const t0 = performance.now();
        const res = await fetch(url, opts);
        const blob = await res.blob();
        const ms = Math.round(performance.now() - t0);
        return `${res.status}/${blob.size}o/${ms}ms/${res.headers.get("content-type") ?? "-"}`;
      } catch (e) {
        return `ERR ${e.message}`;
      }
    };
    return {
      certif: await probe("/api/certificats/PYT-2026-000001?inline=1"),
      certifNoStore: await probe("/api/certificats/PYT-2026-000001?inline=1", {
        cache: "no-store",
      }),
      certifBogus: await probe("/api/certificats/ZZZ-2026-000000"),
      jpg: await probe("/certificat.jpg"),
      svg: await probe("/next.svg"),
      webhook: await probe("/api/webhooks/payment"),
      page: await probe("/verifier?code=AAA-2026-000000"),
      profil: await probe("/app/profil"),
    };
  });
  console.log("  fetch :", JSON.stringify(info, null, 2));
  check("fetch API renvoie un PDF", /^200\/[1-9]/.test(info.certif));

  const context = page.context();
  const cookies = await context.cookies();
  const cookieHeader = cookies.map((c) => `${c.name}=${c.value}`).join("; ");
  const nodeRes = await fetch(
    "http://localhost:3000/api/certificats/PYT-2026-000001",
    { headers: { cookie: cookieHeader } },
  );
  const nodeBuf = await nodeRes.arrayBuffer();
  const nodeHead = String.fromCharCode(...new Uint8Array(nodeBuf.slice(0, 4)));
  console.log(
    "  node+cookies :",
    nodeRes.status,
    nodeBuf.byteLength,
    "octets",
    nodeHead,
  );
  check(
    "requête Node (mêmes cookies) renvoie un PDF",
    nodeRes.status === 200 && nodeHead === "%PDF",
  );

  console.log("\n2. Clic → téléchargement");
  let dl = null;
  try {
    const wait = page.waitForEvent("download", { timeout: 30000 });
    await page.click('button:has-text("Certificat de test")');
    dl = await wait;
    const pdfPath = `${OUT}\\test-cert-button.pdf`;
    await dl.saveAs(pdfPath);
    const head = readFileSync(pdfPath).subarray(0, 4).toString("latin1");
    check("PDF téléchargé", head === "%PDF", `${dl.suggestedFilename()}`);
  } catch (error) {
    check("PDF téléchargé", false, error.message.split("\n")[0]);
    if (dl) console.log("  failure détail :", await dl.failure());
    console.log("  page.url() =", page.url());
    console.log("  texte après clic :", (await page.innerText("body")).slice(0, 300));
  }

  const shot = `${OUT}\\profil-test-button.png`;
  await page.waitForTimeout(500);
  await page.screenshot({ path: shot, fullPage: true });
  console.log("  capture :", shot);
} finally {
  await browser.close();
}

console.log(
  failures === 0
    ? "\n=== BOUTON TEST : OK ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
