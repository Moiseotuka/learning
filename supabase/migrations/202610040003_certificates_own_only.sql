-- Les certificats ne sont visibles que par leur propriétaire, y compris
-- pour les administrateurs (retrait de l'accès is_admin sur cette table).

drop policy if exists "certificates_select_own" on public.certificates;
create policy "certificates_select_own" on public.certificates
  for select to authenticated
  using (user_id = (select auth.uid()));
