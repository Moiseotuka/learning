// Enregistre l'URL de réception des webhooks easyLearn auprès de nyole.
//
//   node scripts/nyole-webhook.mjs [https://domaine/api/webhooks/payment]
//
// La clé secrète est lue dans .env.local (NYOLE_SECRET_KEY). L'URL doit être
// publique et en HTTPS : en local, passez par un tunnel (ngrok, cloudflared…)
// puis renseignez NYOLE_WEBHOOK_URL dans .env.local.
import { readFileSync } from "node:fs";

const ENV_PATH = "D:\\elearning\\.env.local";

function readEnv(path) {
  const lines = [];
  try {
    lines.push(...readFileSync(path, "utf8").split(/\r?\n/));
  } catch {
    /* fichier absent */
  }
  if (!lines.length && path.endsWith(".env.local")) {
    return readEnv(path.replace(/\.env\.local$/, ".env"));
  }
  return Object.fromEntries(
    lines
      .filter((line) => line.includes("=") && !line.trim().startsWith("#"))
      .map((line) => {
        const i = line.indexOf("=");
        return [line.slice(0, i).trim(), line.slice(i + 1).trim()];
      }),
  );
}

const env = readEnv(ENV_PATH);
const secret = env.NYOLE_SECRET_KEY ?? "";
const api = "https://app.nyole.com/api/v1/config/webhook";

const argUrl = process.argv[2]?.trim();
const baseUrl = env.NEXT_PUBLIC_SITE_URL ?? env.SITE_URL ?? "";
const webhookUrl =
  argUrl ||
  env.NYOLE_WEBHOOK_URL ||
  (baseUrl ? `${baseUrl.replace(/\/$/, "")}/api/webhooks/payment` : "");

if (!secret.startsWith("af_")) {
  console.error("NYOLE_SECRET_KEY absente ou invalide dans .env.local");
  process.exit(1);
}
if (!webhookUrl.startsWith("https://")) {
  console.error(
    "URL du webhook absente (argument ou NYOLE_WEBHOOK_URL / NEXT_PUBLIC_SITE_URL).\n" +
      "  Exemple : node scripts/nyole-webhook.mjs https://mon-tunnel.ngrok.app/api/webhooks/payment",
  );
  process.exit(1);
}

const mode = secret.startsWith("af_test_") ? "test" : "live";
const events = [
  "payment.completed",
  "payment.failed",
  "payment.cancelled",
];

console.log(`Webhook nyole — mode ${mode}`);
console.log(`  ${webhookUrl}`);

const response = await fetch(api, {
  method: "PATCH",
  headers: {
    Authorization: `Bearer ${secret}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ webhookUrl, mode, events }),
});
const text = await response.text();
let json = null;
try {
  json = JSON.parse(text);
} catch {
  /* réponse non JSON */
}
console.log(`  HTTP ${response.status}`);
console.log(JSON.stringify(json ?? text.slice(0, 400), null, 2));

if (!response.ok || json?.success === false) {
  process.exit(1);
}
console.log("Webhook enregistré.");
