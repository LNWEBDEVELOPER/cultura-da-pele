-- Run once in Supabase SQL Editor for the Art of Tatto project.
create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'artist' check (role in ('owner','artist')),
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  notified_at timestamptz
);

create or replace function private.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id,email) values (new.id, lower(new.email));
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users
for each row execute function private.create_profile_for_new_user();

create or replace function private.is_site_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='owner' and approval_status='approved');
$$;
create or replace function private.can_manage_portfolio()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id=auth.uid() and approval_status='approved');
$$;

create table if not exists public.tattoos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  style text not null default '',
  image_url text not null,
  image_path text not null,
  created_by uuid references public.profiles(id),
  published boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.tattoos enable row level security;
drop policy if exists "profile self or owner read" on public.profiles;
create policy "profile self or owner read" on public.profiles for select to authenticated
using (id=auth.uid() or private.is_site_owner());
drop policy if exists "owner reviews access requests" on public.profiles;
create policy "owner reviews access requests" on public.profiles for update to authenticated
using (private.is_site_owner()) with check (private.is_site_owner());

drop policy if exists "public sees published tattoos" on public.tattoos;
create policy "public sees published tattoos" on public.tattoos for select to anon, authenticated using (published=true);
drop policy if exists "approved account adds tattoos" on public.tattoos;
create policy "approved account adds tattoos" on public.tattoos for insert to authenticated
with check (private.can_manage_portfolio() and created_by=auth.uid());
drop policy if exists "creator or owner edits tattoos" on public.tattoos;
create policy "creator or owner edits tattoos" on public.tattoos for update to authenticated
using (created_by=auth.uid() or private.is_site_owner())
with check (private.can_manage_portfolio() and (created_by=auth.uid() or private.is_site_owner()));
drop policy if exists "creator or owner deletes tattoos" on public.tattoos;
create policy "creator or owner deletes tattoos" on public.tattoos for delete to authenticated
using ((created_by=auth.uid() and private.can_manage_portfolio()) or private.is_site_owner());

create or replace function public.review_access_request(request_user_id uuid, decision text)
returns void language plpgsql security invoker set search_path = '' as $BODY$
begin
  if not private.is_site_owner() then raise exception 'Only the site owner can review access requests'; end if;
  if decision not in ('approved','rejected') then raise exception 'Invalid decision'; end if;
  update public.profiles set approval_status=decision where id=request_user_id and role='artist';
  if not found then raise exception 'Request not found'; end if;
end;
$BODY$;
revoke all on function public.review_access_request(uuid,text) from public, anon;
grant execute on function public.review_access_request(uuid,text) to authenticated;
grant select on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update (approval_status) on public.profiles to authenticated;
grant select on public.tattoos to anon, authenticated;
grant insert, update, delete on public.tattoos to authenticated;

revoke all on function private.create_profile_for_new_user() from public, anon, authenticated;
revoke all on function private.is_site_owner() from public, anon, authenticated;
revoke all on function private.can_manage_portfolio() from public, anon, authenticated;
grant execute on function private.is_site_owner() to authenticated;
grant execute on function private.can_manage_portfolio() to authenticated;

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

-- Public image bucket; uploads are restricted to approved accounts.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('tattoo-images','tattoo-images',true,8388608,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=8388608,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "public reads tattoo images" on storage.objects;
create policy "public reads tattoo images" on storage.objects for select to anon,authenticated using (bucket_id='tattoo-images');
drop policy if exists "approved accounts upload tattoo images" on storage.objects;
create policy "approved accounts upload tattoo images" on storage.objects for insert to authenticated
with check (bucket_id='tattoo-images' and private.can_manage_portfolio() and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "owner or uploader removes tattoo images" on storage.objects;
create policy "owner or uploader removes tattoo images" on storage.objects for delete to authenticated
using (bucket_id='tattoo-images' and (owner_id=auth.uid()::text or private.is_site_owner()));

-- Add the site owner only after that person has registered and confirmed their email.
-- Run this line after replacing the email with yours:
-- update public.profiles set role='owner', approval_status='approved' where email=lower('luannascimentopsp@gmail.com');

-- Seed the three existing conceptual example cards from the current public site.
insert into public.tattoos(title,style,image_url,image_path,created_by,published)
select v.title,v.style,v.image_url,'seed/'||v.file_name,null,true
from (values
 ('Blackwork ornamental','Estudo visual · blackwork','https://lnwebdeveloper.github.io/cultura-da-pele/assets/blackwork-editorial.jpg','blackwork-editorial.jpg'),
 ('Botânica fine line','Estudo visual · fine line','https://lnwebdeveloper.github.io/cultura-da-pele/assets/cultura-da-pele-hero.jpg','cultura-da-pele-hero.jpg'),
 ('Ornamental blackwork','Estudo visual · ornamental','https://lnwebdeveloper.github.io/cultura-da-pele/assets/blackwork-editorial.jpg','blackwork-editorial.jpg')
) as v(title,style,image_url,file_name)
where not exists(select 1 from public.tattoos where title=v.title);

