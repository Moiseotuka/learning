-- Correction du lot formateur : récursion infinie des policies RLS.
--
-- « instructor_classes_select » regardait « instructor_class_members » pour
-- savoir si l'élève est inscrit, et « instructor_class_members_select »
-- regardait « instructor_classes » pour savoir qui est le formateur. Chaque
-- policy évaluait donc la policy de l'autre table : toute lecture en
-- embarquant une seconde (liste des classes d'un formateur, élèves d'une
-- classe, séances d'une classe) échouait en HTTP 500 — « infinite recursion
-- detected in policy for relation "instructor_class_members" ».
--
-- Les appartenances sont maintenant lues par des fonctions security definer :
-- elles interrogent la table directement, sans réévaluer de policy, et le
-- cycle est coupé.

create or replace function public.owns_class(p_class uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.instructor_classes c
    where c.id = p_class
      and c.instructor_id = auth.uid()
  );
$$;

create or replace function public.is_class_member(p_class uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.instructor_class_members m
    where m.class_id = p_class
      and m.user_id = auth.uid()
      and m.status = 'active'
  );
$$;

create or replace function public.owns_session(p_session uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.live_sessions s
    where s.id = p_session
      and s.instructor_id = auth.uid()
  );
$$;

create or replace function public.owns_subscription(p_subscription uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.instructor_subscriptions s
    where s.id = p_subscription
      and s.user_id = auth.uid()
  );
$$;

revoke all on function public.owns_class(uuid) from public;
revoke all on function public.is_class_member(uuid) from public;
revoke all on function public.owns_session(uuid) from public;
revoke all on function public.owns_subscription(uuid) from public;

grant execute on function public.owns_class(uuid) to anon, authenticated;
grant execute on function public.is_class_member(uuid) to anon, authenticated;
grant execute on function public.owns_session(uuid) to anon, authenticated;
grant execute on function public.owns_subscription(uuid) to anon, authenticated;

drop policy if exists "instructor_subscription_tracks_select_own" on public.instructor_subscription_tracks;
create policy "instructor_subscription_tracks_select_own" on public.instructor_subscription_tracks
  for select to authenticated
  using (public.is_admin() or public.owns_subscription(subscription_id));

drop policy if exists "instructor_classes_select" on public.instructor_classes;
create policy "instructor_classes_select" on public.instructor_classes
  for select to authenticated
  using (
    public.is_admin()
    or instructor_id = (select auth.uid())
    or public.is_class_member(id)
  );

drop policy if exists "instructor_class_members_select" on public.instructor_class_members;
create policy "instructor_class_members_select" on public.instructor_class_members
  for select to authenticated
  using (
    public.is_admin()
    or user_id = (select auth.uid())
    or public.owns_class(class_id)
  );

drop policy if exists "instructor_class_invites_select" on public.instructor_class_invites;
create policy "instructor_class_invites_select" on public.instructor_class_invites
  for select to authenticated
  using (public.is_admin() or public.owns_class(class_id));

drop policy if exists "live_sessions_select" on public.live_sessions;
create policy "live_sessions_select" on public.live_sessions
  for select to authenticated
  using (
    public.is_admin()
    or instructor_id = (select auth.uid())
    or public.is_class_member(class_id)
  );

drop policy if exists "live_session_attendance_select" on public.live_session_attendance;
create policy "live_session_attendance_select" on public.live_session_attendance
  for select to authenticated
  using (
    public.is_admin()
    or user_id = (select auth.uid())
    or public.owns_session(session_id)
  );
