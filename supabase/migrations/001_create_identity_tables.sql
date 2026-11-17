
-- =========================================================
-- 001: Identity tables
-- Shopverse
-- =========================================================

-- 1. Account status

create type public.account_status as enum (
  'active',
  'suspended',
  'deactivated',
  'pending_deletion'
);

-- 2. Automatic updated_at handling

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- 3. Users
-- Supabase Auth remains the authentication source of truth.

create table public.users (
  id uuid primary key
    references auth.users(id) on delete restrict,

  email text not null unique,
  display_name text,
  avatar_url text,

  status public.account_status not null default 'active',
  status_reason text,
  deletion_requested_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Customer profiles

create table public.customer_profiles (
  user_id uuid primary key
    references public.users(id) on delete restrict,

  phone text,
  phone_verified_at timestamptz,

  marketing_emails_enabled boolean not null default false,

  preferred_currency varchar(3) not null default 'USD'
    check (preferred_currency ~ '^[A-Z]{3}$'),

  preferred_locale text not null default 'en',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. Auth user creation handler
-- Every new Supabase Auth user receives a Shopverse identity
-- and customer profile.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_display_name text;
  resolved_avatar_url text;
begin
  resolved_display_name := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name'
  );

  resolved_avatar_url := coalesce(
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'picture'
  );

  insert into public.users (
    id,
    email,
    display_name,
    avatar_url
  )
  values (
    new.id,
    new.email,
    resolved_display_name,
    resolved_avatar_url
  );

  insert into public.customer_profiles (user_id)
  values (new.id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_auth_user();

-- 6. Synchronize Auth email and profile metadata changes

create or replace function public.sync_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.users
  set
    email = new.email,
    display_name = coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ),
    avatar_url = coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    ),
    updated_at = now()
  where id = new.id;

  return new;
end;
$$;

create trigger on_auth_user_updated
  after update of email, raw_user_meta_data
  on auth.users
  for each row
  execute function public.sync_auth_user();

-- 7. Updated_at triggers

create trigger set_users_updated_at
  before update on public.users
  for each row
  execute function public.set_updated_at();

create trigger set_customer_profiles_updated_at
  before update on public.customer_profiles
  for each row
  execute function public.set_updated_at();

-- 8. Indexes

create index users_status_idx
  on public.users(status);

create index customer_profiles_phone_idx
  on public.customer_profiles(phone)
  where phone is not null;

-- 9. Enable Row Level Security

alter table public.users enable row level security;
alter table public.customer_profiles enable row level security;

-- 10. Explicit Data API privileges

grant select on public.users to authenticated;

grant select, insert, update
  on public.customer_profiles to authenticated;

-- 11. RLS policies

create policy "Users can view their own identity"
  on public.users
  for select
  to authenticated
  using (id = (select auth.uid()));

create policy "Customers can view their own profile"
  on public.customer_profiles
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Customers can create their own profile"
  on public.customer_profiles
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Customers can update their own profile"
  on public.customer_profiles
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
