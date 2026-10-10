import { readFileSync, writeFileSync, existsSync } from "node:fs";
import path from "node:path";
import jpeg from "jpeg-js";

const ROOT = process.cwd();
const SOURCE = path.join(ROOT, "public", "certificat.jpg");
const TARGET = path.join(ROOT, "public", "certificat-clean.jpg");

const ZONES = [
  { name: "nom", x0: 245, y0: 322, x1: 990, y1: 438 },
  { name: "titre", x0: 330, y0: 472, x1: 910, y1: 534 },
  { name: "numero", x0: 890, y0: 716, x1: 1045, y1: 752 },
  { name: "qr", x0: 175, y0: 665, x1: 257, y1: 748 },
];

if (!existsSync(SOURCE)) {
  console.error("introuvable :", SOURCE);
  process.exit(1);
}

const decoded = jpeg.decode(readFileSync(SOURCE), { useTArray: true });
const { width, data } = decoded;

for (const zone of ZONES) {
  let r = 0;
  let g = 0;
  let b = 0;
  let n = 0;
  for (let y = zone.y0; y < zone.y1; y++) {
    for (let x = zone.x0; x < zone.x1; x++) {
      const i = (y * width + x) * 4;
      if (data[i] > 195 && data[i + 1] > 195 && data[i + 2] > 185) {
        r += data[i];
        g += data[i + 1];
        b += data[i + 2];
        n++;
      }
    }
  }
  const mr = Math.round(r / n);
  const mg = Math.round(g / n);
  const mb = Math.round(b / n);

  for (let y = zone.y0; y < zone.y1; y++) {
    for (let x = zone.x0; x < zone.x1; x++) {
      const i = (y * width + x) * 4;
      const noise = () => Math.round((Math.random() - 0.5) * 9);
      data[i] = Math.max(0, Math.min(255, mr + noise()));
      data[i + 1] = Math.max(0, Math.min(255, mg + noise()));
      data[i + 2] = Math.max(0, Math.min(255, mb + noise()));
      data[i + 3] = 255;
    }
  }

  console.log(
    `${zone.name}: (${mr}, ${mg}, ${mb}) — zone ${zone.x1 - zone.x0}x${zone.y1 - zone.y0}`,
  );
}

const encoded = jpeg.encode(decoded, 98);
writeFileSync(TARGET, encoded.data);
console.log("écrit :", TARGET, encoded.data.length, "octets");
