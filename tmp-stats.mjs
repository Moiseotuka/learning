import { readFileSync } from "node:fs";

const path = process.argv[2];
const content = readFileSync(path, "utf8");

const words = content.split(/\s+/).filter(Boolean).length;

const blocks = [];
let current = [];
let inFence = false;
for (const line of content.split("\n")) {
  if (line.trimStart().startsWith("```")) inFence = !inFence;
  if (!inFence && line.trim() === "") {
    if (current.length > 0) {
      blocks.push(current.join("\n").trim());
      current = [];
    }
    continue;
  }
  current.push(line);
}
if (current.length > 0) blocks.push(current.join("\n").trim());

const prose = blocks.filter(
  (b) =>
    !b.startsWith("#") &&
    !b.startsWith("```") &&
    !b.split("\n").every((l) => l.trim().startsWith("- ")) &&
    !b.split("\n").every((l) => /^\d+\.\s+/.test(l.trim())),
);

const headings = content.match(/^##\s+.*$/gm) ?? [];
const fences = content.match(/^\s*```/gm)?.length ?? 0;
const backticks = (content.match(/`/g) ?? []).length;

let proseContent = "";
let f2 = false;
for (const line of content.split("\n")) {
  if (line.trimStart().startsWith("```")) {
    f2 = !f2;
    continue;
  }
  if (!f2) proseContent += `${line}\n`;
}

const forbidden = [
  ["gras **", /\*\*/],
  ["](", /\]\(/],
  ["# ", /^# /m],
  ["$$", /\$\$/],
  ["---", /^-{3,}\s*$/m],
  ["html", /<\/?[a-z]+[ >]/i],
];
const bad = forbidden.filter(([, re]) => re.test(proseContent)).map(([l]) => l);

console.log(
  JSON.stringify(
    {
      file: path,
      words,
      prose: prose.length,
      headings: headings.length,
      fences,
      fenceBalanced: fences % 2 === 0,
      backtickBalanced: backticks % 2 === 0,
      forbiddenFound: bad,
      headingList: headings,
    },
    null,
    2,
  ),
);
