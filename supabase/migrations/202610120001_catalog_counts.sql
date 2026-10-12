-- 202610120001_catalog_counts.sql
-- Compteurs réels du catalogue, utilisés par la page d'accueil et le bandeau de chiffres.
-- Un seul appel remplace plusieurs requêtes : la vitrine publie des chiffres vérifiables,
-- jamais des estimations marketing.

create or replace function public.catalog_counts()
returns table (
  published_tracks bigint,
  published_chapters bigint,
  video_lessons bigint,
  course_pages bigint,
  published_categories bigint,
  catalog_hours bigint
)
language sql
stable
as $$
  select
    (
      select count(*)
      from public.tracks
      where published
    ),
    (
      select count(*)
      from public.chapters c
      where c.published
        and exists (
          select 1 from public.tracks t
          where t.id = c.track_id and t.published
        )
    ),
    (
      select coalesce(sum(jsonb_array_length(c.videos)), 0)
      from public.chapters c
      where c.published
        and jsonb_typeof(c.videos) = 'array'
        and exists (
          select 1 from public.tracks t
          where t.id = c.track_id and t.published
        )
    ),
    (
      select count(*)
      from public.chapter_pages p
      where exists (
        select 1
        from public.chapters c
        join public.tracks t on t.id = c.track_id
        where c.id = p.chapter_id and c.published and t.published
      )
    ),
    (
      select count(*)
      from public.categories
      where published
    ),
    (
      select coalesce(sum(duration_hours), 0)::bigint
      from public.tracks
      where published
    );
$$;

alter function public.catalog_counts() owner to postgres;

grant execute on function public.catalog_counts() to anon, authenticated;
