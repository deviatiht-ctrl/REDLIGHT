-- ============================================================
-- REDLIGHT AUTOMOTIVE — 04_admin.sql
-- ⚠️  RANPLASE email anba a ak email admin reyèl la ANVAN egzekite.
--     Email la dwe menm ak kont Supabase Auth admin an.
-- ============================================================

insert into admin_users (email)
values ('EMAIL_ADMIN_LA@example.com')
on conflict (email) do nothing;
