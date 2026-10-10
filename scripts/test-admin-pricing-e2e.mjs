import { chromium } from "playwright-core";
import { existsSync, readFileSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = "quiz-test@easylearn.dev";
const PASSWORD = "QuizTest2026!";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.SHOT_DIR ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";
const USER_ID = "e3132aff-77e7-409b-a011-4dd524c92c04";

const env = Object.fromEntries(
  readFileSync("D:\\elearning\\.env.local", "utf8")
    .split(/\r?\n/)
    .filter((line) => line.includes("=") && !line.trim().startsWith("#"))
    .map((line) => {
      const i = line.indexOf("=");
      return [line.slice(0, i).trim(), line.slice(i + 1).trim()];
    }),
);
const SB_URL = env.NEXT_PUBLIC_SUPABASE_URL;
const SB_KEY = env.SUPABASE_SERVICE_ROLE_KEY;

async function rest(path, options = {}) {
  const res = await fetch(`${SB_URL}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: SB_KEY,
      Authorization: `Bearer ${SB_KEY}`,
      "content-type": "application/json",
      ...(options.headers ?? {}),
    },
  });
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch {
    /* ignore */
  }
  return { status: res.status, json };
}

let failures = 0;
const check = (label, ok, detail) => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

console.log("0. état propre + promotion admin");
// PostgREST refuse un DELETE sans filtre : on sauvegarde plutôt les deux
// lignes tarifaires que le test va réécrire (elles appartiennent au seed).
const savedPrices = (
  await rest(
    "category_level_prices?category_id=eq.prog&level=in.(intermediaire,avance)",
  )
).json;
await rest(`profiles?id=eq.${USER_ID}`, {
  method: "PATCH",
  body: JSON.stringify({ role: "admin" }),
});

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

try {
  await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });

  // ---- 1. Enregistrement de prix ------------------------------------------
  console.log("\n1. Enregistrer des prix");
  await page.goto(`${BASE}/admin/tarifs`, { waitUntil: "networkidle" });

  const inputProgInter = 'input[name="price:prog:intermediaire"]';
  const inputProgAvance = 'input[name="price:prog:avance"]';
  // Le bouton n'est actif qu'après une modification réelle du formulaire
  // (disabled={!dirty}) : on vide puis on remplit, sinon remplir la même
  // valeur que celle déjà en base ne déclenche aucun change event.
  await page.fill(inputProgInter, "");
  await page.fill(inputProgInter, "28000");
  await page.fill(inputProgAvance, "");
  await page.fill(inputProgAvance, "40000");
  await page.click('button:has-text("Enregistrer les prix")');
  await page.waitForURL(/notice=saved|notice=error/, { timeout: 20000 });

  check(
    "redirect ?notice=saved (pas d'erreur)",
    page.url().includes("notice=saved"),
    page.url(),
  );
  await page.waitForLoadState("networkidle");
  const noticeText = await page.innerText("body");
  check(
    "notice de succès affichée",
    noticeText.includes("Prix enregistrés") ||
      noticeText.includes("enregistré"),
    undefined,
  );
  await page.screenshot({ path: `${OUT}\\pricing-notice.png` });
  console.log("  shot: pricing-notice");
  if (page.url().includes("notice=error")) {
    await page.screenshot({ path: `${OUT}\\pricing-error.png` });
    console.log("  shot: pricing-error");
  }

  const saved = await rest(
    "category_level_prices?select=category_id,level,price_usd&order=level",
  );
  check(
    "2 prix en base (prog / intermediaire=28000, avance=40000)",
    Array.isArray(saved.json) &&
      saved.json.some(
        (r) =>
          r.category_id === "prog" &&
          r.level === "intermediaire" &&
          r.price_usd === 28000,
      ) &&
      saved.json.some(
        (r) => r.category_id === "prog" && r.level === "avance" && r.price_usd === 40000,
      ),
    JSON.stringify(saved.json),
  );

  await page.goto(`${BASE}/admin/tarifs`, { waitUntil: "networkidle" });
  const prefilled = await page.inputValue(inputProgInter);
  check(
    "champ re-pré-rempli après rechargement",
    prefilled === "28000",
    `valeur=${prefilled}`,
  );
  await page.screenshot({ path: `${OUT}\\pricing-saved.png` });
  console.log("  shot: pricing-saved");

  // ---- 2. Vidage des prix (clear) ------------------------------------------
  console.log("\n2. Vider un prix");
  await page.fill(inputProgInter, "");
  await page.click('button:has-text("Enregistrer les prix")');
  await page.waitForURL(/notice=saved|notice=error/, { timeout: 20000 });
  check(
    "clear enregistré (?notice=saved)",
    page.url().includes("notice=saved"),
    page.url(),
  );

  const cleared = await rest(
    "category_level_prices?select=category_id,level&category_id=eq.prog",
  );
  check(
    "ligne intermediaire supprimée (avance conservée)",
    Array.isArray(cleared.json) &&
      !cleared.json.some((r) => r.level === "intermediaire") &&
      cleared.json.some((r) => r.level === "avance"),
    JSON.stringify(cleared.json),
  );
} catch (error) {
  console.error("ERREUR:", error.message);
  failures += 1;
  await page
    .screenshot({ path: `${OUT}\\pricing-crash.png` })
    .catch(() => undefined);
} finally {
  await browser.close();
}

console.log("\n3. cleanup");
await rest(`profiles?id=eq.${USER_ID}`, {
  method: "PATCH",
  body: JSON.stringify({ role: "learner" }),
});
const wipePrices = await rest(
  "category_level_prices?category_id=eq.prog&level=in.(intermediaire,avance)",
  { method: "DELETE" },
);
if (Array.isArray(savedPrices) && savedPrices.length > 0) {
  const restore = await rest("category_level_prices", {
    method: "POST",
    body: JSON.stringify(savedPrices),
  });
  console.log(
    `  prix d'origine restaurés : ${restore.status === 201 ? "ok" : restore.status} (${savedPrices.length} ligne(s))`,
  );
} else {
  console.log(`  lignes de test supprimées : ${wipePrices.status}`);
}
console.log("  rôle restauré + prix restitués");

console.log(
  failures === 0
    ? "\n=== TARIFS ADMIN : TOUS LES TESTS PASSENT ==="
    : `\n=== ${failures} ÉCHEC(S) ===`,
);
process.exit(failures === 0 ? 0 : 1);
