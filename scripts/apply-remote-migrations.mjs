import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

const REF = "gmgmrywvloszxlqmellw";
const TOKEN = process.env.SUPABASE_PAT;
if (!TOKEN) { console.error("SUPABASE_PAT manquant"); process.exit(1); }

const mode = process.argv[2]; // "sql" | "query"
const args = process.argv.slice(3);

async function runSql(sql, label) {
  const res = await fetch(`https://api.supabase.com/v1/projects/${REF}/database/query`, {
    method: "POST",
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify({ query: sql }),
  });
  const text = await res.text();
  if (!res.ok) {
    console.error(`✗ ${label} — HTTP ${res.status}`);
    try { console.error(JSON.parse(text).message || text.slice(0, 800)); } catch { console.error(text.slice(0, 800)); }
    process.exitCode = 1;
    return false;
  }
  console.log(`✓ ${label}`);
  return true;
}

if (mode === "sql") {
  for (const f of args) {
    const path = resolve(f);
    if (!existsSync(path)) { console.error(`✗ introuvable: ${path}`); process.exitCode = 1; continue; }
    const sql = readFileSync(path, "utf8");
    const ok = await runSql(sql, `${f} (${(sql.length / 1024).toFixed(0)} KB)`);
    if (!ok) break;
  }
} else if (mode === "query") {
  const sql = readFileSync(resolve(args[0]), "utf8");
  const res = await fetch(`https://api.supabase.com/v1/projects/${REF}/database/query`, {
    method: "POST",
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify({ query: sql }),
  });
  const text = await res.text();
  if (!res.ok) {
    console.error(`HTTP ${res.status}:`);
    try { console.error(JSON.parse(text).message || text); } catch { console.error(text); }
    process.exit(1);
  }
  console.log(text);
} else {
  console.error("usage: SUPABASE_PAT=... node apply-remote-migrations.mjs sql <files...> | query <file.sql>");
  process.exit(1);
}
