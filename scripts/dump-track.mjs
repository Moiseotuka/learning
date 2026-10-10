import { createClient } from "@supabase/supabase-js";
import { readFileSync } from "node:fs";

const env = Object.fromEntries(
  readFileSync(".env.local", "utf8")
    .split(/\r?\n/)
    .filter((l) => l.includes("="))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).replace(/^['"]|['"]$/g, "")];
    }),
);

const sb = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
const slug = process.argv[2] ?? "developpement-web-moderne";
const { data: track } = await sb.from("tracks").select("id").eq("slug", slug).single();
const { data } = await sb
  .from("chapters")
  .select("id,slug,title,summary,objectives,level,position")
  .eq("track_id", track.id)
  .order("position");
for (const c of data)
  console.log(
    JSON.stringify(
      { id: c.id, slug: c.slug, pos: c.position, level: c.level, title: c.title, summary: c.summary, objectives: c.objectives },
      null,
      0,
    ),
  );
