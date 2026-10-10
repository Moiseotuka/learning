import { createHash } from "node:crypto";

const files = [
  "Django_logo.svg",
  "Python-logo-notext.svg",
  "SQLite370.svg",
  "PostgreSQL_elephant.svg",
  "Tux.svg",
  "Django_Software_Foundation_logo.svg",
  "Web_framework.png",
  "GNOME_Terminal_screenshot.png",
  "Terminal-linux.jpg",
  "Django_Adrian_Holovaty.jpg",
  "Django_Pony.png",
  "Python-logo-notext.svg",
];

for (const f of files) {
  const md5 = createHash("md5").update(f, "utf8").digest("hex");
  const ext = f.endsWith(".svg") ? ".png" : "";
  const url = `https://upload.wikimedia.org/wikipedia/commons/thumb/${md5[0]}/${md5[0] + md5[1]}/${encodeURIComponent(f)}/960px-${encodeURIComponent(f)}${ext}`;
  try {
    const r = await fetch(url, { method: "HEAD", headers: { "User-Agent": "easyLearn-content/1.0" } });
    console.log(r.status, f, "->", url);
  } catch (e) {
    console.log("ERR", f, e.message);
  }
}
