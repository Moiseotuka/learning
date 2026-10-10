import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const fs = require("fs");
const parts = [1,2,3,4].map(i => fs.readFileSync("content/lessons/.parts/off-c6-"+i+".txt", "utf8"));
fs.writeFileSync("content/lessons/off-c6.txt", parts.map(s => s.trimEnd()).join("\n\n") + "\n");
