begin;

-- 1. Retire atik kòmand ki pointe sou pwodwi demo (FK order_items.product_id).
delete from public.order_items i
using public.products p
where i.product_id = p.id and p.is_demo = true;

-- 2. Retire peman pou kòmand ki vid nèt (te gen sèlman pwodwi demo).
delete from public.payments pay
where exists (
  select 1 from public.orders o
  where o.id = pay.order_id
    and not exists (select 1 from public.order_items i where i.order_id = o.id)
);

-- 3. Retire kòmand ki pa gen okenn atik ankò (kòmand demo).
delete from public.orders o
where not exists (select 1 from public.order_items i where i.order_id = o.id);

-- 4. Retire pwodwi demo yo.
delete from public.products where is_demo = true;

-- 5. Retire kategori ki rete vid (san pwodwi reyèl).
delete from public.categories c
where not exists (select 1 from public.products p where p.category_id = c.id);

commit;
