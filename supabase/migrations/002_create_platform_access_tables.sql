
-- =========================================================
-- 002: Platform access tables
-- Shopverse
-- =========================================================

-- 1. Platform roles

create type public.platform_access_role as enum (
  'admin',
  'super_admin'
);

-- 2. Access assignment status

create type public.access_status as enum (
  'pending',
  'active',
  'suspended',
  'revoked'
);

-- 3. Platform access assignments

create table public.platform_access_assignments (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references public.users(id) on delete restrict,

  role public.platform_access_role not null,

  status public.access_status not null default 'active',

  assigned_by uuid
    references public.users(id) on delete restrict,

  assigned_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint platform_access_expiry_check
    check (expires_at is null or expires_at > assigned_at)
);

-- Prevent duplicate non-revoked assignments.

create unique index platform_access_assignment_unique
  on public.platform_access_assignments (user_id, role)
  where status <> 'revoked';

create index platform_access_user_idx
  on public.platform_access_assignments(user_id);

create index platform_access_active_idx
  on public.platform_access_assignments(user_id, role)
  where status = 'active';

-- 4. Platform permissions

create table public.platform_permissions (
  key text primary key,
  description text not null
);

-- 5. Role permissions

create table public.role_permissions (
  role public.platform_access_role not null,

  permission_key text not null
    references public.platform_permissions(key)
    on delete restrict,

  primary key (role, permission_key)
);

-- 6. Enable RLS

alter table public.platform_access_assignments
  enable row level security;

alter table public.platform_permissions
  enable row level security;

alter table public.role_permissions
  enable row level security;

-- 7. Helper function:
-- Determines whether the current user has active super-admin access.

create or replace function public.is_active_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.platform_access_assignments assignment
    where assignment.user_id = (select auth.uid())
      and assignment.role = 'super_admin'
      and assignment.status = 'active'
      and (
        assignment.expires_at is null
        or assignment.expires_at > now()
      )
  );
$$;

-- Restrict function execution.

revoke all on function public.is_active_super_admin()
  from public;

grant execute on function public.is_active_super_admin()
  to authenticated;

-- 8. Data API privileges

grant select
  on public.platform_access_assignments
  to authenticated;

grant select
  on public.platform_permissions
  to authenticated;

grant select
  on public.role_permissions
  to authenticated;

grant insert, update
  on public.platform_access_assignments
  to authenticated;

-- 9. Assignment policies

create policy "Users can view their own platform assignments"
  on public.platform_access_assignments
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Super admins can view all platform assignments"
  on public.platform_access_assignments
  for select
  to authenticated
  using ((select public.is_active_super_admin()));

create policy "Super admins can grant platform access"
  on public.platform_access_assignments
  for insert
  to authenticated
  with check (
    (select public.is_active_super_admin())
    and assigned_by = (select auth.uid())
  );

create policy "Super admins can update platform assignments"
  on public.platform_access_assignments
  for update
  to authenticated
  using ((select public.is_active_super_admin()))
  with check ((select public.is_active_super_admin()));

-- 10. Permission policies

create policy "Authenticated users can view platform permissions"
  on public.platform_permissions
  for select
  to authenticated
  using (true);

create policy "Authenticated users can view role permissions"
  on public.role_permissions
  for select
  to authenticated
  using (true);
