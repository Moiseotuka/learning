const queries = process.argv.slice(2);
for (const q of queries) {
  const url =
    "https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=8&gsrsearch=" +
    encodeURIComponent(q) +
    "&prop=imageinfo&iiprop=url|mime&iiurlwidth=960";
  const r = await fetch(url, { headers: { "User-Agent": "easyLearn-content/1.0 (contact@example.org)" } });
  const j = await r.json();
  console.log("### " + q + " status=" + r.status);
  const pages = j.query?.pages ?? {};
  for (const p of Object.values(pages)) {
    const ii = p.imageinfo?.[0];
    if (!ii) continue;
    console.log(p.title + " | " + ii.mime + " | " + ii.thumburl);
  }
  console.log("");
}
