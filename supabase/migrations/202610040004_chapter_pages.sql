-- easyLearn — pages numérotées du Cours (organisation type Cisco NetAcad)
-- La leçon d'un chapitre est découpée en pages navigables : chaque section
-- « ## » devient une page titrée, le chapô d'introduction rejoint la première
-- page. Numérotation affichée : chapitre.étape.page (ex. 1.3.4).
-- Idempotent.
-- Généré par scripts/generate-pages-migration.mjs — ne pas éditer à la main.
-- Suite : 202610040005_chapter_pages_seed.sql (pages) puis
-- 202610040006_chapter_pages_content.sql (repli chapters.content).

-- 1. Table des pages ---------------------------------------------------------

create table if not exists public.chapter_pages (
  id text primary key,
  chapter_id text not null references public.chapters (id) on delete cascade,
  position integer not null check (position >= 1),
  title text not null,
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (chapter_id, position)
);

drop trigger if exists chapter_pages_set_updated_at on public.chapter_pages;
create trigger chapter_pages_set_updated_at
  before update on public.chapter_pages
  for each row execute function public.set_updated_at();

create index if not exists chapter_pages_chapter_position_idx
  on public.chapter_pages (chapter_id, position);

-- 2. Row Level Security ------------------------------------------------------
-- Lecture pour tout apprenant connecté : le déverrouillage (chapitre payé,
-- vidéos regardées) reste appliqué côté application, comme pour chapters.

alter table public.chapter_pages enable row level security;

drop policy if exists "chapter_pages_select" on public.chapter_pages;
create policy "chapter_pages_select" on public.chapter_pages
  for select to authenticated
  using (true);

drop policy if exists "chapter_pages_admin_write" on public.chapter_pages;
create policy "chapter_pages_admin_write" on public.chapter_pages
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());
