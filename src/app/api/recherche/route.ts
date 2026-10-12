import { searchCatalog } from "@/lib/catalog/search";

/**
 * Suggestions de la recherche interne (champ de l'en-tête et hero).
 * Seules des données déjà publiques passent ici : titres, domaine, niveau, lien
 * interne du catalogue publié. Une requête par frappe arrêtée, mise en cache
 * soixante secondes côté client.
 */
export async function GET(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const query = String(url.searchParams.get("q") ?? "").trim().slice(0, 80);
  const limit = Math.min(Math.max(Number(url.searchParams.get("limit")) || 8, 1), 20);

  if (query.length < 2) {
    return Response.json({ items: [] }, { headers: { "cache-control": "no-store" } });
  }

  const items = await searchCatalog(query, limit);

  return Response.json(
    {
      query,
      items: items.map((item) => ({
        kind: item.kind,
        title: item.title,
        context: item.context,
        level: item.level,
        href: item.href,
      })),
    },
    { headers: { "cache-control": "private, max-age=60" } },
  );
}
