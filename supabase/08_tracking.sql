begin;

-- ============================================================
-- REDLIGHT AUTOPARTS — 08_tracking.sql
-- Swivi koli (tracking): pozisyon + ETA + istorik etap.
-- Admin lan mete ajou; kliyan an li pou kòmand li sèlman.
-- Egzekite APRE 06_commerce.sql nan Supabase SQL Editor.
-- ============================================================

-- Pozisyon kounye a nan koli a (1 ranje pa kòmand).
create table if not exists public.order_tracking (
  order_id uuid primary key references public.orders(id) on delete cascade,
  location text,                        -- tèks lib: "Okap — Wout Nasyonal 1"
  latitude double precision,
  longitude double precision,
  eta_at timestamptz,                   -- dat/lè livrezon estime
  delay_note text,                      -- anprevu siyale pa admin (null = pa gen)
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

alter table public.order_tracking enable row level security;

drop policy if exists order_tracking_read on public.order_tracking;
drop policy if exists order_tracking_admin_write on public.order_tracking;

create policy order_tracking_read on public.order_tracking for select using (
  public.is_admin()
  or exists(
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);
create policy order_tracking_admin_write on public.order_tracking for all
  using (public.is_admin())
  with check (public.is_admin());

-- Istorik etap yo (checkpoint / anprevu) — timeline pou kliyan an.
create table if not exists public.order_tracking_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  kind text not null default 'checkpoint'
    check (kind in ('checkpoint', 'delay')),
  location text,
  note text,
  latitude double precision,
  longitude double precision,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists order_tracking_events_order_idx
  on public.order_tracking_events(order_id, created_at desc);

alter table public.order_tracking_events enable row level security;

drop policy if exists tracking_events_read on public.order_tracking_events;
drop policy if exists tracking_events_admin_write on public.order_tracking_events;

create policy tracking_events_read on public.order_tracking_events for select using (
  public.is_admin()
  or exists(
    select 1 from public.orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);
create policy tracking_events_admin_write on public.order_tracking_events for all
  using (public.is_admin())
  with check (public.is_admin());

commit;
