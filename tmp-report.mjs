const fs = require("fs");
let dirs = ["content/lessons/.parts", "content/lessons", "content/quizzes", "content/chapters"];
for (const d of dirs) {
  console.log("===", d, "===");
  const files = fs.readdirSync(d).filter(f => f.endsWith(".txt") || f.endsWith(".json"));
  for (const f of files) {
    const p = `${d}/${f}`;
    const stat = fs.statSync(p);
    console.log(`${f} : ${stat.size} octets`);
  }
  console.log();
}
