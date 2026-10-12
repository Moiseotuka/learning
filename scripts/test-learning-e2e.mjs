/**
 * Test E2E du parcours chapitre unifié (headless, Edge système).
 *
 * Déroulé : login → sidebar type NetAcad (sections de niveau avec barre +
 * %, lignes de chapitre avec compteur x / y, timeline d'étapes repliable) →
 * étape par défaut Objectifs → anti-skip (playlist bloquée + étape suivante
 * désactivée) → gate document (?etape=cours bloqué ou accepté selon l'ordre
 * du jour Vidéos/Cours) → gate quiz → setup videos_watched (service role) →
 * navigation complète des étapes dans l'ordre affiché → reprise de l'étape
 * via la sidebar → quiz accessible → chapitre verrouillé en URL directe
 * (dont /tutoriel).
 *
 * Usage : npm run test:learning
 * Prérequis : serveur dev sur BASE_URL + migrations Phase A collées
 * (202610020001_video_watch.sql puis 202610020002_level_exams.sql)
 * Compte de test : env QUIZ_TEST_EMAIL / QUIZ_TEST_PASSWORD
 */
import { chromium } from "playwright-core";
import { existsSync } from "node:fs";

import {
  markChapterVideosWatched,
  resetChapterVideosWatched,
  serviceEnv,
} from "./e2e-setup.mjs";

const BASE = process.env.QUIZ_TEST_BASE ?? "http://localhost:3000";
const EMAIL = process.env.QUIZ_TEST_EMAIL ?? "quiz-test@easylearn.dev";
const PASSWORD = process.env.QUIZ_TEST_PASSWORD ?? "QuizTest2026!";
const EDGE =
  process.env.QUIZ_TEST_BROWSER ??
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

const TRACK = "python-developpeur";
const CH1 = "premiers-pas-variables";
const CH_LOCKED = "projet-analyseur-notes";

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

let failures = 0;
function check(label, ok, detail = "") {
  console.log(`  ${ok ? "✓" : "✗"} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures += 1;
}

/** innerText renvoie le texte visualisé (souvent en MAJUSCULES via CSS
 *  `uppercase`) : les comparaisons de contenu se font insensibles à la casse. */
function includesCI(haystack, needle) {
  return haystack.toLowerCase().includes(needle.toLowerCase());
}

if (!existsSync(EDGE)) {
  console.error("Navigateur introuvable :", EDGE, "(définir QUIZ_TEST_BROWSER)");
  process.exit(1);
}

const browser = await chromium.launch({ executablePath: EDGE, headless: true });

try {
  const page = await browser.newPage();

  /** Sur une étape Cours paginée, avance jusqu'à la dernière page. */
  const exhaustPages = async () => {
    // Reprise PageResume (rechargement document) : attendre &page=N.
    if (
      /etape=cours/.test(page.url()) &&
      !/[?&]page=\d+/.test(page.url())
    ) {
      await page
        .waitForURL(/page=\d+/, { timeout: 15000 })
        .catch(() => null);
    }
    for (let guard = 0; guard < 40; guard += 1) {
      if (
        (await page.locator('main a:has-text("Étape suivante")').count()) > 0
      ) {
        return;
      }
      const nextPage = page.locator('main a:has-text("Page suivante")');
      if ((await nextPage.count()) === 0) return;
      await nextPage.click();
      await page
        .waitForURL(/page=\d+/, { timeout: 10000 })
        .catch(() => null);
    }
  };

  console.log("\n1. Connexion");
  await page.goto(`${BASE}/connexion`, { waitUntil: "domcontentloaded" });
  await page.fill("#email", EMAIL);
  await page.fill("#password", PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL((url) => url.pathname === "/", {
    timeout: 20000,
  });
  check("redirigé vers la landing page (avant navigation)", true);

  // Migration 202610040004_chapter_pages.sql (pages numérotées du Cours) ?
  const { url: sbUrl, key: sbKey } = serviceEnv();
  const pagesReady = sbUrl
    ? await fetch(`${sbUrl}/rest/v1/chapter_pages?select=id&limit=1`, {
        headers: { apikey: sbKey, Authorization: `Bearer ${sbKey}` },
      })
        .then((response) => response.ok)
        .catch(() => false)
    : false;
  console.log(
    pagesReady
      ? "   chapter_pages : migration collée (sections pages activées)"
      : "   chapter_pages : migration absente — sections pages ignorées",
  );

  console.log("\n2. Sidebar unifiée — plus d'onglets Tutoriel/Documents");
  await page.goto(`${BASE}/app/parcours/${TRACK}`, {
    waitUntil: "domcontentloaded",
  });
  const asideTabs = await page.locator('aside [role="tab"]').allInnerTexts();
  check(
    "sous-onglets Chapitres / Ressources présents",
    asideTabs.some((label) => /chapitres/i.test(label)) &&
      asideTabs.some((label) => /ressources/i.test(label)),
    asideTabs.join(" | ") || "aucun",
  );
  check(
    "plus d'onglet Tutoriel / Documents",
    !asideTabs.some((label) => /tutoriel|documents/i.test(label)),
  );
  check(
    "sections de niveau (h3) dans la sidebar",
    (await page.locator("aside h3").count()) >= 1,
  );
  check(
    "barres de progression par niveau + pied de sidebar",
    (await page.locator('aside [role="progressbar"]').count()) >= 2,
  );
  check(
    "chevrons de dépliage présents",
    (await page.locator("aside button[aria-expanded]").count()) >= 1,
  );
  const ch1Row = page
    .locator(`aside a[href$="/chapitres/${CH1}"]`)
    .first();
  const rowText = await ch1Row.innerText();
  check(
    "ligne de chapitre avec compteur x / y",
    /\d+ \/ \d+/.test(rowText),
    rowText.replace(/\n/g, " ").slice(0, 60),
  );
  check(
    "séparateurs entre les niveaux (border-t)",
    await page.evaluate(() => {
      const groups = [...document.querySelectorAll("aside h3")].map(
        (h3) => h3.parentElement?.parentElement,
      );
      return groups.some(
        (group) =>
          group && getComputedStyle(group).borderTopWidth !== "0px",
      );
    }),
  );
  check(
    "bouton 'Voir le tutoriel' retiré de la vue parcours",
    (await page.locator('a:has-text("Voir le tutoriel")').count()) === 0,
  );

  await ch1Row.click();
  await page.waitForURL(new RegExp(`/chapitres/${CH1}$`), { timeout: 20000 });
  check("ouverture du chapitre 1", true);

  console.log("\n3. Objectifs d'abord, puis vidéos anti-skip");
  const reset = await resetChapterVideosWatched({
    email: EMAIL,
    chapterId: "py-c1",
  });
  check(
    "reset videos_watched (fixture)",
    reset.ok,
    reset.ok
      ? `${reset.rows ?? 0} ligne(s)`
      : `${reset.reason}${reset.detail ? ` — ${reset.detail}` : ""}`,
  );

  const timeline = page
    .locator('aside ol[aria-label*="Étapes du chapitre"]')
    .first();
  await timeline.waitFor({ timeout: 20000 });
  const videosStep = timeline
    .locator("a")
    .filter({ hasText: /le[çc]ons vid[ée]o|vid[ée]os/i })
    .first();
  check(
    "timeline sidebar : 6 étapes (Objectifs + Leçons vidéo + 3 étapes + quiz)",
    (await timeline.locator("a").count()) === 6,
  );
  const stepLabels = await timeline
    .locator("a")
    .evaluateAll((links) => links.map((a) => (a.textContent ?? "").trim()));
  const stepKeysObserved = stepLabels.map((label) => {
    if (/objectifs/i.test(label)) return "objectifs";
    if (/vid[ée]o/i.test(label)) return "videos";
    if (/exercice/i.test(label)) return "exercice";
    if (/ressources/i.test(label)) return "ressources";
    if (/quiz/i.test(label)) return "quiz";
    if (/cours/i.test(label)) return "cours";
    return label;
  });
  const coursFirst =
    stepKeysObserved.indexOf("cours") < stepKeysObserved.indexOf("videos");
  console.log(`   ordre du jour : ${stepKeysObserved.join(" → ")}`);
  check(
    "étape par défaut Objectifs (aria-current=step)",
    includesCI(
      await page.locator('aside [aria-current="step"]').first().innerText(),
      "Objectifs",
    ),
  );
  check(
    "contenu Objectifs affiché dans main",
    includesCI(await page.innerText("main"), "Objectifs du chapitre"),
  );

  await videosStep.click();
  await page.waitForURL(/\?etape=videos$/, { timeout: 20000 });
  check("ouverture de l'étape Leçons vidéo via la sidebar", true);

  await page.waitForSelector("main iframe", { timeout: 20000 });
  check(
    "iframe vidéo affiché",
    (await page.locator("main iframe").count()) >= 1,
  );
  check(
    "progression vidéos 0 / 3",
    includesCI(await page.innerText("main"), "0 / 3 leçons terminées"),
  );
  const playlistButtons = page.locator("main ul li button");
  const playlistCount = await playlistButtons.count();
  check(
    "playlist du chapitre (3 vidéos)",
    playlistCount === 3,
    `${playlistCount} vidéos`,
  );

  const titleBefore = await page
    .innerText('main p:has-text("en cours") + h2')
    .catch(() => "");
  const secondVideo = playlistButtons.nth(1);
  check(
    "vidéo suivante marquée inaccessible (aria-disabled)",
    (await secondVideo.getAttribute("aria-disabled")) === "true",
  );
  await secondVideo.click({ timeout: 2500 }).catch(() => null);
  await sleep(400);
  const titleAfter = await page
    .innerText('main p:has-text("en cours") + h2')
    .catch(() => "");
  check(
    "clic bloqué sur une vidéo non regardée",
    titleBefore.length > 0 && titleBefore === titleAfter,
    `${titleBefore.slice(0, 30)} → ${titleAfter.slice(0, 30)}`,
  );

  const nextButton = page.locator('main button:has-text("Étape suivante")');
  check(
    "'Étape suivante' désactivée tant que vidéos non terminées",
    (await nextButton.count()) === 1 && (await nextButton.isDisabled()),
  );

  console.log("\n4. Gate document — accès direct à une étape ultérieure");
  await page.goto(`${BASE}/app/parcours/${TRACK}/chapitres/${CH1}?etape=cours`, {
    waitUntil: "domcontentloaded",
  });
  await timeline.waitFor({ timeout: 20000 });
  if (coursFirst) {
    check(
      "?etape=cours accepté (Cours avant les Vidéos)",
      includesCI(
        await page.locator('aside [aria-current="step"]').first().innerText(),
        "Cours",
      ),
    );
    const coursMain = await page.innerText("main");
    check(
      "leçon affichée sans notice de blocage",
      includesCI(coursMain, "Leçon") &&
        !includesCI(coursMain, "pour débloquer la suite du chapitre"),
    );
  } else {
    check(
      "?etape=cours renvoyé vers l'étape Leçons vidéo",
      includesCI(
        await page.locator('aside [aria-current="step"]').first().innerText(),
        "vidéo",
      ),
    );
    check(
      "notice de blocage affichée",
      includesCI(
        await page.innerText("main"),
        "Regardez toutes les vidéos du chapitre pour débloquer la suite du chapitre et le quiz.",
      ),
    );
  }

  console.log("\n5. Gate quiz — accès direct au quiz");
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH1}/quiz`,
    { waitUntil: "domcontentloaded" },
  );
  const lockedQuizText = await page.innerText("main");
  check(
    "quiz bloqué avant visionnage",
    includesCI(
      lockedQuizText,
      "Regardez toutes les vidéos du chapitre avant de passer le quiz.",
    ),
  );
  await page.click('a:has-text("Voir les")');
  await page.waitForURL(/\?etape=videos$/, { timeout: 20000 });
  check("lien de révision → étape Leçons vidéo", true);

  console.log("\n6. Déblocage (setup videos_watched) puis navigation document");
  const setup = await markChapterVideosWatched({
    email: EMAIL,
    chapterId: "py-c1",
    trackId: TRACK,
  });
  check(
    "setup des vidéos regardées",
    setup.ok,
    setup.ok
      ? `${setup.tokens?.length ?? 0} vidéos marquées`
      : `${setup.reason}${setup.detail ? ` — ${setup.detail}` : ""}`,
  );

  if (setup.ok) {
    await page.goto(`${BASE}/app/parcours/${TRACK}/chapitres/${CH1}`, {
      waitUntil: "domcontentloaded",
    });
    await timeline.waitFor({ timeout: 20000 });
    check(
      "étape par défaut Objectifs après déblocage",
      includesCI(await page.innerText("main"), "Objectifs du chapitre"),
    );

    if (pagesReady) {
      console.log("\n6bis. Pages numérotées du Cours (type Cisco)");
      await page.goto(
        `${BASE}/app/parcours/${TRACK}/chapitres/${CH1}?etape=cours&page=1`,
        { waitUntil: "domcontentloaded" },
      );
      await timeline.waitFor({ timeout: 20000 });
      const firstPageMain = await page.innerText("main");
      check(
        "page 1 : code 1.3.1 + « Page 1 sur N »",
        firstPageMain.includes("1.3.1") &&
          /Page 1 sur \d+/.test(firstPageMain),
      );
      const timelineLabels = await timeline
        .locator("a")
        .evaluateAll((links) => links.map((a) => (a.textContent ?? "").trim()));
      const coursLabel =
        timelineLabels.find((label) => /^Cours/i.test(label)) ?? "";
      check(
        "compteur x / y sur l'étape Cours (sidebar)",
        /\d+ \/ \d+/.test(coursLabel),
        coursLabel,
      );
      const totalPages = Number.parseInt(
        (coursLabel.match(/\/ (\d+)/) ?? [])[1] ?? "0",
        10,
      );
      check("au moins 8 pages par leçon", totalPages >= 8, `${totalPages} pages`);

      await page.click('main a:has-text("Page suivante")');
      await page.waitForURL(/page=2/, { timeout: 20000 });
      check(
        "« Page suivante » → ?page=2 (code 1.3.2)",
        includesCI(await page.innerText("main"), "1.3.2"),
      );

      if (totalPages > 0) {
        await page.goto(
          `${BASE}/app/parcours/${TRACK}/chapitres/${CH1}?etape=cours&page=${totalPages}`,
          { waitUntil: "domcontentloaded" },
        );
        await timeline.waitFor({ timeout: 20000 });
        const lastPageMain = await page.innerText("main");
        check(
          "dernière page : code 1.3.N + « Page N sur N »",
          lastPageMain.includes(`1.3.${totalPages}`) &&
            lastPageMain.includes(`Page ${totalPages} sur ${totalPages}`),
        );
        check(
          "dernière page : retour à « Étape suivante »",
          (await page.locator('main a:has-text("Page suivante")').count()) ===
            0 &&
            (await page.locator('main a:has-text("Étape suivante")').count()) ===
              1,
        );
      }

      await page.goto(`${BASE}/app/parcours/${TRACK}/chapitres/${CH1}`, {
        waitUntil: "domcontentloaded",
      });
      await timeline.waitFor({ timeout: 20000 });
      check(
        "retour au chapitre : étape par défaut Objectifs",
        includesCI(await page.innerText("main"), "Objectifs du chapitre"),
      );
    }

    const stepAssertions = {
      videos: async () => {
        check(
          "progression 3 / 3 après setup",
          includesCI(await page.innerText("main"), "3 / 3 leçons terminées"),
        );
      },
      cours: async () => {
        const coursMain = await page.innerText("main");
        check(
          "étape Cours (URL + contenu)",
          includesCI(coursMain, "Leçon"),
        );
        if (pagesReady) {
          check(
            "page du Cours numérotée (1.3.x + Page x / y)",
            /1\.3\.\d+/.test(coursMain) && /Page \d+ sur \d+/.test(coursMain),
            (coursMain.match(/1\.3\.\d+/) ?? ["code absent"])[0],
          );
        }
      },
      exercice: async () => {
        check(
          "étape Exercice (URL + contenu)",
          includesCI(await page.innerText("main"), "Exercice pratique"),
        );
        await page
          .waitForSelector("section .cm-editor", { timeout: 15000 })
          .catch(() => null);
        check(
          "panneau Pratiquer (outils de pratique)",
          includesCI(await page.innerText("main"), "Pratiquer") &&
            (await page.locator("section .cm-editor").count()) >= 1,
        );
      },
    };
    const chain = stepKeysObserved.slice(1, -1);
    check(
      "navigation des 4 étapes dans l'ordre affiché",
      chain.length === 4,
      chain.join(" → "),
    );
    for (const key of chain) {
      await exhaustPages();
      await page.click('a:has-text("Étape suivante")');
      // sur le Cours, PageResume peut ajouter &page=N (reprise mémorisée)
      await page.waitForURL(new RegExp(`\\?etape=${key}(&page=\\d+)?$`), {
        timeout: 20000,
      });
      if (key === "cours") {
        // attendre la fin du rechargement de reprise avant l'assertion
        await page
          .waitForURL(/page=\d+/, { timeout: 15000 })
          .catch(() => null);
      }
      await stepAssertions[key]?.();
    }
    const ressourcesMain = await page.innerText("main");
    check(
      "étape Ressources (URL + contenu)",
      includesCI(ressourcesMain, "Ressources recommandées"),
    );
    check(
      "compteur 'Étape 5 sur 5'",
      ressourcesMain.includes("Étape 5 sur 5"),
    );
    const stepNavBox = page
      .locator("main article > div")
      .filter({ hasText: "Étape 5 sur 5" });
    check(
      "CTA quiz en dernière étape",
      (await stepNavBox.locator('a[href$="/quiz"]').count()) === 1,
    );
    const storedStep = await page.evaluate(
      (key) => localStorage.getItem(key),
      `easylearn:step:${TRACK}:${CH1}`,
    );
    check(
      "étape mémorisée en localStorage",
      storedStep === "ressources",
      storedStep ?? "null",
    );

    await page
      .locator(`aside a[href$="/chapitres/${CH1}"]`)
      .first()
      .click();
    await page.waitForURL(/\?etape=ressources$/, { timeout: 20000 });
    check("sidebar → reprend l'étape mémorisée", true);

    await page.goto(
      `${BASE}/app/parcours/${TRACK}/chapitres/${CH1}/quiz`,
      { waitUntil: "domcontentloaded" },
    );
    const quizMain = await page.innerText("main");
    check(
      "quiz accessible après visionnage",
      includesCI(quizMain, "Valider mes réponses"),
      includesCI(quizMain, "Regardez toutes les vidéos")
        ? "toujours bloqué"
        : undefined,
    );
  }

  console.log("\n7. Chapitre verrouillé en URL directe");
  await page.goto(`${BASE}/app/parcours/${TRACK}/chapitres/${CH_LOCKED}`, {
    waitUntil: "domcontentloaded",
  });
  check(
    "écran verrouillé (chapitre)",
    includesCI(await page.innerText("main"), "Chapitre verrouillé"),
  );
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LOCKED}/tutoriel`,
    { waitUntil: "domcontentloaded" },
  );
  await page.waitForURL(
    new RegExp(`/chapitres/${CH_LOCKED}$`),
    { timeout: 20000 },
  );
  check(
    "route /tutoriel → redirect vers le chapitre (verrouillé)",
    includesCI(await page.innerText("main"), "Chapitre verrouillé"),
  );
  await page.goto(
    `${BASE}/app/parcours/${TRACK}/chapitres/${CH_LOCKED}?etape=ressources`,
    { waitUntil: "domcontentloaded" },
  );
  check(
    "écran verrouillé (document, étape ignorée)",
    includesCI(await page.innerText("main"), "Chapitre verrouillé"),
  );
} finally {
  await browser.close();
}

console.log(
  failures === 0
    ? "\n=== TOUS LES TESTS PASSENT ===\n"
    : `\n=== ${failures} ÉCHEC(S) ===\n`,
);
process.exit(failures === 0 ? 0 : 1);
