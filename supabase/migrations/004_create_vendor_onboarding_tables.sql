
-- =========================================================
-- 004: Vendor onboarding infrastructure
-- Shopverse
-- =========================================================

-- 1. Vendor status

create type public.vendor_status as enum (
  'active',
  'suspended',
  'closed'
);

-- 2. Business verification status

create type public.business_verification_status as enum (
  'not_submitted',
  'pending',
  'verified',
  'rejected'
);

-- 3. Strengthen the platform administrator helper.
-- Admin access requires an active account and AAL2 (2FA).

create or replace function public.is_active_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.platform_access_assignments assignment
    inner join public.users app_user
      on app_user.id = assignment.user_id
    where assignment.user_id = (select auth.uid())
      and assignment.role in ('admin', 'super_admin')
      and assignment.status = 'active'
      and app_user.status = 'active'
      and (
        assignment.expires_at is null
        or assignment.expires_at > now()
      )
      and (select auth.jwt() ->> 'aal') = 'aal2'
  );
$$;

revoke all on function public.is_active_platform_admin()
  from public, anon;

grant execute on function public.is_active_platform_admin()
  to authenticated;

-- 4. Vendors
-- A vendor is created only after application approval.

create table public.vendors (
  id uuid primary key default gen_random_uuid(),

  application_id uuid not null unique
    references public.vendor_applications(id) on delete restrict,

  name text not null,
  slug text not null unique
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

  description text,
  logo_url text,

  business_email text not null,
  business_phone text not null,
  country_code varchar(2) not null
    check (country_code ~ '^[A-Z]{2}$'),

  business_type text not null,

  status public.vendor_status not null default 'active',

  created_by uuid not null
    references public.users(id) on delete restrict,

  approved_at timestamptz not null default now(),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index vendors_status_idx
  on public.vendors(status);

create index vendors_created_by_idx
  on public.vendors(created_by);

create trigger set_vendors_updated_at
  before update on public.vendors
  for each row
  execute function public.set_updated_at();

-- 5. Vendor memberships
-- MVP supports exactly one owner per vendor.

create table public.vendor_memberships (
  id uuid primary key default gen_random_uuid(),

  vendor_id uuid not null
    references public.vendors(id) on delete restrict,

  user_id uuid not null
    references public.users(id) on delete restrict,

  role text not null default 'owner'
    check (role = 'owner'),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vendor_single_owner_unique
    unique (vendor_id)
);

create index vendor_memberships_user_idx
  on public.vendor_memberships(user_id);

create trigger set_vendor_memberships_updated_at
  before update on public.vendor_memberships
  for each row
  execute function public.set_updated_at();

-- 6. Independent vendor verification

create table public.vendor_verifications (
  id uuid primary key default gen_random_uuid(),

  vendor_id uuid not null unique
    references public.vendors(id) on delete restrict,

  status public.business_verification_status
    not null default 'not_submitted',

  reviewed_by uuid
    references public.users(id) on delete restrict,

  reviewed_at timestamptz,
  review_notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vendor_verification_review_check
    check (
      (reviewed_by is null and reviewed_at is null)
      or
      (reviewed_by is not null and reviewed_at is not null)
    )
);

create index vendor_verifications_status_idx
  on public.vendor_verifications(status);

create trigger set_vendor_verifications_updated_at
  before update on public.vendor_verifications
  for each row
  execute function public.set_updated_at();

-- 7. Enable RLS

alter table public.vendors enable row level security;
alter table public.vendor_memberships enable row level security;
alter table public.vendor_verifications enable row level security;

-- 8. Data API privileges
-- No direct client-side vendor creation or modification.

grant select on public.vendors to anon, authenticated;

grant select on public.vendor_memberships to authenticated;

grant select on public.vendor_verifications to authenticated;

-- 9. Vendor policies

create policy "Anyone can view active vendors"
  on public.vendors
  for select
  to anon, authenticated
  using (
    status = 'active'
    or exists (
      select 1
      from public.vendor_memberships membership
      where membership.vendor_id = vendors.id
        and membership.user_id = (select auth.uid())
    )
    or (select public.is_active_platform_admin())
  );

-- 10. Membership policies

create policy "Vendor owners can view their memberships"
  on public.vendor_memberships
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select public.is_active_platform_admin())
  );

-- 11. Verification policies

create policy "Vendor owners can view their verification status"
  on public.vendor_verifications
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.vendor_memberships membership
      where membership.vendor_id = vendor_verifications.vendor_id
        and membership.user_id = (select auth.uid())
    )
    or (select public.is_active_platform_admin())
  );
