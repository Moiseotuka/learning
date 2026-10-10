/**
 * Diagnostic : la route /api/certificats renvoie-t-elle204 aux headers
 * exacts de Chromium (UA HeadlessChrome, sec-ch-ua, referer) ?
 * Si oui → condition côté serveur ; si non (200+PDF) → côté client.
 */
import { readFileSync } from "node:fs";

const envRaw = readFileSync(new URL("../.env.local", import.meta.url), "utf8");
const envOf = (key) =>
  (envRaw.match(new RegExp(`^${key}=(.*)$`, "m")) ?? [])[1]?.trim() ?? "";

const SUPA = envOf("NEXT_PUBLIC_SUPABASE_URL");
const ANON = envOf("NEXT_PUBLIC_SUPABASE_ANON_KEY") || envOf("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");

const login = await fetch(`${SUPA}/auth/v1/token?grant_type=password`, {
  method: "POST",
  headers: { "Content-Type": "application/json", apikey: ANON },
  body: JSON.stringify({
    email: "quiz-test@easylearn.dev",
    password: "QuizTest2026!",
  }),
}).then((r) => r.json());

if (!login.access_token) {
  console.error("login KO", JSON.stringify(login).slice(0, 300));
  process.exit(1);
}

const ref = new URL(SUPA).hostname.split(".")[0];
const cookieValue = JSON.stringify({
  access_token: login.access_token,
  refresh_token: login.refresh_token,
  expires_at: Math.floor(Date.now() / 1000) + 3600,
});
const cookie = `sb-${ref}-auth-token=${encodeURIComponent(cookieValue)}`;

const ua =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0";

const res = await fetch(
  "http://localhost:3000/api/certificats/PYT-2026-000001",
  {
    headers: {
      cookie,
      "user-agent": ua,
      "sec-ch-ua-platform": "Windows",
      "sec-ch-ua": '"Chromium";v="154", "Microsoft Edge";v="154"',
      referer: "http://localhost:3000/app/profil",
      accept: "*/*",
    },
  },
);
const buffer = await res.arrayBuffer();
console.log(
  "node + headers Chromium →",
  res.status,
  buffer.byteLength,
  "octets",
  res.headers.get("content-type"),
);
