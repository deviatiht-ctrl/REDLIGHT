begin;

-- ============================================================
-- REDLIGHT AUTOPARTS — 10_payment_verification.sql
-- Verifikasyon peman ki pa bloke sou PAYMENT_MISMATCH:
--  * kenbe ID depa (paiement-marchand) AK ID verify (paiement-verify)
--  * anrejistre chak verifikasyon nan payment_checks (istorik)
--  * montan ki pa koresponn -> 'review' olye erè
-- Egzekite APRE 06_commerce.sql, ANVAN ou redeplwaye fonksyon `commerce` la.
-- ============================================================

alter table public.payments add column if not exists provider_transaction_id text;
alter table public.payments add column if not exists provider_status text;
alter table public.payments add column if not exists provider_method text;
alter table public.payments add column if not exists paid_amount numeric(10,2);
alter table public.payments add column if not exists last_error text;
alter table public.payments add column if not exists verify_attempts integer not null default 0;
update public.payments set provider_transaction_id = transaction_id
  where provider_transaction_id is null and transaction_id is not null;

create table if not exists public.payment_checks (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.payments(order_id) on delete cascade,
  reference text not null,
  source text not null check (source in ('client','webhook','cron','start','admin')),
  result text not null check (result in ('paid','pending','failed','mismatch','error')),
  provider_status text,
  transaction_id text,
  amount numeric(10,2),
  method text,
  error text,
  raw jsonb,
  created_at timestamptz not null default now()
);
create index if not exists payment_checks_order_idx on public.payment_checks(order_id, created_at desc);
create index if not exists payment_checks_transaction_idx on public.payment_checks(transaction_id);
alter table public.payment_checks enable row level security;
drop policy if exists payment_checks_admin_read on public.payment_checks;
create policy payment_checks_admin_read on public.payment_checks for select using (public.is_admin());

drop function if exists public.apply_payment(text,text,numeric,boolean);
create or replace function public.apply_payment(
  p_reference text,
  p_transaction text,
  p_amount numeric,
  p_paid boolean,
  p_provider_status text default null,
  p_method text default null,
  p_source text default 'client',
  p_raw jsonb default null
)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_payment public.payments%rowtype;
  v_tx text := nullif(trim(coalesce(p_transaction, '')), '');
  v_provider_status text := nullif(lower(trim(coalesce(p_provider_status, ''))), '');
  v_source text := case when p_source in ('client','webhook','cron','start','admin') then p_source else 'client' end;
  v_result text;
  v_error text;
  v_status text;
begin
  select * into v_payment from public.payments where reference = p_reference for update;
  if not found then raise exception 'payment_not_found'; end if;

  -- Menm ID tranzaksyon an pa ka peye 2 kòmand diferan.
  if v_tx is not null and exists(select 1 from public.payments where transaction_id = v_tx and order_id <> v_payment.order_id) then
    v_result := 'mismatch'; v_error := 'TRANSACTION_ID_USED_BY_OTHER_ORDER'; v_tx := null;
  elsif p_paid and (p_amount is null or round(p_amount, 2) <> round(v_payment.amount, 2)) then
    v_result := 'mismatch'; v_error := 'AMOUNT_MISMATCH';
  elsif p_paid then
    v_result := 'paid';
  elsif v_provider_status in ('failed','fail','echec','error','cancelled','canceled','rejected') then
    v_result := 'failed';
  else
    v_result := 'pending';
  end if;

  update public.payments set
    transaction_id = coalesce(v_tx, transaction_id),
    provider_transaction_id = coalesce(provider_transaction_id, v_tx),
    provider_status = v_provider_status,
    provider_method = coalesce(nullif(trim(coalesce(p_method, '')), ''), provider_method),
    paid_amount = coalesce(p_amount, paid_amount),
    status = case
      when v_result = 'paid' then 'paid'
      when v_result = 'mismatch' then 'review'
      when status in ('paid','review') then 'review'
      else 'pending' end,
    last_error = v_error,
    last_verified_at = now(),
    verify_attempts = verify_attempts + 1
  where order_id = v_payment.order_id
  returning status into v_status;

  update public.orders set
    payment_status = v_status,
    status = case when v_status = 'paid' and status = 'pending' then 'confirmed' else status end
  where id = v_payment.order_id;

  insert into public.payment_checks(order_id, reference, source, result, provider_status, transaction_id, amount, method, error, raw)
  values (v_payment.order_id, v_payment.reference, v_source, v_result, v_provider_status,
          nullif(trim(coalesce(p_transaction, '')), ''), p_amount, p_method, v_error, p_raw);

  return v_result;
end;
$$;
revoke all on function public.apply_payment(text,text,numeric,boolean,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.apply_payment(text,text,numeric,boolean,text,text,text,jsonb) to service_role;

commit;

-- ============================================================
-- VERIFIKASYON OTOMATIK (chak 5 minit) — egzekite APA, apre:
--   1. mete sekrè `PLOP_RECONCILE_SECRET` nan Edge Functions → Secrets
--   2. ranplase <PROJECT_REF> ak <PLOP_RECONCILE_SECRET> anba a
-- ============================================================
-- create extension if not exists pg_cron;
-- create extension if not exists pg_net;
-- select cron.unschedule('redlight-reconcile-payments') where exists (select 1 from cron.job where jobname = 'redlight-reconcile-payments');
-- select vault.create_secret('<PLOP_RECONCILE_SECRET>', 'redlight_reconcile_secret');
-- select cron.schedule('redlight-reconcile-payments', '*/5 * * * *', $cron$
--   select net.http_post(
--     url := 'https://<PROJECT_REF>.supabase.co/functions/v1/commerce',
--     headers := jsonb_build_object('Content-Type', 'application/json',
--       'X-Reconcile-Secret', (select decrypted_secret from vault.decrypted_secrets where name = 'redlight_reconcile_secret')),
--     body := '{"action":"payment.reconcile","days":7}'::jsonb,
--     timeout_milliseconds := 60000
--   );
-- $cron$);
