/**
 * Images réelles pour les leçons : recherche sur Wikimedia Commons (libres),
 * téléchargement, upload dans le bucket Supabase Storage `course-images`,
 * et manifeste content/image-manifest.json (clé → URL publique).
 *
 * Dans les leçons, une figure s'insère avec :
 *   ```image
 *   <URL publique>
 *   | Légende affichée sous la figure
 *   ```
 *
 * Usage : node scripts/fetch-course-images.mjs            (tout ce qui manque)
 *         node scripts/fetch-course-images.mjs --only clé (une image)
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";

import { serviceEnv } from "./e2e-setup.mjs";

const ROOT = resolve(new URL("..", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const MANIFEST = resolve(ROOT, "content/image-manifest.json");
const BUCKET = "course-images";

/** clé → requête de recherche Commons (fr ou en, priorité aux photos/schémas nets) */
const WANT = {
  "topo-etoile": 'intitle:"star topology" network diagram',
  "topo-bus": "Bus network topology diagram",
  "topo-mailee": "Mesh network topology diagram",
  "switch-reseau": "Ethernet switch networking device",
  "routeur-reseau": "Router networking device",
  "cable-rj45": "RJ45 UTP Cat5e connector",
  "point-acces-wifi": "Wi-Fi access point wireless",
  "modele-osi": 'OSI reference model layers chart',
  "adresse-ip": "IPv4 subnet address diagram",
  "cable-fibre": "Fiber optic patch cord connector",
  "patch-panel": "Patch panel rack network",
  "serveur-rack": "Server rack data center",
  "cable-coaxial": "Coaxial cable connector",
  "multimetre": "Digital multimeter measurement",
  "logo-html": "HTML5 logo",
  "css-code": "CSS source code screenshot",
  "react-logo": "React.js logo",
  "php-logo": "PHP logo",
  "sql-schema": 'intitle:"entity relationship diagram"',
  "git-branch": "Git branching diagram",
  "docker-container": "Docker container engine logo",
  "kubernetes": "Kubernetes logo",
  "linux-terminal": "Terminal emulator screenshot Linux",
  "arduino-uno": "Arduino Uno board",
  "esp32": "ESP32 development board",
  "oscilloscope": "Oscilloscope display waveform",
  "clavier-cyber": "Computer keyboard keys closeup",
  "parefeu-reseau": "Network firewall appliance",
  "antenne-wifi": "Wireless antenna access point",
  "js-logo": "JavaScript logo",
  "npm-logo": "npm package logo",
  "typescript-logo": "TypeScript logo",
  "a11y-symbol": "accessibility symbol",
  "chrome-logo": "Google Chrome logo",
  "lighthouse-logo": "Google Lighthouse logo",
  "disque-dur": "hard disk drive",
  "forensics-traces": "computer forensics",
  "cloud-security": "cloud security",
  "soc-console": "security operations center",
  "ipv6-logo": "IPv6 logo",
  "load-balancer": "load balancing diagram",
  "neural-net": "neural network diagram",
  "cnn-diagram": "convolutional neural network diagram",
  "time-series": "time series chart",
  "stock-chart": "stock market chart",
  "freertos-logo": "FreeRTOS logo",
  "freertos-tasks": "FreeRTOS task state",
  "can-bus": "Controller Area Network",
  "rs485": "RS-485",
  "battery-li-ion": "lithium ion battery",
  "python-logo": "Python programming language logo",
};

/** Titres Commons exacts testés AVANT la recherche libre (quand on connaît le bon fichier). */
const WANT_EXACT = {
  "modele-osi": [
    "File:OSI model 7 layers.svg",
    "File:OSI Model v1.svg",
    "File:Osi-model.svg",
    "File:OSI seven layers.svg",
    "File:OSI-Modell.svg",
    "File:OSI Model.svg",
  ],
  "react-logo": [
    "File:React-icon.svg",
    "File:React-logo.svg",
    "File:React.js logo.svg",
    "File:React logo.svg",
    "File:React-Logo.svg",
    "File:Reactjs logo.svg",
  ],
  "sql-schema": [
    "File:Entity-Relationship Diagram GenWiki.png",
    "File:Entity relationship diagram.svg",
    "File:ER diagram.svg",
    "File:Example ER diagram.png",
    "File:Entity Relationship Diagram.svg",
    "File:Erd example.png",
    "File:Simple ER diagram.png",
  ],
  "box-internet": [
    "File:Wireless router.jpg",
    "File:Home router.jpg",
    "File:DSL router.jpg",
  ],
  "js-logo": [
    "File:JavaScript logo.svg",
    "File:Javascript-shiny.svg",
    "File:JavaScript-logo.png",
  ],
  "npm-logo": [
    "File:Npm-logo.svg",
    "File:Npm logo.png",
  ],
  "typescript-logo": [
    "File:Typescript logo.svg",
    "File:TypeScript logo2022.svg",
    "File:TypeScript logo.svg",
  ],
  "a11y-symbol": [
    "File:Accessibility.svg",
    "File:Universal Access Symbol.svg",
    "File:Accessibility logo.svg",
  ],
  "chrome-logo": [
    "File:Google Chrome logo (2011).svg",
    "File:Chrome logo.svg",
  ],
  "lighthouse-logo": [
    "File:Google Lighthouse Logo.svg",
    "File:Lighthouse logo.svg",
  ],
  "ipv6-logo": [
    "File:IPv6 logo.svg",
    "File:IPv6-logo.svg",
    "File:Ipv6-logo.svg",
  ],
  "neural-net": [
    "File:Colored neural network.svg",
    "File:Neural network.svg",
    "File:Artificial neural network.svg",
  ],
  "python-logo": [
    "File:Python-logo.svg",
    "File:Python logo quite big.svg",
    "File:Python-logo-notext.svg",
  ],
  "can-bus": [
    "File:CAN-Bus.svg",
    "File:CAN bus.svg",
    "File:Controller Area Network Bus.svg",
  ],
  "freertos-logo": [
    "File:FreeRTOS logo 2005.svg",
    "File:Logo freeRTOS.png",
    "File:FreeRTOS logo 2003.png",
  ],
  "freertos-tasks": [
    "File:Task state.png",
    "File:Freertos-figures-full-ready-list.png",
  ],
  "typescript-logo": [
    "File:TypeScript Logo (Blue).svg",
    "File:Typescript logo 2020.svg",
    "File:TypeScript Logo.svg",
  ],
  "lighthouse-logo": [
    "File:Google Lighthouse logo.svg",
  ],
  "disque-dur": [
    "File:Seagate ST33232A hard disk inner view.jpg",
    "File:Laptop-hard-drive-exposed.jpg",
    "File:35-Desktop-Hard-Drive.jpg",
  ],
  "forensics-traces": [
    "File:Digital Forensics - Imaging a hard drive in the field.jpg",
    "File:Digital forensics lab.jpg",
    "File:Forensic disk imager.jpg",
  ],
  "cloud-security": [
    "File:Cloud-Security.svg",
    "File:Cloudsecuritymodel.png",
  ],
  "soc-console": [
    "File:NSOC-2012.jpg",
  ],
  "npm-logo": [
    "File:Npm-logo.svg",
    "File:Npm logo 2017.svg",
  ],
};

async function downloadTitle(title) {
  const { buf, type } = await download(title);
  const min = /\.svg$/i.test(title) ? 600 : 5000;
  if (buf.length < min) throw new Error("fichier trop petit");
  return { buf, type };
}

async function existsTitle(title) {
  const url = new URL("https://commons.wikimedia.org/w/api.php");
  url.searchParams.set("action", "query");
  url.searchParams.set("titles", title);
  url.searchParams.set("format", "json");
  const res = await fetch(url, { headers: { "User-Agent": "easyLearn-course-images/1.0" } });
  if (!res.ok) return false;
  const data = await res.json();
  const pages = Object.values(data.query?.pages ?? {});
  return pages.length > 0 && pages[0].missing === undefined;
}

async function commonsSearch(query) {
  const url = new URL("https://commons.wikimedia.org/w/api.php");
  url.searchParams.set("action", "query");
  url.searchParams.set("list", "search");
  url.searchParams.set("srsearch", query);
  url.searchParams.set("srnamespace", "6");
  url.searchParams.set("srlimit", "8");
  url.searchParams.set("format", "json");
  const res = await fetch(url, { headers: { "User-Agent": "easyLearn-course-images/1.0" } });
  if (!res.ok) throw new Error(`search ${res.status}`);
  const data = await res.json();
  return (data.query?.search ?? []).map((s) => s.title);
}

function isImageFile(title) {
  return /\.(jpe?g|png|webp|gif|svg)$/i.test(title);
}

async function download(title) {
  const url = new URL(`https://commons.wikimedia.org/wiki/Special:FilePath/${encodeURIComponent(title)}`);
  url.searchParams.set("width", "1400");
  const res = await fetch(url, { headers: { "User-Agent": "easyLearn-course-images/1.0" }, redirect: "follow" });
  if (!res.ok) throw new Error(`download ${res.status}`);
  const type = (res.headers.get("content-type") || "").split(";")[0].trim();
  const buf = Buffer.from(await res.arrayBuffer());
  return { buf, type };
}

async function upload(key, buf, type) {
  const { url, key: serviceKey } = serviceEnv();
  const ext = type === "image/png" ? "png" : type === "image/webp" ? "webp" : type === "image/svg+xml" ? "svg" : "jpg";
  const path = `${key}.${ext}`;
  const res = await fetch(`${url}/storage/v1/object/${BUCKET}/${path}`, {
    method: "POST",
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, "Content-Type": type, "x-upsert": "true" },
    body: buf,
  });
  if (!res.ok) throw new Error(`upload ${res.status} ${(await res.text()).slice(0, 150)}`);
  return `${url}/storage/v1/object/public/${BUCKET}/${path}`;
}

const onlyIdx = process.argv.indexOf("--only");
const only = onlyIdx >= 0 ? process.argv[onlyIdx + 1] : null;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const manifest = existsSync(MANIFEST) ? JSON.parse(readFileSync(MANIFEST, "utf8")) : {};
let added = 0;

for (const [key, query] of Object.entries(WANT)) {
  if (only && key !== only) continue;
  if (manifest[key]) { console.log(`= ${key} déjà présent`); continue; }
  try {
    await sleep(400);
    let done = false;
    for (const title of WANT_EXACT[key] ?? []) {
      if (done) break;
      try {
        if (!(await existsTitle(title))) continue;
        const { buf, type } = await downloadTitle(title);
        const publicUrl = await upload(key, buf, type);
        manifest[key] = { url: publicUrl, source: `Wikimedia Commons — ${title}` };
        console.log(`✓ ${key} ← ${title} (${Math.round(buf.length / 1024)} Ko)`);
        added++;
        done = true;
      } catch (e) {
        console.log(`  · ${title} : ${e.message}`);
      }
    }
    if (done) continue;
    await sleep(400);
    const titles = (await commonsSearch(query)).filter(isImageFile);
    for (const title of titles.slice(0, 5)) {
      try {
        const { buf, type } = await download(title);
        if (buf.length < (/\.svg$/i.test(title) ? 600 : 5000)) continue;
        const publicUrl = await upload(key, buf, type);
        manifest[key] = { url: publicUrl, source: `Wikimedia Commons — ${title}` };
        console.log(`✓ ${key} ← ${title} (${Math.round(buf.length / 1024)} Ko)`);
        added++;
        done = true;
        break;
      } catch (e) {
        console.log(`  · ${title} : ${e.message}`);
      }
    }
    if (!done) console.log(`✗ ${key} — aucune image exploitable`);
  } catch (e) {
    console.log(`✗ ${key} — ${e.message}`);
  }
}

mkdirSync(resolve(ROOT, "content"), { recursive: true });
writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2), "utf8");
console.log(`\n${added} nouvelle(s) image(s) → ${MANIFEST} (total ${Object.keys(manifest).length})`);
