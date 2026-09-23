begin;
create extension if not exists pgcrypto;

alter table public.products alter column is_demo set default false;
drop policy if exists products_read_all on public.products;
create policy products_read_all on public.products for select using (true);

create table if not exists public.payment_methods (
  code text primary key check (code in ('moncash','moncash_ussd','natcash','kashpaw','carte','all')),
  name text not null,
  logo_url text check (logo_url is null or logo_url ~ '^https?://'),
  enabled boolean not null default false,
  sort_order integer not null default 0
);
insert into public.payment_methods(code,name,sort_order) values
  ('moncash','MonCash',1),('moncash_ussd','MonCash USSD',2),
  ('natcash','NatCash',3),('kashpaw','KashPaw',4),('carte','Carte / Square',5),('all','PLOP PLOP',6)
on conflict(code) do nothing;
alter table public.payment_methods enable row level security;
drop policy if exists payment_methods_read on public.payment_methods;
drop policy if exists payment_methods_admin on public.payment_methods;
create policy payment_methods_read on public.payment_methods for select using (true);
create policy payment_methods_admin on public.payment_methods for all using (public.is_admin()) with check (public.is_admin());

create table if not exists public.legal_documents (
  kind text not null check (kind in ('terms','privacy','support')),
  locale text not null check (locale in ('fr','ht','en','es')),
  title text not null,
  body text not null,
  updated_at timestamptz not null default now(),
  primary key(kind,locale)
);
alter table public.legal_documents enable row level security;
drop policy if exists legal_read on public.legal_documents;
drop policy if exists legal_admin on public.legal_documents;
create policy legal_read on public.legal_documents for select using (true);
create policy legal_admin on public.legal_documents for all using (public.is_admin()) with check (public.is_admin());

alter table public.orders add column if not exists checkout_key uuid;
alter table public.orders add column if not exists payment_status text not null default 'unpaid';
create unique index if not exists orders_checkout_unique on public.orders(user_id,checkout_key);

create table if not exists public.payments (
  order_id uuid primary key references public.orders(id),
  reference text not null unique,
  transaction_id text unique,
  amount numeric(10,2) not null check(amount >= 20),
  method text not null references public.payment_methods(code),
  status text not null default 'creating' check(status in ('creating','pending','paid','review')),
  redirect_url text,
  last_verified_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.payments enable row level security;
drop policy if exists payments_read on public.payments;
create policy payments_read on public.payments for select using (
  public.is_admin() or exists(select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
);

create table if not exists public.merchant_withdrawals (
  reference uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id),
  amount numeric(10,2) not null check(amount > 0),
  method text not null check(method in ('moncash','natcash')),
  recipient text not null check(recipient ~ '^509[0-9]{8}$'),
  status text not null default 'prepared' check(status in ('prepared','processing','pending','success','failed','remboursé')),
  transaction_id text,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.merchant_withdrawals enable row level security;
drop policy if exists withdrawals_admin_read on public.merchant_withdrawals;
create policy withdrawals_admin_read on public.merchant_withdrawals for select using(public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('payment-logos','payment-logos',true,2097152,array['image/png','image/jpeg','image/webp'])
on conflict(id) do nothing;
drop policy if exists payment_logos_read on storage.objects;
drop policy if exists payment_logos_insert on storage.objects;
drop policy if exists payment_logos_update on storage.objects;
create policy payment_logos_read on storage.objects for select using(bucket_id = 'payment-logos');
create policy payment_logos_insert on storage.objects for insert with check(bucket_id = 'payment-logos' and public.is_admin());
create policy payment_logos_update on storage.objects for update using(bucket_id = 'payment-logos' and public.is_admin()) with check(bucket_id = 'payment-logos' and public.is_admin());

revoke execute on function public.place_order(jsonb,numeric,text,text) from public,anon,authenticated;
drop policy if exists orders_owner_insert on public.orders;
drop policy if exists orders_owner_cancel on public.orders;
drop policy if exists orders_owner_update on public.orders;
drop policy if exists order_items_owner_insert on public.order_items;
drop policy if exists orders_admin_all on public.orders;
drop policy if exists order_items_admin_all on public.order_items;
drop policy if exists orders_admin_read on public.orders;
drop policy if exists order_items_admin_read on public.order_items;
create policy orders_admin_read on public.orders for select using(public.is_admin());
create policy order_items_admin_read on public.order_items for select using(public.is_admin());

create or replace function public.checkout_order(p_items jsonb,p_delivery_address text,p_payment_method text,p_checkout_key uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_item record;
  v_product public.products%rowtype;
  v_total numeric := 0;
begin
  if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required'; end if;
  if p_checkout_key is null then raise exception 'invalid_checkout_key'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  select id into v_id from public.orders where user_id = auth.uid() and checkout_key = p_checkout_key;
  if found then return v_id; end if;
  if (select count(*) from public.orders where user_id = auth.uid() and status = 'pending') >= 5 then raise exception 'pending_order_limit'; end if;
  if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'invalid_items'; end if;
  if length(trim(p_delivery_address)) not between 5 and 1000 or p_delivery_address is null then raise exception 'invalid_address'; end if;
  if not exists(select 1 from public.payment_methods where code = p_payment_method and enabled) then raise exception 'payment_method_disabled'; end if;
  insert into public.orders(user_id,total,delivery_address,payment_method,checkout_key)
  values(auth.uid(),0,trim(p_delivery_address),p_payment_method,p_checkout_key) returning id into v_id;
  for v_item in
    select (x->>'product_id')::uuid as pid, sum((x->>'quantity')::numeric) as qty
    from jsonb_array_elements(p_items) x group by 1 order by 1
  loop
    if v_item.qty is null or v_item.qty <> trunc(v_item.qty) or v_item.qty not between 1 and 999 then raise exception 'invalid_quantity'; end if;
    select * into v_product from public.products where id = v_item.pid and is_demo = false for update;
    if not found or v_product.price <= 0 then raise exception 'product_not_found'; end if;
    if v_product.stock < v_item.qty then raise exception 'insufficient_stock'; end if;
    update public.products set stock = stock - v_item.qty::int where id = v_item.pid;
    insert into public.order_items(order_id,product_id,quantity,unit_price) values(v_id,v_item.pid,v_item.qty::int,v_product.price);
    v_total := v_total + v_product.price * v_item.qty;
  end loop;
  if v_total < 20 then raise exception 'minimum_amount_20'; end if;
  update public.orders set total = v_total where id = v_id;
  return v_id;
end;
$$;
revoke all on function public.checkout_order(jsonb,text,text,uuid) from public,anon;
grant execute on function public.checkout_order(jsonb,text,text,uuid) to authenticated;

create or replace function public.claim_payment(p_order_id uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_order.status <> 'pending' or v_order.payment_status <> 'unpaid' then return false; end if;
  insert into public.payments(order_id,reference,amount,method) values(v_order.id,'PAY-' || v_order.id,v_order.total,v_order.payment_method) on conflict(order_id) do nothing;
  return found;
end;
$$;
revoke all on function public.claim_payment(uuid) from public,anon,authenticated;
grant execute on function public.claim_payment(uuid) to service_role;

create or replace function public.apply_payment(p_reference text,p_transaction text,p_amount numeric,p_paid boolean)
returns void language plpgsql security definer set search_path = public as $$
declare v_payment public.payments%rowtype;
begin
  select * into v_payment from public.payments where reference = p_reference for update;
  if not found or v_payment.amount <> p_amount or p_transaction is null or p_transaction = '' or (v_payment.transaction_id is not null and v_payment.transaction_id <> p_transaction) then raise exception 'payment_mismatch'; end if;
  update public.payments set transaction_id = p_transaction,
    status = case when p_paid then 'paid' when status = 'paid' then 'review' when status = 'review' then 'review' else 'pending' end,
    last_verified_at = now() where order_id = v_payment.order_id;
  update public.orders set payment_status = case when p_paid then 'paid' when payment_status in ('paid','review') then 'review' else 'pending' end,
    status = case when p_paid and status = 'pending' then 'confirmed' else status end where id = v_payment.order_id;
end;
$$;
revoke all on function public.apply_payment(text,text,numeric,boolean) from public,anon,authenticated;
grant execute on function public.apply_payment(text,text,numeric,boolean) to service_role;

create or replace function public.change_order_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare v_order public.orders%rowtype;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or auth.uid() is null or (v_order.user_id is distinct from auth.uid() and not public.is_admin()) then raise exception 'access_denied'; end if;
  if p_status = v_order.status then return; end if;
  if p_status = 'cancelled' then
    -- Bloke sèlman si yon tranzaksyon founisè egziste (payment kòmanse vre).
    -- Yon ranje 'creating' san transaction_id vle di apèl la pa janm rive founisè a.
    if v_order.status <> 'pending'
       or exists(select 1 from public.payments where order_id = p_order_id and transaction_id is not null)
    then raise exception 'payment_reconciliation_required'; end if;
    update public.products p set stock = p.stock + i.quantity from public.order_items i where i.order_id = p_order_id and i.product_id = p.id;
  elsif not public.is_admin() or v_order.payment_status <> 'paid' or not (
    (v_order.status = 'confirmed' and p_status = 'shipped') or (v_order.status = 'shipped' and p_status = 'delivered')
      or (v_order.status = 'cancelled' and p_status = 'cancelled')
  ) then raise exception 'invalid_transition';
  end if;
  update public.orders set status = p_status where id = p_order_id;
end;
$$;
revoke all on function public.change_order_status(uuid,text) from public,anon;
grant execute on function public.change_order_status(uuid,text) to authenticated;

create or replace function public.claim_withdrawal(p_reference uuid)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  perform pg_advisory_xact_lock(73489125);
  if exists(select 1 from public.merchant_withdrawals where status <> 'prepared' and updated_at > now() - interval '120 seconds') then raise exception 'WITHDRAWAL_COOLDOWN'; end if;
  update public.merchant_withdrawals set status = 'processing',updated_at = now() where reference = p_reference and status = 'prepared' and created_at > now() - interval '10 minutes';
  return found;
end;
$$;
revoke all on function public.claim_withdrawal(uuid) from public,anon,authenticated;
grant execute on function public.claim_withdrawal(uuid) to service_role;

alter table public.orders drop constraint if exists orders_user_id_fkey;
alter table public.orders add constraint orders_user_id_fkey foreign key(user_id) references auth.users(id) on delete set null;
create or replace function public.before_account_delete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists(select 1 from public.admin_users where email = old.email) then raise exception 'admin_deletion_requires_transfer'; end if;
  if exists(select 1 from public.orders where user_id = old.id and (status not in ('delivered','cancelled') or payment_status = 'review')) then raise exception 'active_orders'; end if;
  update public.orders set delivery_address = null where user_id = old.id;
  return old;
end;
$$;
drop trigger if exists before_account_delete on auth.users;
create trigger before_account_delete before delete on auth.users for each row execute function public.before_account_delete();

commit;
