import { readFileSync } from "node:fs";
const path = "content/lessons/off-c6.txt";
const content = readFileSync(path, "utf8");
const lines = content.split("\n");
const words = content.split(/\s+/).filter(Boolean).length;
console.log("mots:", words);

// blank line before/after each fence
let issues = [];
let inF = false;
let blockStart = -1;
let fenceCount = 0;
const blocks = [];
let buf = [];
for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  if (l.trimStart().startsWith("```")) {
    if (!inF) {
      inF = true;
      blockStart = i;
      buf = [l];
      fenceCount++;
      if (i > 0 && lines[i - 1].trim() !== "") issues.push(`pas de ligne vide avant la ligne ${i + 1}: ${JSON.stringify(l.slice(0, 60))}`);
    } else {
      buf.push(l);
      blocks.push({ start: blockStart, lines: buf.slice() });
      inF = false;
      fenceCount++;
      if (i + 1 < lines.length && lines[i + 1].trim() !== "") issues.push(`pas de ligne vide après la ligne ${i + 1}: ${JSON.stringify(l.slice(0, 60))}`);
    }
  } else if (inF) buf.push(l);
}
console.log("blocs:", fenceCount, "(paires:", fenceCount / 2 + ")");

let images = 0;
let tables = 0;
for (const b of blocks) {
  const head = b.lines[0].replace(/^\s*```/, "").trim();
  if (head === "image") {
    images++;
    if (b.lines.length !== 4) issues.push(`bloc image ligne ${b.start + 1}: ${b.lines.length} lignes attendu 4`);
    if (!/^https:\/\/upload\.wikimedia\.org\/\S+$/.test(b.lines[1])) issues.push(`URL image invalide ligne ${b.start + 2}`);
    if (!b.lines[2].startsWith("| ") || !b.lines[2].trimEnd().endsWith(".")) issues.push(`légende image invalide ligne ${b.start + 3}`);
  }
  if (head === "table") {
    tables++;
    const rows = b.lines.slice(1, -1).map((r) => r.split("|").length - 2);
    const first = rows[0];
    rows.forEach((n, i) => {
      if (n !== first) issues.push(`table ligne ${b.start + 1}: ligne ${i} a ${n} colonnes, en-tête en a ${first}`);
    });
  }
}
console.log("images:", images, "tables:", tables);

// mojibake / encodage
const bad = ["\uFFFD", "\u01F8", "\u01E6", "\u00C8\u00C8"];
for (const b of bad) if (content.includes(b)) issues.push("caractère suspect: " + JSON.stringify(b));
if (/[��]/.test(content)) issues.push("replacement char");
if (/\*\*/.test(content.replace(/```[\s\S]*?```/g, ""))) issues.push("** dans le prose");
console.log("blocs code (types):", blocks.map((b) => b.lines[0].replace(/^\s*```/, "").trim() || "sans-langage").join(", "));

if (issues.length === 0) console.log("=== VERIFICATION OK ===");
else {
  console.log("PROBLEMES:");
  issues.forEach((i) => console.log(" ! " + i));
}
