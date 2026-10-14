import { chromium } from "playwright-core";
import { createHmac } from "node:crypto";
import { existsSync, mkdirSync, readFileSync } from "node:fs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? (process.env.QUIZ_TEST_PASSWORD ?? "définir QUIZ_TEST_PASSWORD");
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
const OUT =
  process.env.SHOT_DIR ?? "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";

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
const PROVIDER = env.PAYMENT_PROVIDER ?? "mock";
const NYOLE_SECRET = env.NYOLE_SECRET_KEY ?? "";

let failures = 0;
const check = (label, ok, detail) => {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
};

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

const CATEGORY = "prog";
const LEVEL = "intermediaire";
const TRACK = "python-developpeur";
const CH_LEVEL2 = "fichiers";
const USER_ID = "e3132aff-77e7-409b-a011-4dd524c92c04";
const BEGINNER_CHAPTERS = [
  "premiers-pas-variables",
  "conditions-boucles",
  "fonctions",
  "listes-dictionnaires",
];

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE);
  process.exit(1);
}
mkdirSync(OUT, { recursive: true });

const shot = async (page, name) => {
  const path = `${OUT}\\${name}.png`;
  await page.screenshot({ path });
  console.log("  shot:", name);
};

// ---- Setup : prix de test + état propre ----------------------------------
console.log("\n0. Setup (prix + état)");
const savedProgress = (
  await rest(`chapter_progress?user_id=eq.${USER_ID}`)
).json;
console.log(`  progressions sauvegardées : ${savedProgress?.length ?? "?"}`);
const savedExams = (await rest(`level_exams?user_id=eq.${USER_ID}`)).json;
await rest(`chapter_progress?user_id=eq.${USER_ID}`, { method: "DELETE" });
await rest(`level_exams?user_id=eq.${USER_ID}`, { method: "DELETE" });
await rest(`purchases?user_id=eq.${USER_ID}`, {
  method: "DELETE",
});
await rest("payment_events?event_id=not.is.null", { method: "DELETE" });
// Le prix « prog / intermédiaire » appartient au jeu de données : on le
// sauvegarde avant de le remplacer, pour le restaurer en fin de test.
const savedPrice = (
  await rest(
    `category_level_prices?category_id=eq.${CATEGORY}&level=eq.${LEVEL}`,
  )
).json;
const delPrice = await rest(
  `category_level_prices?category_id=eq.${CATEGORY}&level=eq.${LEVEL}`,
  { method: "DELETE" },
);
console.log(`  nettoyage prix : ${delPrice.status}`);
const insPrice = await rest("category_level_prices", {
  method: "POST",
  body: JSON.stringify({ category_id: CATEGORY, level: LEVEL, price_usd: 28000 }),
});
check(
  "prix de test inséré (prog / intermédiaire / 28000 CDF)",
  insPrice.status === 201,
  `status ${insPrice.status}`,
);

const chapterIds = Object.fromEntries(
  (
    (
      await rest(
        "chapters?select=id,slug&track_id=eq.python-developpeur",
      )
    ).json ?? []
  ).map((row) => [row.slug, row.id]),
);
const chapterResourceRows =
  (
    await rest("chapters?select=slug,resources&track_id=eq.python-developpeur")
  ).json ?? [];
const labelsOf = (slug) =>
  (chapterResourceRows.find((row) => row.slug === slug)?.resources ?? []).map(
    (resource) => resource.label,
  );
const lockedLabels = labelsOf(CH_LEVEL2);
const openLabels = labelsOf("premiers-pas-variables");
const completedRows = BEGINNER_CHAPTERS.map((slug) => ({
  user_id: USER_ID,
  chapter_id: chapterIds[slug],
  track_id: "python-developpeur",
  attempts: 1,
  best_score: 100,
  status: "completed",
  completed_at: new Date().toISOString(),
}));
const insProgress = await rest("chapter_progress", {
  method: "POST",
  body: JSON.stringify(completedRows),
});
check(
  "fixture : 4 chapitres débutant complétés (chapitre intermédiaire atteignable)",
  insProgress.status === 201,
  `status ${insProgress.status}`,
);

// L'examen de fin de niveau conditionne l'accès au niveau suivant : le test
// paiement se concentre sur le paywall, l'examen est donc une fixture.
const insExam = await rest("level_exams", {
  method: "POST",
  body: JSON.stringify([
    {
      user_id: USER_ID,
      track_id: TRACK,
      level: "debutant",
      attempts: 1,
      best_score: 100,
      status: "passed",
      passed_at: new Date().toISOString(),
    },
  ]),
});
check(
  "fixture : examen de fin de niveau réussi (niveau suivant ouvert)",
  insExam.status === 201,
  `status ${insExam.status}`,
);

const browser = await chromium.launch({ executablePath: EDGE, headless: true });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

try {
  // ---- 1. Dashboard : filtre des modules non achetés ----------------------
  console.log("\n1. Dashboard = seuls modules accessibles");
  await page.goto(`${BASE}/connexion`, { waitUntil: "networkidle" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  await page.goto(`${BASE}/app`, { waitUntil: "networkidle" });
  const dash = await page.innerText("main");
  check("module débutant présent (python)", dash.includes("Premiers pas en Python"));
  check(
    "module intermédiaire non payé masqué (réseaux)",
    !dash.includes("protocoles, routage et supervision"),
  );
  check(
    "module intermédiaire non payé masqué (ia/data)",
    !dash.includes("Intelligence artificielle et Data Science appliquées"),
  );
  await shot(page, "pay-01-dashboard-filtre");

  // ---- 2. Avant achat : chapitre de niveau intermédiaire verrouillé ------
  console.log("\n2. Avant achat");
  await page.goto(`${BASE}/app/parcours/${TRACK}`, { waitUntil: "networkidle" });
  const trackView = await page.innerText("main");
  check(
    "bandeau d'achat niveau(s) verrouillé(s)",
    trackView.includes("Ce niveau n'est pas encore débloqué") &&
      trackView.includes("Intermédiaire"),
  );
  check("prix affiché sur le CTA", trackView.includes("28000 CDF"));
  await shot(page, "pay-02-parcours-bandeau");

  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LEVEL2}`,
    { waitUntil: "networkidle" },
  );
  const locked = await page.innerText("main");
  check("chapitre intermédiaire → écran Niveau verrouillé", locked.includes("Niveau verrouillé"));
  await shot(page, "pay-03-chapitre-verrouille");

  // Verrou strict : aucune porte dérobée vers le contenu d'un niveau non payé.
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LEVEL2}/quiz`,
    { waitUntil: "networkidle" },
  );
  const lockedQuiz = await page.innerText("main");
  check(
    "quiz du niveau non payé → verrou (aucune question servie)",
    lockedQuiz.includes("niveau payant") &&
      (await page.locator("form fieldset").count()) === 0,
  );
  await shot(page, "pay-03b-quiz-verrouille");

  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LEVEL2}/tutoriel`,
    { waitUntil: "networkidle" },
  );
  const lockedTutorial = await page.innerText("main");
  check(
    "tutoriel du niveau non payé → chapitre verrouillé",
    lockedTutorial.includes("Niveau verrouillé"),
  );

  await page.goto(`${BASE}/app/parcours/${TRACK}`, {
    waitUntil: "networkidle",
  });
  await page.locator('[role="tab"]', { hasText: "Ressources" }).click();
  const lockedSidebar = await page.locator("aside").innerText();
  check(
    "ressources du niveau non payé masquées (onglet Ressources)",
    lockedLabels.length > 0 &&
      lockedLabels.every((label) => !lockedSidebar.includes(label)),
    `${lockedLabels.length} ressources`,
  );
  check(
    "ressources du niveau gratuit toujours visibles",
    openLabels.length > 0 &&
      openLabels.some((label) => lockedSidebar.includes(label)),
  );
  check(
    "sidebar : chapitre du niveau non payé sans lien",
    (await page.locator('aside a[href*="chapitres/fichiers"]').count()) === 0,
  );
  await shot(page, "pay-03c-ressources-verrouillees");

  // ---- 3. Achat via /app/acheter ------------------------------------------
  console.log(`\n3. Achat (provider=${PROVIDER})`);
  await page.goto(
    `${BASE}/app/acheter?cat=${CATEGORY}&level=${LEVEL}`,
    { waitUntil: "networkidle" },
  );
  const buy = await page.innerText("main");
  check("récap domaine", buy.includes("Programmation"));
  check("récap niveau", buy.includes("Intermédiaire"));
  check("récap prix", buy.includes("28000 CDF"));
  check(
    "mention du mode de paiement",
    PROVIDER === "nyole" ? buy.includes("nyole") : buy.includes("simulé"),
    `provider=${PROVIDER}`,
  );
  await shot(page, "pay-04-acheter");

  if (PROVIDER === "nyole") {
    // --- nyole : la page de paiement s'ouvre dans une boîte de dialogue -----
    check(
      "clé secrète nyole configurée",
      NYOLE_SECRET.startsWith("af_"),
      NYOLE_SECRET ? "af_…" : "absente",
    );

    await page.click('button[type="submit"]');
    await page.waitForSelector(
      'div[role="dialog"] iframe[src^="https://app.nyole.com/checkout/"]',
      { timeout: 20000 },
    );
    const iframeSrc = await page.getAttribute(
      'div[role="dialog"] iframe',
      "src",
    );
    check(
      "page de paiement nyole chargée dans un dialogue",
      Boolean(iframeSrc?.startsWith("https://app.nyole.com/checkout/")),
      iframeSrc,
    );
    check(
      "l'apprenant reste sur easyLearn (URL inchangée)",
      new URL(page.url()).pathname === "/app/acheter",
      page.url(),
    );
    await shot(page, "pay-04b-dialogue-nyole");

    let purchase = null;
    for (let i = 0; i < 20 && !purchase; i += 1) {
      const rows = await rest(
        `purchases?select=id,status,provider,provider_reference,amount_usd,currency&user_id=eq.${USER_ID}&category_id=eq.${CATEGORY}&level=eq.${LEVEL}`,
      );
      purchase =
        (rows.json ?? []).find((row) => row.provider_reference) ?? null;
      if (!purchase) await new Promise((resolve) => setTimeout(resolve, 500));
    }
    check(
      "purchase créée (pending, session nyole)",
      Boolean(purchase) &&
        purchase.status === "pending" &&
        purchase.provider === "nyole" &&
        Boolean(purchase.provider_reference),
      JSON.stringify(purchase),
    );
    check(
      "montant purchase en base (28000 CDF)",
      purchase?.amount_usd === 28000 && purchase?.currency === "CDF",
      JSON.stringify({
        amount_usd: purchase?.amount_usd,
        currency: purchase?.currency,
      }),
    );
    if (!purchase) {
      throw new Error("purchase nyole introuvable après ouverture du dialogue");
    }

    const sessionId = purchase?.provider_reference ?? "";

    // Régression « montant ×100 » : nyole veut l'unité principale (28000,
    // pas 2 800 000) — sinon la page hébergée afficherait un montant 100×
    // trop élevé.
    const nyoleStatusRes = await fetch(
      `https://app.nyole.com/api/v1/checkout/sessions/${encodeURIComponent(sessionId)}/status`,
      { headers: { Authorization: `Bearer ${NYOLE_SECRET}` } },
    );
    const nyoleStatus = await nyoleStatusRes.json().catch(() => null);
    check(
      "session nyole : montant en unités CDF (28000)",
      nyoleStatusRes.status === 200 &&
        nyoleStatus?.amount === 28000 &&
        nyoleStatus?.currency === "CDF",
      JSON.stringify({
        amount: nyoleStatus?.amount,
        currency: nyoleStatus?.currency,
      }),
    );

    // La page peut convertir vers la devise locale ; on lit le montant brut
    // (« 28 000 CDF ») après avoir déplié le bloc « Détails » (replié dans
    // l'iframe étroite). On compare sans espaces : séparateurs de milliers et
    // espaces insécables disparaissent ainsi.
    const nyoleFrame = page.frameLocator('div[role="dialog"] iframe');
    try {
      await nyoleFrame
        .getByText("Détails", { exact: true })
        .first()
        .click({ timeout: 8000 });
    } catch {
      /* déjà déplié */
    }
    let nyoleText = "";
    let nyoleFlat = "";
    const amountDeadline = Date.now() + 30000;
    while (Date.now() < amountDeadline) {
      try {
        nyoleText = await nyoleFrame.locator("body").innerText({ timeout: 5000 });
        nyoleFlat = nyoleText.replace(/\s/g, "");
        if (nyoleFlat.includes("28000")) break;
      } catch {
        /* iframe pas encore montée : on retente */
      }
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
    const amountLine = nyoleText
      .split("\n")
      .map((line) => line.replace(/[\u00a0\u202f]/g, " ").trim())
      .find((line) => /28\s?000/.test(line));
    check(
      "page nyole affiche le prix paramétré (28000 CDF)",
      nyoleFlat.includes("28000") && /CDF|Fc/i.test(nyoleText),
      amountLine ??
        nyoleText.split("\n").slice(0, 12).join(" | ").slice(0, 300) ??
        "(page nyole vide)",
    );
    await shot(page, "pay-04c-dialogue-montant");
    const status = await page.evaluate(async (id) => {
      const res = await fetch(
        `/api/payments/status?purchase=${encodeURIComponent(id)}`,
        { cache: "no-store" },
      );
      return {
        status: res.status,
        body: await res.json().catch(() => null),
      };
    }, purchase.id);
    check(
      "endpoint statut : authentifié, achat non payé (PENDING)",
      status.status === 200 &&
        status.body?.ok === true &&
        status.body?.paid === false &&
        status.body?.status === "PENDING",
      JSON.stringify(status.body),
    );
    check(
      "dialogue toujours ouvert (aucune confirmation prématurée)",
      (await page.locator('div[role="dialog"]').count()) > 0,
    );

    const badHook = await fetch(`${BASE}/api/webhooks/payment`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "X-Afriflow-Timestamp": String(Math.floor(Date.now() / 1000)),
        "X-Afriflow-Signature": "t=1,v1=deadbeef",
      },
      body: JSON.stringify({
        event: "payment.completed",
        data: { id: sessionId, status: "SUCCESS" },
      }),
    });
    check(
      "webhook nyole : signature invalide refusée (401)",
      badHook.status === 401,
      `status ${badHook.status}`,
    );

    const pollStatus = async (id, predicate, timeoutMs = 30000) => {
      const started = Date.now();
      let last = null;
      while (Date.now() - started < timeoutMs) {
        last = await page.evaluate(async (pid) => {
          const res = await fetch(
            `/api/payments/status?purchase=${encodeURIComponent(pid)}`,
            { cache: "no-store" },
          );
          return {
            http: res.status,
            body: await res.json().catch(() => null),
          };
        }, id);
        if (predicate(last?.body)) return last;
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
      return last;
    };

    const settle = async (session, issue) => {
      const res = await fetch("https://app.nyole.com/api/checkout/sandbox", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ transactionId: session, issue }),
      });
      const text = await res.text();
      return { ok: res.ok, status: res.status, detail: text.slice(0, 160) };
    };

    const sendWebhook = async (session) => {
      const hookBody = JSON.stringify({
        event: "payment.completed",
        livemode: !NYOLE_SECRET.startsWith("af_test_"),
        data: {
          id: session,
          order_id: "TEST-E2E",
          status: "SUCCESS",
          amount: 28000,
          currency: "CDF",
          provider: "easylearn-e2e",
          provider_reference: "e2e_ref",
          metadata: {
            purchase_id: purchase.id,
            user_id: USER_ID,
            category_id: CATEGORY,
            level: LEVEL,
          },
          completed_at: new Date().toISOString(),
        },
        timestamp: new Date().toISOString(),
      });
      const ts = Math.floor(Date.now() / 1000).toString();
      const v1 = createHmac("sha256", NYOLE_SECRET)
        .update(`${ts}.${hookBody}`)
        .digest("hex");
      const res = await fetch(`${BASE}/api/webhooks/payment`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "X-Afriflow-Timestamp": ts,
          "X-Afriflow-Signature": `t=${ts},v1=${v1}`,
        },
        body: hookBody,
      });
      return {
        status: res.status,
        json: await res.json().catch(() => null),
      };
    };

    if (NYOLE_SECRET.startsWith("af_test_")) {
      // --- Mode test : échec simulé, puis nouvelle tentative et succès ------
      const failed = await settle(sessionId, "echec");
      check(
        "sandbox nyole : échec simulé accepté",
        failed.ok,
        `${failed.status} ${failed.detail}`,
      );
      const afterFail = await pollStatus(
        purchase.id,
        (body) => body?.status === "FAILED",
      );
      check(
        "échec → statut FAILED, achat toujours non payé",
        afterFail?.body?.status === "FAILED" &&
          afterFail?.body?.paid === false,
        JSON.stringify(afterFail?.body),
      );
      check(
        "dialogue toujours ouvert après échec",
        (await page.locator('div[role="dialog"]').count()) > 0,
      );
      const failRows = await rest(
        "purchases?select=status&user_id=eq." + USER_ID,
      );
      check(
        "purchase restée pending après l'échec (aucun déblocage)",
        (failRows.json ?? []).some((row) => row.status === "pending") &&
          !(failRows.json ?? []).some((row) => row.status === "paid"),
        JSON.stringify(failRows.json),
      );

      // Nouvelle tentative : session échouée remplacée par une session neuve.
      await page.click('[data-testid="checkout-close"]');
      await page.waitForSelector('div[role="dialog"]', {
        state: "detached",
        timeout: 10000,
      });
      await page.click('button[type="submit"]');
      await page.waitForSelector(
        'div[role="dialog"] iframe[src^="https://app.nyole.com/checkout/"]',
        { timeout: 20000 },
      );
      const iframeSrc2 = await page.getAttribute(
        'div[role="dialog"] iframe',
        "src",
      );
      const sessionId2 = (iframeSrc2 ?? "").split("/").pop() ?? "";
      check(
        "nouvelle session créée après l'échec (retry)",
        Boolean(sessionId2) && sessionId2 !== sessionId,
        `${sessionId} → ${sessionId2}`,
      );
      const retryPending = await pollStatus(
        purchase.id,
        (body) => body?.status === "PENDING",
        15000,
      );
      check(
        "statut de la nouvelle session : PENDING",
        retryPending?.body?.status === "PENDING",
        JSON.stringify(retryPending?.body),
      );

      const okSettle = await settle(sessionId2, "succes");
      check(
        "sandbox nyole : succès simulé accepté",
        okSettle.ok,
        `${okSettle.status} ${okSettle.detail}`,
      );
      const paidNow = await pollStatus(
        purchase.id,
        (body) => body?.paid === true,
      );
      check(
        "succès → achat validé par le statut serveur",
        paidNow?.body?.paid === true,
        JSON.stringify(paidNow?.body),
      );

      // Le webhook signé reste accepté (déduplication, déjà payé).
      const hook = await sendWebhook(sessionId2);
      check(
        "webhook nyole : payment.completed accepté (idempotent)",
        hook.status === 200 && hook.json?.ok === true,
        `status ${hook.status} ${JSON.stringify(hook.json)}`,
      );

      await page.waitForURL(/notice=paiement/, { timeout: 45000 });
      check(
        "dialogue fermé après confirmation",
        (await page.locator('div[role="dialog"]').count()) === 0,
      );
    } else {
      // --- Mode production : le webhook signé déclenche la confirmation -----
      const hook = await sendWebhook(sessionId);
      check(
        "webhook nyole : payment.completed accepté",
        hook.status === 200 && hook.json?.ok === true,
        `status ${hook.status} ${JSON.stringify(hook.json)}`,
      );
      await page.waitForURL(/notice=paiement/, { timeout: 30000 });
      check(
        "dialogue fermé après confirmation",
        (await page.locator('div[role="dialog"]').count()) === 0,
      );
    }
  } else {
    await page.click('button[type="submit"]');
    await page.waitForURL(/notice=paiement/, { timeout: 20000 });
  }

  await page.waitForLoadState("networkidle");
  const after = await page.innerText("main");
  check("notice de succès affichée", after.includes("Paiement confirmé"));
  // La bannière reste légitimement affichée tant que `prog/avance` et
  // `prog/projet` sont payants et non achetés, et l'en-tête affiche toujours
  // « à partir de 28000 CDF » : on vérifie la disparition du lien d'achat du
  // niveau acheté, pas celle du bandeau entier ni d'un prix.
  check(
    "CTA d'achat du niveau acheté disparu",
    (await page.locator(`a[href*="level=${LEVEL}"]`).count()) === 0,
  );
  await shot(page, "pay-05-apres-paiement");

  // ---- 4. Après achat : chapitre ouvert + purchase payée ------------------
  console.log("\n4. Après achat");
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LEVEL2}`,
    { waitUntil: "networkidle" },
  );
  const opened = await page.innerText("main");
  check(
    "chapitre intermédiaire accessible",
    !opened.includes("Niveau verrouillé") && !opened.includes("Chapitre verrouillé"),
  );
  check("étape Objectifs rendue", opened.includes("Objectifs"));
  await shot(page, "pay-06-chapitre-ouvert");

  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LEVEL2}/quiz`,
    { waitUntil: "networkidle" },
  );
  const openedQuiz = await page.innerText("main");
  check(
    "quiz du niveau payé : verrou de niveau levé après achat",
    !openedQuiz.includes("niveau payant") &&
      openedQuiz.includes(
        "Regardez toutes les vidéos du chapitre avant de passer le quiz.",
      ),
  );

  await page.goto(`${BASE}/app/parcours/${TRACK}`, {
    waitUntil: "networkidle",
  });
  await page.locator('[role="tab"]', { hasText: "Ressources" }).click();
  const openedSidebar = await page.locator("aside").innerText();
  check(
    "ressources du niveau payé visibles après achat",
    lockedLabels.length > 0 &&
      lockedLabels.every((label) => openedSidebar.includes(label)),
  );
  check(
    "sidebar : chapitre du niveau payé de nouveau lié",
    (await page.locator('aside a[href*="chapitres/fichiers"]').count()) > 0,
  );

  const purchases = await rest(
    "purchases?select=status,level,category_id&user_id=eq.e3132aff-77e7-409b-a011-4dd524c92c04",
  );
  check(
    "purchase en base (status=paid)",
    Array.isArray(purchases.json) &&
      purchases.json.some(
        (p) => p.status === "paid" && p.level === LEVEL && p.category_id === CATEGORY,
      ),
    JSON.stringify(purchases.json),
  );
} finally {
  await browser.close();
}

// ---- Cleanup : restaure l'état exact d'avant test -------------------------
console.log("\n5. Cleanup");
await rest(`chapter_progress?user_id=eq.${USER_ID}`, { method: "DELETE" });
if (Array.isArray(savedProgress) && savedProgress.length > 0) {
  const restore = await rest("chapter_progress", {
    method: "POST",
    body: JSON.stringify(savedProgress),
  });
  console.log(
    `  progressions restaurées : ${restore.status === 201 ? "ok" : restore.status} (${savedProgress.length} ligne(s))`,
  );
}
await rest(`level_exams?user_id=eq.${USER_ID}`, { method: "DELETE" });
if (Array.isArray(savedExams) && savedExams.length > 0) {
  const restoreExams = await rest("level_exams", {
    method: "POST",
    body: JSON.stringify(savedExams),
  });
  console.log(
    `  examens restaurés : ${restoreExams.status === 201 ? "ok" : restoreExams.status} (${savedExams.length} ligne(s))`,
  );
}
await rest(`purchases?user_id=eq.${USER_ID}`, {
  method: "DELETE",
});
await rest("payment_events?event_id=not.is.null", { method: "DELETE" });
const clean = await rest(
  `category_level_prices?category_id=eq.${CATEGORY}&level=eq.${LEVEL}`,
  { method: "DELETE" },
);
console.log(`  prix de test supprimés : ${clean.status === 204 ? "ok" : clean.status}`);
if (Array.isArray(savedPrice) && savedPrice.length > 0) {
  const restorePrice = await rest("category_level_prices", {
    method: "POST",
    body: JSON.stringify(savedPrice[0]),
  });
  console.log(
    `  prix d'origine restauré : ${restorePrice.status === 201 ? "ok" : restorePrice.status}`,
  );
}

console.log(
  failures === 0
    ? "\n=== PAIEMENT E2E : TOUS LES TESTS PASSENT ==="
    : `\n=== ${failures} ÉCHEC(S) ===`,
);
process.exit(failures === 0 ? 0 : 1);
