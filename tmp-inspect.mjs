import { readFileSync } from "node:fs";
const c = readFileSync("content/lessons/cyb-c6.txt", "utf8");
const lines = c.split("\n");
console.log(lines.filter((l) => l.startsWith("## ")).join("\n"));
console.log("WORDS", c.split(/\s+/).filter(Boolean).length);
let inF = false;
let buf = [];
const blocks = [];
for (const l of lines) {
  if (l.trimStart().startsWith("```")) {
    if (!inF) {
      inF = true;
      buf = [l];
    } else {
      buf.push(l);
      blocks.push(buf.join("\n"));
      inF = false;
    }
  } else if (inF) buf.push(l);
}
console.log("fence count", blocks.length);
for (const b of blocks) {
  if (b.startsWith("```image") || b.startsWith("```table")) {
    console.log(b);
    console.log("-----");
  }
}
