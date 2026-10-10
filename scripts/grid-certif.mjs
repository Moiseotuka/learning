import { chromium } from "playwright-core";
import { writeFileSync } from "node:fs";

const vLines = Array.from({ length: 25 }, (_, i) => {
  const x = i * 50;
  return `<line x1="${x}" y1="0" x2="${x}" y2="864" stroke="red" stroke-width="1"/><text x="${x + 2}" y="14" fill="red" font-size="12">${x}</text>`;
}).join("");
const hLines = Array.from({ length: 18 }, (_, i) => {
  const y = i * 50;
  return `<line x1="0" y1="${y}" x2="1232" y2="${y}" stroke="lime" stroke-width="1"/><text x="2" y="${y + 13}" fill="lime" font-size="12">${y}</text>`;
}).join("");

const html = `<body style='margin:0;position:relative'>
  <img src='file:///D:/elearning/public/certificat.jpg' width='1232' height='864'>
  <svg style='position:absolute;left:0;top:0;pointer-events:none' width='1232' height='864'>${vLines}${hLines}</svg>
</body>`;
const htmlPath = "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\grid.html";
writeFileSync(htmlPath, html);

const browser = await chromium.launch({
  executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  headless: true,
});
const page = await browser.newPage({ viewport: { width: 1232, height: 900 } });
await page.goto(`file:///${htmlPath.replaceAll("\\", "/")}`);
await page.waitForTimeout(800);
await page.screenshot({ path: "C:\\Users\\moiseo\\AppData\\Local\\Temp\\opencode\\certif-grid.png" });
console.log("done");
await browser.close();
