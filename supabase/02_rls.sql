-- ============================================================
-- REDLIGHT AUTOMOTIVE — 02_rls.sql
-- Row Level Security + fonksyon is_admin() + place_order().
-- Egzekite APRE 01_schema.sql.
-- ============================================================

alter table categories  enable row level security;
alter table products    enable row level security;
alter table orders      enable row level security;
alter table order_items enable row level security;
alter table admin_users enable row level security;

-- ------------------------------------------------------------
-- is_admin() — true si email itilizatè konekte a nan admin_users.
-- security definer: li ka li admin_users menm si RLS bloke li.
-- ------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users
    where email = auth.jwt() ->> 'email'
  );
$$;

-- ------------------------------------------------------------
-- categories / products : tout moun ka li, sèlman admin ka ekri
-- ------------------------------------------------------------
drop policy if exists "categories_read_all" on categories;
create policy "categories_read_all"
  on categories for select using (true);

drop policy if exists "categories_admin_write" on categories;
create policy "categories_admin_write"
  on categories for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "products_read_all" on products;
create policy "products_read_all"
  on products for select using (true);

drop policy if exists "products_admin_write" on products;
create policy "products_admin_write"
  on products for all
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- orders : pwopriyetè ka li / kreye / kansèle (pending -> cancelled)
--          admin ka fè tout bagay
-- ------------------------------------------------------------
drop policy if exists "orders_owner_read" on orders;
create policy "orders_owner_read"
  on orders for select
  using (auth.uid() = user_id);

drop policy if exists "orders_owner_insert" on orders;
create policy "orders_owner_insert"
  on orders for insert
  with check (auth.uid() = user_id);

-- Kliyan ka sèlman kansèle yon kòmand ki toujou "pending".
drop policy if exists "orders_owner_cancel" on orders;
create policy "orders_owner_cancel"
  on orders for update
  using (auth.uid() = user_id and status = 'pending')
  with check (auth.uid() = user_id and status = 'cancelled');

drop policy if exists "orders_admin_all" on orders;
create policy "orders_admin_all"
  on orders for all
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- order_items : aksè atravè kòmand paran an
-- ------------------------------------------------------------
drop policy if exists "order_items_owner_read" on order_items;
create policy "order_items_owner_read"
  on order_items for select
  using (exists (
    select 1 from orders o
    where o.id = order_items.order_id and o.user_id = auth.uid()
  ));

drop policy if exists "order_items_owner_insert" on order_items;
create policy "order_items_owner_insert"
  on order_items for insert
  with check (exists (
    select 1 from orders o
    where o.id = order_items.order_id and o.user_id = auth.uid()
  ));

drop policy if exists "order_items_admin_all" on order_items;
create policy "order_items_admin_all"
  on order_items for all
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------
-- admin_users : sèlman admin ka li lis la (li tèt li / lòt admin)
-- ------------------------------------------------------------
drop policy if exists "admin_users_admin_read" on admin_users;
create policy "admin_users_admin_read"
  on admin_users for select
  using (public.is_admin());

-- ------------------------------------------------------------
-- place_order() — kòmand atomik: insert order + items + degrese stock.
-- security definer pou li ka modifye products.stock san admin.
-- Si stock pa ase oswa pwodwi pa egziste -> exception, tout bagay woule bak.
-- p_items format: [{"product_id":"uuid","quantity":2,"unit_price":1500.00}, ...]
-- ------------------------------------------------------------
create or replace function public.place_order(
  p_items jsonb,
  p_total numeric,
  p_delivery_address text,
  p_payment_method text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_item jsonb;
  v_stock int;
  v_pid uuid;
  v_qty int;
begin
  insert into orders (user_id, total, delivery_address, payment_method)
  values (auth.uid(), p_total, p_delivery_address, p_payment_method)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_pid := (v_item ->> 'product_id')::uuid;
    v_qty := (v_item ->> 'quantity')::int;

    select stock into v_stock
    from products where id = v_pid
    for update;

    if v_stock is null then
      raise exception 'product_not_found: %', v_pid;
    end if;
    if v_stock < v_qty then
      raise exception 'insufficient_stock: %', v_pid;
    end if;

    update products set stock = stock - v_qty where id = v_pid;

    insert into order_items (order_id, product_id, quantity, unit_price)
    values (v_order_id, v_pid, v_qty, (v_item ->> 'unit_price')::numeric);
  end loop;

  return v_order_id;
end;
$$;
