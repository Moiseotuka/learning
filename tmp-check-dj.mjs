import fs from "node:fs";
let files = [];
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) {
      if (e.name === ".parts" || e.name === "_" || e.name.startsWith(".")) continue;
      walk(`${dir}/${e.name}`, files);
    } else if (e.name.endsWith(".txt") || e.name.endsWith(".json")) {
      files.push(`${dir}/${e.name}`);
    }
  }
}
walk("content");
let ofc = 0, dj = 0, others = 0;
for (const f of files) {
  if (f.includes("/off-c") && f.endsWith(".txt")) ofc++;
  else if (f.includes("/dj-c") && f.endsWith(".txt")) dj++;
  else if (f.includes("/dj-c") && f.endsWith(".json")) dj++;
  else if (f.includes("/dj-c") && f.endsWith(".json")) dj++;
  else if (!f.includes(".parts")) others++;
}
console.log(`Leçons off-c : ${ofc} : ${['1','2','3','4','5','6'].map(i=>`off-c${i}.txt`).join(" ")}`);
console.log(`Leçons dj-c : ${dj} : ${['1','2','3','4','5','6'].map(i=>`dj-c${i}.txt`).join(" ")}`);
console.log(`Autres : ${others}`);
