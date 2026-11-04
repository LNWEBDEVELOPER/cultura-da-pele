-- Private calendar for the site owner; appointment contact details and notes are never public.
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  client_name text not null check (length(btrim(client_name)) between 1 and 120),
  client_contact text not null default '' check (length(client_contact) <= 80),
  starts_at timestamptz not null,
  duration_minutes integer not null default 60 check (duration_minutes between 15 and 480),
  status text not null default 'scheduled' check (status in ('scheduled','confirmed','completed','cancelled')),
  notes text not null default '' check (length(notes) <= 4000),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists appointments_starts_at_idx on public.appointments (starts_at);
alter table public.appointments enable row level security;
revoke all on table public.appointments from public, anon, authenticated;
grant select, insert, update, delete on table public.appointments to authenticated;
drop policy if exists "site owner reads appointments" on public.appointments;
create policy "site owner reads appointments" on public.appointments for select to authenticated
using (private.is_site_owner());
drop policy if exists "site owner creates appointments" on public.appointments;
create policy "site owner creates appointments" on public.appointments for insert to authenticated
with check (private.is_site_owner() and created_by=auth.uid());
drop policy if exists "site owner updates appointments" on public.appointments;
create policy "site owner updates appointments" on public.appointments for update to authenticated
using (private.is_site_owner()) with check (private.is_site_owner() and created_by=auth.uid());
drop policy if exists "site owner deletes appointments" on public.appointments;
create policy "site owner deletes appointments" on public.appointments for delete to authenticated
using (private.is_site_owner());