
-- =========================================================
-- 007: Vendor account management
-- Shopverse
-- =========================================================

-- 1. Vendor closure request status

create type public.vendor_closure_request_status as enum (
  'pending',
  'approved',
  'rejected',
  'withdrawn'
);

-- 2. Vendor profile editing
-- Owners can update only these three business profile fields.
-- Slugs, ownership, approval and account status are protected.

grant update (name, description, logo_url)
  on public.vendors to authenticated;

create policy "Active vendor owners can update their profiles"
  on public.vendors
  for update
  to authenticated
  using (
    status = 'active'
    and exists (
      select 1
      from public.vendor_memberships membership
      where membership.vendor_id = vendors.id
        and membership.user_id = (select auth.uid())
    )
    and exists (
      select 1
      from public.users app_user
      where app_user.id = (select auth.uid())
        and app_user.status = 'active'
    )
  )
  with check (
    status = 'active'
    and exists (
      select 1
      from public.vendor_memberships membership
      where membership.vendor_id = vendors.id
        and membership.user_id = (select auth.uid())
    )
  );

-- 3. Vendor closure requests

create table public.vendor_closure_requests (
  id uuid primary key default gen_random_uuid(),

  vendor_id uuid not null
    references public.vendors(id) on delete restrict,

  requested_by uuid not null
    references public.users(id) on delete restrict,

  reason text not null,

  status public.vendor_closure_request_status
    not null default 'pending',

  requested_at timestamptz not null default now(),

  reviewed_by uuid
    references public.users(id) on delete restrict,

  reviewed_at timestamptz,
  review_notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vendor_closure_review_check
    check (
      (reviewed_by is null and reviewed_at is null)
      or
      (reviewed_by is not null and reviewed_at is not null)
    )
);

create unique index vendor_closure_one_pending_idx
  on public.vendor_closure_requests(vendor_id)
  where status = 'pending';

create index vendor_closure_requests_vendor_idx
  on public.vendor_closure_requests(vendor_id);

create index vendor_closure_requests_status_idx
  on public.vendor_closure_requests(status);

create trigger set_vendor_closure_requests_updated_at
  before update on public.vendor_closure_requests
  for each row
  execute function public.set_updated_at();

alter table public.vendor_closure_requests enable row level security;

grant select on public.vendor_closure_requests to authenticated;

create policy "Vendor owners can view their closure requests"
  on public.vendor_closure_requests
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.vendor_memberships membership
      where membership.vendor_id = vendor_closure_requests.vendor_id
        and membership.user_id = (select auth.uid())
    )
    or (select public.is_active_platform_admin())
  );

-- 4. Submit a vendor closure request

create or replace function public.submit_vendor_closure_request(
  p_vendor_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  new_request_id uuid;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.users
    where id = current_user_id
      and status = 'active'
  ) then
    raise exception 'Your account is not eligible';
  end if;

  if nullif(pg_catalog.btrim(p_reason), '') is null then
    raise exception 'A closure reason is required';
  end if;

  perform 1
  from public.vendors vendor
  join public.vendor_memberships membership
    on membership.vendor_id = vendor.id
  where vendor.id = p_vendor_id
    and vendor.status = 'active'
    and membership.user_id = current_user_id
  for update of vendor;

  if not found then
    raise exception 'Active vendor ownership not found';
  end if;

  insert into public.vendor_closure_requests (
    vendor_id,
    requested_by,
    reason
  )
  values (
    p_vendor_id,
    current_user_id,
    pg_catalog.btrim(p_reason)
  )
  returning id into new_request_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor.closure_requested',
    'vendor',
    p_vendor_id,
    pg_catalog.jsonb_build_object(
      'request_id', new_request_id
    )
  );

  return new_request_id;
end;
$$;

revoke all on function public.submit_vendor_closure_request(uuid, text)
  from public, anon;

grant execute on function public.submit_vendor_closure_request(uuid, text)
  to authenticated;

-- 5. Withdraw a pending closure request

create or replace function public.withdraw_vendor_closure_request(
  p_request_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  request_record public.vendor_closure_requests%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into request_record
  from public.vendor_closure_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Closure request not found';
  end if;

  if request_record.requested_by <> current_user_id then
    raise exception 'You cannot withdraw this request';
  end if;

  if request_record.status <> 'pending' then
    raise exception 'Only pending requests can be withdrawn';
  end if;

  update public.vendor_closure_requests
  set status = 'withdrawn'
  where id = p_request_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor.closure_request_withdrawn',
    'vendor',
    request_record.vendor_id,
    pg_catalog.jsonb_build_object(
      'request_id', p_request_id
    )
  );
end;
$$;

revoke all on function public.withdraw_vendor_closure_request(uuid)
  from public, anon;

grant execute on function public.withdraw_vendor_closure_request(uuid)
  to authenticated;

-- 6. Review a vendor closure request
-- Approval means the request is accepted in principle.
-- Actual closure waits for the commerce obligations check.

create or replace function public.review_vendor_closure_request(
  p_request_id uuid,
  p_decision public.vendor_closure_request_status,
  p_review_notes text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  request_record public.vendor_closure_requests%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_active_platform_admin() then
    raise exception 'Active platform administrator with MFA required';
  end if;

  if p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected';
  end if;

  if p_decision = 'rejected'
    and nullif(pg_catalog.btrim(p_review_notes), '') is null
  then
    raise exception 'Review notes are required for rejection';
  end if;

  select *
  into request_record
  from public.vendor_closure_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Closure request not found';
  end if;

  if request_record.status <> 'pending' then
    raise exception 'Only pending requests can be reviewed';
  end if;

  update public.vendor_closure_requests
  set
    status = p_decision,
    reviewed_by = current_user_id,
    reviewed_at = now(),
    review_notes = nullif(pg_catalog.btrim(p_review_notes), '')
  where id = p_request_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor.closure_request.reviewed',
    'vendor',
    request_record.vendor_id,
    pg_catalog.jsonb_build_object(
      'request_id', p_request_id,
      'decision', p_decision
    )
  );
end;
$$;

revoke all on function public.review_vendor_closure_request(
  uuid, public.vendor_closure_request_status, text
) from public, anon;

grant execute on function public.review_vendor_closure_request(
  uuid, public.vendor_closure_request_status, text
) to authenticated;

-- 7. Suspend or reactivate a vendor
-- Only platform administrators with MFA can perform this action.

create or replace function public.set_vendor_status(
  p_vendor_id uuid,
  p_status public.vendor_status,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  previous_status public.vendor_status;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_active_platform_admin() then
    raise exception 'Active platform administrator with MFA required';
  end if;

  if p_status not in ('active', 'suspended') then
    raise exception 'This operation only supports suspension or reactivation';
  end if;

  if nullif(pg_catalog.btrim(p_reason), '') is null then
    raise exception 'A reason is required';
  end if;

  select status
  into previous_status
  from public.vendors
  where id = p_vendor_id
  for update;

  if not found then
    raise exception 'Vendor not found';
  end if;

  if previous_status = 'closed' then
    raise exception 'Closed vendors cannot be reactivated';
  end if;

  if previous_status = p_status then
    raise exception 'Vendor already has this status';
  end if;

  update public.vendors
  set status = p_status
  where id = p_vendor_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor.status_changed',
    'vendor',
    p_vendor_id,
    pg_catalog.jsonb_build_object(
      'previous_status', previous_status,
      'new_status', p_status,
      'reason', pg_catalog.btrim(p_reason)
    )
  );
end;
$$;

revoke all on function public.set_vendor_status(
  uuid, public.vendor_status, text
) from public, anon;

grant execute on function public.set_vendor_status(
  uuid, public.vendor_status, text
) to authenticated;
