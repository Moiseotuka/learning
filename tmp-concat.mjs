import { readFileSync, writeFileSync } from "node:fs";
const parts = [1,2,3,4].map(i => readFileSync("content/lessons/.parts/off-c3-"+i+".txt","utf8"));
writeFileSync("content/lessons/off-c3.txt", parts.map(s=>s.trimEnd()).join("\n\n")+"\n");
const c = readFileSync("content/lessons/off-c3.txt","utf8");
console.log("mots:", c.split(/\s+/).filter(Boolean).length, "| sections:", (c.match(/^##\s/gm)||[]).length, "| chars:", c.length);
