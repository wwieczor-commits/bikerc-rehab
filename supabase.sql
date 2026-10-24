-- Baza pacjentów i zawodników BikeRc: tabele osób i sesji oraz zasady dostępu.
-- Wklej całość w Supabase → SQL Editor → New query → Run.

-- osoby: pacjenci (tryb Rehabilitacja) i zawodnicy (tryb Bike fitting)
create table if not exists public.osoby (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  utworzono       timestamptz not null default now(),
  zmieniono       timestamptz not null default now(),
  rodzaj          text not null default 'pacjent' check (rodzaj in ('pacjent','zawodnik')),
  imie_nazwisko   text not null,
  data_urodzenia  date,
  telefon         text,
  email           text,
  dane            jsonb not null default '{}'::jsonb
);

create index if not exists osoby_user_rodzaj on public.osoby (user_id, rodzaj, zmieniono desc);

-- sesje: zapisane pomiary i raporty danej osoby
create table if not exists public.sesje (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  osoba_id   uuid not null references public.osoby(id) on delete cascade,
  utworzono  timestamptz not null default now(),
  data       timestamptz not null default now(),
  tryb       text,
  test       text,
  dane       jsonb not null default '{}'::jsonb
);

create index if not exists sesje_osoba_data on public.sesje (osoba_id, data desc);
create index if not exists sesje_user on public.sesje (user_id);

-- data ostatniej zmiany osoby ustawia się sama
create or replace function public.osoby_zmieniono() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.zmieniono := now();
  return new;
end $$;

drop trigger if exists osoby_zmieniono on public.osoby;
create trigger osoby_zmieniono before update on public.osoby
  for each row execute function public.osoby_zmieniono();

-- każdy zalogowany widzi i zmienia tylko własne dane, niezalogowany nic
alter table public.osoby enable row level security;
alter table public.sesje enable row level security;

drop policy if exists "osoby odczyt" on public.osoby;
drop policy if exists "osoby dodanie" on public.osoby;
drop policy if exists "osoby zmiana" on public.osoby;
drop policy if exists "osoby usuniecie" on public.osoby;
create policy "osoby odczyt"     on public.osoby for select to authenticated using (user_id = (select auth.uid()));
create policy "osoby dodanie"    on public.osoby for insert to authenticated with check (user_id = (select auth.uid()));
create policy "osoby zmiana"     on public.osoby for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "osoby usuniecie"  on public.osoby for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists "sesje odczyt" on public.sesje;
drop policy if exists "sesje dodanie" on public.sesje;
drop policy if exists "sesje zmiana" on public.sesje;
drop policy if exists "sesje usuniecie" on public.sesje;
create policy "sesje odczyt"     on public.sesje for select to authenticated using (user_id = (select auth.uid()));
-- sesję można dopisać tylko do własnej osoby
create policy "sesje dodanie"    on public.sesje for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (select 1 from public.osoby o where o.id = osoba_id and o.user_id = (select auth.uid())));
create policy "sesje zmiana"     on public.sesje for update to authenticated using (user_id = (select auth.uid())) with check (
  user_id = (select auth.uid()) and exists (select 1 from public.osoby o where o.id = osoba_id and o.user_id = (select auth.uid())));
create policy "sesje usuniecie"  on public.sesje for delete to authenticated using (user_id = (select auth.uid()));

revoke all on public.osoby from anon;
revoke all on public.sesje from anon;
grant select, insert, update, delete on public.osoby to authenticated;
grant select, insert, update, delete on public.sesje to authenticated;
