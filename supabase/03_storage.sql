-- ============================================================
-- REDLIGHT AUTOMOTIVE — 03_storage.sql
-- Bucket 'product-images': lekti piblik, ekriti sèlman admin.
-- Egzekite APRE 02_rls.sql (is_admin() dwe egziste deja).
-- ============================================================

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- Tout moun ka li imaj yo (bucket piblik)
drop policy if exists "product_images_read" on storage.objects;
create policy "product_images_read"
  on storage.objects for select
  using (bucket_id = 'product-images');

-- Sèlman admin ka upload / modifye / efase
drop policy if exists "product_images_admin_insert" on storage.objects;
create policy "product_images_admin_insert"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_admin_update" on storage.objects;
create policy "product_images_admin_update"
  on storage.objects for update
  using (bucket_id = 'product-images' and public.is_admin())
  with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "product_images_admin_delete" on storage.objects;
create policy "product_images_admin_delete"
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.is_admin());
