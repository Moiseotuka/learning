-- easyTech — Promouvoir un nombre de chapitres que l'apprenant ne trouvera pas
-- est le genre d'écart que Google comme un apprenant remarquent : `modules_count`
-- était saisi à la main et annonce jusqu'à 44 chapitres là où 11 sont publiés.
-- Il devient une donnée calculée à partir des chapitres réellement publiés.

create or replace function public.sync_tracks_modules_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target text := case when tg_op = 'DELETE' then old.track_id else new.track_id end;
begin
  update public.tracks t
     set modules_count = (
       select count(*)::int
       from public.chapters c
       where c.track_id = target
         and c.published
     )
   where t.id = target;

  return null;
end;
$$;

revoke all on function public.sync_tracks_modules_count() from public;
grant execute on function public.sync_tracks_modules_count() to anon, authenticated, service_role;

drop trigger if exists chapters_sync_track_modules_count on public.chapters;
create trigger chapters_sync_track_modules_count
  after insert or update or delete on public.chapters
  for each row execute function public.sync_tracks_modules_count();

-- Réaligne ce qui a déjà été publié.
update public.tracks t
   set modules_count = (
     select count(*)::int
     from public.chapters c
     where c.track_id = t.id
       and c.published
   );
