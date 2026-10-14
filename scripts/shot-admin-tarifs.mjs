import { chromium } from "playwright-core";
import { existsSync, readFileSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = "quiz-test@easylearn.dev";
const PASSWORD = (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";
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
  return { status: res.status, body: await res.text() };
}

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}

console.log("0. promotion temporaire admin");
const promote = await rest(`profiles?id=eq.${USER_ID}`, {
  method: "PATCH",
  body: JSON.stringify({ role: "admin" }),
});
console.log("  PATCH role=admin:", promote.status);

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
let failures = 0;
const check = (label, ok, detail) => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

try {
  await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });

  await page.goto(`${BASE}/admin/tarifs`, { waitUntil: "networkidle" });
  const text = await page.innerText("body");
  check("page /admin/tarifs rendue", page.url().includes("/admin/tarifs"), page.url());
  check("titre tarifs", text.includes("Tarifs") || text.includes("tarif"), text.slice(0, 120));
  check(
    "état 'table absente' disparu (migration collée)",
    !text.includes("202610030001"),
    undefined,
  );
  check("colonne Débutant = Gratuit", text.includes("Gratuit"));
  check("domaine Programmation présent", text.includes("Programmation"));
  await page.screenshot({ path: `${OUT}\\admin-tarifs.png` });
  console.log("  shot: admin-tarifs");
} catch (error) {
  console.error("ERREUR:", error.message);
  failures += 1;
} finally {
  await browser.close();
}

console.log("restauration role=learner");
const demote = await rest(`profiles?id=eq.${USER_ID}`, {
  method: "PATCH",
  body: JSON.stringify({ role: "learner" }),
});
console.log("  PATCH role=learner:", demote.status);

console.log(failures === 0 ? "\nADMIN TARIFS OK" : `\n${failures} ÉCHEC(S)`);
process.exit(failures === 0 ? 0 : 1);
