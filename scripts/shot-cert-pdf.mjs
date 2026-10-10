import { createRequire } from "node:module";
import { chromium } from "playwright-core";

const require = createRequire(import.meta.url);
const OUT = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode";
const compiled = "D:\\elearning\\.tmp-cert\\pdf.js";

const { renderCertificatePdf } = require(compiled);

const pdf = await renderCertificatePdf({
  code: "PYT-2026-000123",
  title: "Python : niveau Intermédiaire",
  full_name: "Moise OTUKA OTUKA",
});

const pdfPath = `${OUT}\\cert-test.pdf`;
const { writeFileSync } = await import("node:fs");
writeFileSync(pdfPath, pdf);
console.log("pdf:", pdfPath, pdf.length, "octets");

const browser = await chromium.launch({
  executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  headless: true,
});
const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });
await page.goto(`file:///${pdfPath.replaceAll("\\", "/")}`);
await page.waitForTimeout(3500);
await page.screenshot({ path: `${OUT}\\cert-test.png` });
console.log("shot: cert-test.png");
await browser.close();
