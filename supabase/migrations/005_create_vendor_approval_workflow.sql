
-- =========================================================
-- 005: Vendor approval workflow and audit logging
-- Shopverse
-- =========================================================

-- 1. Audit logs
-- Records important platform and vendor operations.
-- Audit records are immutable through the Data API.

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),

  actor_id uuid not null
    references public.users(id) on delete restrict,

  action text not null,
  target_type text not null,
  target_id uuid not null,

  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),

  created_at timestamptz not null default now()
);

create index audit_logs_actor_idx
  on public.audit_logs(actor_id);

create index audit_logs_target_idx
  on public.audit_logs(target_type, target_id);

create index audit_logs_created_at_idx
  on public.audit_logs(created_at desc);

alter table public.audit_logs enable row level security;

grant select on public.audit_logs to authenticated;

create policy "Platform administrators can view audit logs"
  on public.audit_logs
  for select
  to authenticated
  using ((select public.is_active_platform_admin()));

-- 2. Approve vendor application
-- Creates the vendor, owner membership and verification record
-- atomically. Any failure rolls back the entire operation.

create or replace function public.approve_vendor_application(
  p_application_id uuid,
  p_vendor_slug text,
  p_review_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  application_record public.vendor_applications%rowtype;
  normalized_slug text;
  new_vendor_id uuid;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_active_platform_admin() then
    raise exception 'Active platform administrator with MFA required';
  end if;

  normalized_slug := pg_catalog.lower(
    pg_catalog.btrim(p_vendor_slug)
  );

  if normalized_slug is null
    or normalized_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
  then
    raise exception 'Invalid vendor slug';
  end if;

  select *
  into application_record
  from public.vendor_applications
  where id = p_application_id
  for update;

  if not found then
    raise exception 'Vendor application not found';
  end if;

  if application_record.status <> 'pending' then
    raise exception 'Only pending applications can be approved';
  end if;

  if not exists (
    select 1
    from public.users
    where id = application_record.applicant_id
      and status = 'active'
  ) then
    raise exception 'Applicant account is not active';
  end if;

  insert into public.vendors (
    application_id,
    name,
    slug,
    business_email,
    business_phone,
    country_code,
    business_type,
    created_by,
    approved_at
  )
  values (
    application_record.id,
    application_record.business_name,
    normalized_slug,
    application_record.business_email,
    application_record.business_phone,
    application_record.country_code,
    application_record.business_type,
    application_record.applicant_id,
    now()
  )
  returning id into new_vendor_id;

  insert into public.vendor_memberships (
    vendor_id,
    user_id,
    role
  )
  values (
    new_vendor_id,
    application_record.applicant_id,
    'owner'
  );

  insert into public.vendor_verifications (
    vendor_id,
    status
  )
  values (
    new_vendor_id,
    'not_submitted'
  );

  update public.vendor_applications
  set
    status = 'approved',
    reviewed_by = current_user_id,
    reviewed_at = now(),
    review_notes = p_review_notes
  where id = application_record.id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor_application.approved',
    'vendor_application',
    application_record.id,
    pg_catalog.jsonb_build_object(
      'vendor_id', new_vendor_id,
      'vendor_slug', normalized_slug,
      'applicant_id', application_record.applicant_id
    )
  );

  return new_vendor_id;
end;
$$;

revoke all on function public.approve_vendor_application(
  uuid, text, text
) from public, anon;

grant execute on function public.approve_vendor_application(
  uuid, text, text
) to authenticated;

-- 3. Reject vendor application

create or replace function public.reject_vendor_application(
  p_application_id uuid,
  p_review_notes text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  application_record public.vendor_applications%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_active_platform_admin() then
    raise exception 'Active platform administrator with MFA required';
  end if;

  if nullif(pg_catalog.btrim(p_review_notes), '') is null then
    raise exception 'Review notes are required for rejection';
  end if;

  select *
  into application_record
  from public.vendor_applications
  where id = p_application_id
  for update;

  if not found then
    raise exception 'Vendor application not found';
  end if;

  if application_record.status <> 'pending' then
    raise exception 'Only pending applications can be rejected';
  end if;

  update public.vendor_applications
  set
    status = 'rejected',
    reviewed_by = current_user_id,
    reviewed_at = now(),
    review_notes = pg_catalog.btrim(p_review_notes)
  where id = application_record.id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor_application.rejected',
    'vendor_application',
    application_record.id,
    pg_catalog.jsonb_build_object(
      'applicant_id', application_record.applicant_id,
      'review_notes', pg_catalog.btrim(p_review_notes)
    )
  );
end;
$$;

revoke all on function public.reject_vendor_application(
  uuid, text
) from public, anon;

grant execute on function public.reject_vendor_application(
  uuid, text
) to authenticated;

-- 4. Withdraw a pending application
-- Applicants can withdraw their own pending applications.

create or replace function public.withdraw_vendor_application(
  p_application_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  application_record public.vendor_applications%rowtype;
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

  select *
  into application_record
  from public.vendor_applications
  where id = p_application_id
  for update;

  if not found then
    raise exception 'Vendor application not found';
  end if;

  if application_record.applicant_id <> current_user_id then
    raise exception 'You cannot withdraw another user application';
  end if;

  if application_record.status <> 'pending' then
    raise exception 'Only pending applications can be withdrawn';
  end if;

  update public.vendor_applications
  set status = 'withdrawn'
  where id = application_record.id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor_application.withdrawn',
    'vendor_application',
    application_record.id,
    pg_catalog.jsonb_build_object(
      'applicant_id', current_user_id
    )
  );
end;
$$;

revoke all on function public.withdraw_vendor_application(
  uuid
) from public, anon;

grant execute on function public.withdraw_vendor_application(
  uuid
) to authenticated;
