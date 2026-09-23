-- ============================================================
-- REDLIGHT AUTOMOTIVE — 05_seed.sql
-- Done demo / Katalòg inisyal: 5 kategori + 13 pwodwi.
-- Korije RLS pou tout vizitè ka wè kategori ak pwodwi yo avèk foto yo.
-- ============================================================

-- 1. Asire RLS aktive epi pèmèt lekti piblik pou Kategori ak Pwodwi
alter table if exists public.categories enable row level security;
drop policy if exists "categories_read_all" on public.categories;
create policy "categories_read_all" on public.categories for select using (true);

alter table if exists public.products enable row level security;
drop policy if exists "products_read_all" on public.products;
create policy "products_read_all" on public.products for select using (true);

-- 2. Mete Kategori yo (avèk upsert pou garanti yo egziste toujou)
insert into public.categories (name, icon) values
  ('Motè',        'cog'),
  ('Fren',        'disc'),
  ('Batri',       'battery'),
  ('Lwil/Filtè',  'droplet'),
  ('Akseswa',     'tag')
on conflict (name) do update set icon = excluded.icon;

-- 3. Netwaye pwodwi demo anvan yo pou evite kopi oswa konfli
delete from public.products
where is_demo = true
   or name in (
     'Filtr lwil motè',
     'Plaqèt fren avan (set)',
     'Batri 12V 70Ah',
     'Kit distribisyon konplè',
     'Altènatè 90A',
     'Bobin alimaj (pake 4)',
     'Ponp gaz elektrik',
     'Amortisè avan (pè)',
     'Radyatè aliminyòm',
     'Disk fren dèyè (pè)',
     'Filtr lè kabin',
     'Lanp LED H4 (pè)',
     'Kouvri volan kwi'
   );

-- 4. Mete 13 pwodwi yo avèk imaj ak kategori korespondan yo (is_demo = false pou konpatibilite total)
insert into public.products (name, description, price, stock, category_id, compatible_models, images, is_demo)
select
  p.name,
  p.description,
  p.price,
  p.stock,
  c.id,
  p.compatible_models,
  p.images,
  false
from (values
  ('Filtr lwil motè',
   'Filtr lwil OEM kalite siperyè. Pwoteje motè ou kont pousyè ak metal. Ranplase chak 5 000 km.',
   850.00, 40, 'Lwil/Filtè',
   array['Toyota Corolla 2015-2020','Honda Civic 2016-2021','Nissan Sentra 2014-2019'],
   array['https://picsum.photos/seed/oilfilter/600/600']),
  ('Plaqèt fren avan (set)',
   'Set 4 plaqèt fren seramik. Perfòmans frenaj solid, mwens pousyè, silansye.',
   3500.00, 25, 'Fren',
   array['Toyota Corolla 2015-2020','Toyota Camry 2016-2019'],
   array['https://picsum.photos/seed/brakepad/600/600']),
  ('Batri 12V 70Ah',
   'Batri san antretyen, 70Ah, 660 CCA. Garanti 18 mwa.',
   12000.00, 12, 'Batri',
   array['Universal'],
   array['https://picsum.photos/seed/battery12v/600/600']),
  ('Kit distribisyon konplè',
   'Kouroua + tansyonè + ponp dlo. Orijin ekwivalan OEM.',
   8500.00, 8, 'Motè',
   array['Honda Civic 2016-2021','Honda Accord 2018-2022'],
   array['https://picsum.photos/seed/timingkit/600/600']),
  ('Altènatè 90A',
   'Altènatè rebati, teste 100%. 90 amp.',
   15000.00, 5, 'Motè',
   array['Nissan Sentra 2014-2019','Nissan Versa 2015-2020'],
   array['https://picsum.photos/seed/alternator/600/600']),
  ('Bobin alimaj (pake 4)',
   'Pake 4 bobin alimaj. Elimine raté alimaj, fè ekonomi gaz.',
   6000.00, 15, 'Motè',
   array['Hyundai Tucson 2016-2021','Hyundai Elantra 2017-2020'],
   array['https://picsum.photos/seed/coilpack/600/600']),
  ('Ponp gaz elektrik',
   'Ponp gaz in-tank, presyon estab. Enstalasyon dirèk.',
   9500.00, 10, 'Motè',
   array['Toyota Hilux 2016-2023','Toyota Tacoma 2016-2022'],
   array['https://picsum.photos/seed/fuelpump/600/600']),
  ('Amortisè avan (pè)',
   'Pè amortisè gaz avan. Konfò ak estabilite sou wout nou yo.',
   4200.00, 18, 'Akseswa',
   array['Honda CR-V 2017-2022'],
   array['https://picsum.photos/seed/shock/600/600']),
  ('Radyatè aliminyòm',
   'Radyatè tout-aliminyòm, refwadisman maksimòm pou klima cho.',
   11000.00, 7, 'Motè',
   array['Kia Sportage 2017-2022','Kia Sorento 2016-2020'],
   array['https://picsum.photos/seed/radiator/600/600']),
  ('Disk fren dèyè (pè)',
   'Pè disk fren vantile, anviwònman anti-rouye.',
   2800.00, 20, 'Fren',
   array['Toyota Corolla 2015-2020','Honda Civic 2016-2021'],
   array['https://picsum.photos/seed/brakedisc/600/600']),
  ('Filtr lè kabin',
   'Filtr lè kabin ak kabòn aktif. Lè pi pwòp nan machin ou.',
   650.00, 50, 'Lwil/Filtè',
   array['Universal'],
   array['https://picsum.photos/seed/cabinfilter/600/600']),
  ('Lanp LED H4 (pè)',
   'Pè lanp LED H4, 6000K blan frè. 3x pi klere pase alojèn.',
   2800.00, 30, 'Akseswa',
   array['Universal'],
   array['https://picsum.photos/seed/ledh4/600/600']),
  ('Kouvri volan kwi',
   'Kouvri volan kwi natirèl, grip solid, konfòtab.',
   1200.00, 35, 'Akseswa',
   array['Universal'],
   array['https://picsum.photos/seed/wheelcover/600/600'])
) as p(name, description, price, stock, category_name, compatible_models, images)
  join public.categories c on c.name = p.category_name;
