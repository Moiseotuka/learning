import { readFileSync } from "node:fs";

const rows = readFileSync(`${process.env.TEMP}\\yt-videos.tsv`, "utf8")
  .split("\n")
  .filter((l) => l.trim())
  .map((l) => {
    const [slug, url, ...rest] = l.replace(/\r$/, "").split("\t");
    return { slug, url, title: rest.join("\t") };
  });

const results = [];
for (let i = 0; i < rows.length; i += 8) {
  const batch = rows.slice(i, i + 8);
  const out = await Promise.all(
    batch.map(async (row) => {
      try {
        const res = await fetch(
          `https://www.youtube.com/oembed?url=${encodeURIComponent(row.url)}&format=json`,
        );
        if (res.ok) return { ...row, embed: "OK" };
        const body = await res.text();
        return { ...row, embed: `REFUS ${res.status}: ${body.slice(0, 120)}` };
      } catch (e) {
        return { ...row, embed: `ERREUR ${e.message}` };
      }
    }),
  );
  results.push(...out);
}

const bad = results.filter((r) => r.embed !== "OK");
console.log(`total=${results.length} | embed OK=${results.length - bad.length} | refusés=${bad.length}`);
for (const r of bad) console.log(`✗ ${r.slug} | ${r.title} | ${r.url} | ${r.embed}`);
