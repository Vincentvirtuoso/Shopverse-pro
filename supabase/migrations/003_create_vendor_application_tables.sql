
-- =========================================================
-- 003: Vendor application tables
-- Shopverse
-- =========================================================

-- 1. Application statuses

create type public.vendor_application_status as enum (
  'pending',
  'approved',
  'rejected',
  'withdrawn'
);

-- 2. Configurable application attempt limit

create table public.vendor_application_settings (
  singleton boolean primary key default true
    check (singleton = true),

  max_attempts smallint not null default 3
    check (max_attempts between 1 and 5),

  updated_at timestamptz not null default now()
);

insert into public.vendor_application_settings (singleton, max_attempts)
values (true, 3);

-- No direct Data API access to configuration.
alter table public.vendor_application_settings enable row level security;

-- 3. Vendor applications

create table public.vendor_applications (
  id uuid primary key default gen_random_uuid(),

  applicant_id uuid not null
    references public.users(id) on delete restrict,

  attempt_number smallint not null
    check (attempt_number between 1 and 5),

  business_name text not null,
  business_email text not null,
  business_phone text not null,

  country_code varchar(2) not null
    check (country_code ~ '^[A-Z]{2}$'),

  business_type text not null,

  status public.vendor_application_status not null default 'pending',

  submitted_at timestamptz not null default now(),

  reviewed_by uuid
    references public.users(id) on delete restrict,

  reviewed_at timestamptz,
  review_notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vendor_application_attempt_unique
    unique (applicant_id, attempt_number),

  constraint vendor_application_review_check
    check (
      (reviewed_by is null and reviewed_at is null)
      or
      (reviewed_by is not null and reviewed_at is not null)
    )
);

create index vendor_applications_applicant_idx
  on public.vendor_applications(applicant_id);

create index vendor_applications_status_idx
  on public.vendor_applications(status);

create index vendor_applications_pending_idx
  on public.vendor_applications(submitted_at)
  where status = 'pending';

-- 4. Platform administrator helper

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
    where assignment.user_id = (select auth.uid())
      and assignment.role in ('admin', 'super_admin')
      and assignment.status = 'active'
      and (
        assignment.expires_at is null
        or assignment.expires_at > now()
      )
  );
$$;

revoke all on function public.is_active_platform_admin()
  from public;

grant execute on function public.is_active_platform_admin()
  to authenticated;

-- 5. Atomic application attempt enforcement

create or replace function public.enforce_vendor_application_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_attempts integer;
  attempt_limit integer;
begin
  -- Serialize submissions from the same applicant.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.applicant_id::text, 0)
  );

  select max_attempts
  into attempt_limit
  from public.vendor_application_settings
  where singleton = true;

  if attempt_limit is null then
    raise exception 'Vendor application settings are missing';
  end if;

  -- An applicant cannot have multiple pending applications
  -- or apply again after approval.
  if exists (
    select 1
    from public.vendor_applications
    where applicant_id = new.applicant_id
      and status in ('pending', 'approved')
  ) then
    raise exception 'An active or approved application already exists';
  end if;

  -- Every submitted application counts, including withdrawn ones.
  select count(*)
  into current_attempts
  from public.vendor_applications
  where applicant_id = new.applicant_id;

  if current_attempts >= attempt_limit then
    raise exception 'Maximum vendor application attempts reached';
  end if;

  new.attempt_number := current_attempts + 1;
  new.status := 'pending';
  new.submitted_at := now();

  return new;
end;
$$;

create trigger enforce_vendor_application_limit_trigger
  before insert on public.vendor_applications
  for each row
  execute function public.enforce_vendor_application_limit();

-- 6. Vendor application submission function
-- Applicants cannot choose their own attempt number or status.

create or replace function public.submit_vendor_application(
  p_business_name text,
  p_business_email text,
  p_business_phone text,
  p_country_code varchar(2),
  p_business_type text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  user_status public.account_status;
  is_email_verified boolean;
  application_id uuid;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select status
  into user_status
  from public.users
  where id = current_user_id;

  if user_status is distinct from 'active' then
    raise exception 'Your account is not eligible to apply';
  end if;

  select email_confirmed_at is not null
  into is_email_verified
  from auth.users
  where id = current_user_id;

  if is_email_verified is distinct from true then
    raise exception 'Email verification is required';
  end if;

  if nullif(pg_catalog.btrim(p_business_name), '') is null
    or nullif(pg_catalog.btrim(p_business_email), '') is null
    or nullif(pg_catalog.btrim(p_business_phone), '') is null
    or nullif(pg_catalog.btrim(p_business_type), '') is null
  then
    raise exception 'All business application fields are required';
  end if;

  if p_country_code !~ '^[A-Z]{2}$' then
    raise exception 'Invalid country code';
  end if;

  insert into public.vendor_applications (
    applicant_id,
    business_name,
    business_email,
    business_phone,
    country_code,
    business_type
  )
  values (
    current_user_id,
    pg_catalog.btrim(p_business_name),
    pg_catalog.btrim(p_business_email),
    pg_catalog.btrim(p_business_phone),
    p_country_code,
    pg_catalog.btrim(p_business_type)
  )
  returning id into application_id;

  return application_id;
end;
$$;

revoke all on function public.submit_vendor_application(
  text, text, text, varchar, text
) from public;

grant execute on function public.submit_vendor_application(
  text, text, text, varchar, text
) to authenticated;

-- 7. Verification document metadata

create table public.vendor_application_documents (
  id uuid primary key default gen_random_uuid(),

  application_id uuid not null
    references public.vendor_applications(id) on delete restrict,

  document_type text not null,

  storage_path text not null unique,

  original_file_name text not null,
  content_type text not null,

  file_size_bytes bigint not null
    check (file_size_bytes > 0),

  uploaded_at timestamptz not null default now()
);

create index vendor_application_documents_application_idx
  on public.vendor_application_documents(application_id);

-- 8. Updated timestamp trigger

create trigger set_vendor_applications_updated_at
  before update on public.vendor_applications
  for each row
  execute function public.set_updated_at();

-- 9. Enable RLS

alter table public.vendor_applications enable row level security;
alter table public.vendor_application_documents enable row level security;

-- 10. Data API privileges

grant select on public.vendor_applications to authenticated;

grant select, insert
  on public.vendor_application_documents to authenticated;

-- 11. Application policies

create policy "Applicants can view their own applications"
  on public.vendor_applications
  for select
  to authenticated
  using (applicant_id = (select auth.uid()));

create policy "Platform administrators can view all applications"
  on public.vendor_applications
  for select
  to authenticated
  using ((select public.is_active_platform_admin()));

-- 12. Document policies

create policy "Applicants can view their own application documents"
  on public.vendor_application_documents
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.vendor_applications application
      where application.id = application_id
        and application.applicant_id = (select auth.uid())
    )
  );

create policy "Platform administrators can view application documents"
  on public.vendor_application_documents
  for select
  to authenticated
  using ((select public.is_active_platform_admin()));

create policy "Applicants can attach documents to pending applications"
  on public.vendor_application_documents
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.vendor_applications application
      where application.id = application_id
        and application.applicant_id = (select auth.uid())
        and application.status = 'pending'
    )
  );
