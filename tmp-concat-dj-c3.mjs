import { readFileSync, writeFileSync } from "node:fs";

const parts = [1, 2, 3, 4].map((i) =>
  readFileSync(`content/lessons/.parts/dj-c3-${i}.txt`, "utf8")
);
const contenu = parts.map((s) => s.trimEnd()).join("\n\n") + "\n";
writeFileSync("content/lessons/dj-c3.txt", contenu);
console.log("Écrit:", contenu.split(/\s+/).filter(Boolean).length, "mots");
