import { readFileSync } from "node:fs";

const ids = [
  "TDPzQ_9uYyY", "kjS_q5A0qZ4", "vL5zQxY7K9E", "L5Y5JgZoU2U",
  "nL34KDTP3Ro", "4Vn3QYn9XmU", "8XV2IuKV4v0", "6VvRUblJfxU",
  "s_NF9nHqj4g", "zP9YrJpVx7o", "1lY5JJ2qFjQ", "3gZzv5WQ9rE",
  "vmAMVXlG2LQ", "9kQmJ8Q3u7I",
];

for (let i = 0; i < ids.length; i += 5) {
  const batch = ids.slice(i, i + 5);
  const out = await Promise.all(
    batch.map(async (id) => {
      try {
        const res = await fetch(`https://www.youtube.com/watch?v=${id}`, {
          headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36", "Accept-Language": "en-US,en;q=0.9" },
        });
        const html = await res.text();
        const m = html.match(/(?<!preview)"playabilityStatus":\{"status":"([A-Z_]+)"(?:,"reason":"([^"]{0,80})")?/);
        const embed = html.match(/"playerEmbedAllowed":(true|false)/);
        const removed = /Video unavailable|Cette vidéo n'est pas disponible|has been removed/.test(html);
        const title = (html.match(/<title>([^<]{5,120})<\/title>/) || [])[1] || "?";
        return `${id} | HTTP ${res.status} | ${m ? `${m[1]} ${m[2] || ""}` : "?"} | embedAllowed=${embed ? embed[1] : "?"} | removed=${removed} | ${title.slice(0, 60)}`;
      } catch (e) {
        return `${id} | ERREUR ${e.message}`;
      }
    }),
  );
  out.forEach((l) => console.log(l));
}
