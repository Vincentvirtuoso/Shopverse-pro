
-- =========================================================
-- 006: Vendor business verification workflow
-- Shopverse
-- =========================================================

-- 1. Verification submission timestamp

alter table public.vendor_verifications
  add column submitted_at timestamptz;

-- 2. Verification documents
-- Files themselves will be stored in a private Supabase Storage bucket.

create table public.vendor_verification_documents (
  id uuid primary key default gen_random_uuid(),

  verification_id uuid not null
    references public.vendor_verifications(id) on delete restrict,

  document_type text not null,

  storage_path text not null unique,

  original_file_name text not null,
  content_type text not null,

  file_size_bytes bigint not null
    check (file_size_bytes > 0),

  uploaded_at timestamptz not null default now(),

  created_at timestamptz not null default now()
);

create index vendor_verification_documents_verification_idx
  on public.vendor_verification_documents(verification_id);

alter table public.vendor_verification_documents enable row level security;

grant select, insert
  on public.vendor_verification_documents
  to authenticated;

-- 3. Document access policies

create policy "Vendor owners can view their verification documents"
  on public.vendor_verification_documents
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.vendor_verifications verification
      join public.vendor_memberships membership
        on membership.vendor_id = verification.vendor_id
      where verification.id = verification_id
        and membership.user_id = (select auth.uid())
    )
    or (select public.is_active_platform_admin())
  );

create policy "Vendor owners can upload verification documents"
  on public.vendor_verification_documents
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.vendor_verifications verification
      join public.vendor_memberships membership
        on membership.vendor_id = verification.vendor_id
      join public.vendors vendor
        on vendor.id = verification.vendor_id
      where verification.id = verification_id
        and membership.user_id = (select auth.uid())
        and vendor.status = 'active'
        and verification.status in ('not_submitted', 'rejected')
    )
  );

-- 4. Submit business verification
-- Requires at least one newly uploaded document.
-- Rejected verification can be resubmitted with new documents.

create or replace function public.submit_vendor_verification(
  p_verification_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  verification_record public.vendor_verifications%rowtype;
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

  select verification.*
  into verification_record
  from public.vendor_verifications verification
  join public.vendor_memberships membership
    on membership.vendor_id = verification.vendor_id
  join public.vendors vendor
    on vendor.id = verification.vendor_id
  where verification.id = p_verification_id
    and membership.user_id = current_user_id
    and vendor.status = 'active'
  for update of verification;

  if not found then
    raise exception 'Verification record not found or access denied';
  end if;

  if verification_record.status not in ('not_submitted', 'rejected') then
    raise exception 'Verification cannot be submitted in its current status';
  end if;

  if not exists (
    select 1
    from public.vendor_verification_documents document
    where document.verification_id = p_verification_id
      and (
        verification_record.reviewed_at is null
        or document.uploaded_at > verification_record.reviewed_at
      )
  ) then
    raise exception 'Upload at least one new verification document';
  end if;

  update public.vendor_verifications
  set
    status = 'pending',
    submitted_at = now(),
    reviewed_by = null,
    reviewed_at = null,
    review_notes = null
  where id = p_verification_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor_verification.submitted',
    'vendor_verification',
    p_verification_id,
    pg_catalog.jsonb_build_object(
      'vendor_id', verification_record.vendor_id
    )
  );
end;
$$;

revoke all on function public.submit_vendor_verification(uuid)
  from public, anon;

grant execute on function public.submit_vendor_verification(uuid)
  to authenticated;

-- 5. Review business verification
-- Only active platform administrators with MFA can review.

create or replace function public.review_vendor_verification(
  p_verification_id uuid,
  p_decision public.business_verification_status,
  p_review_notes text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  verification_record public.vendor_verifications%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_active_platform_admin() then
    raise exception 'Active platform administrator with MFA required';
  end if;

  if p_decision not in ('verified', 'rejected') then
    raise exception 'Decision must be verified or rejected';
  end if;

  if p_decision = 'rejected'
    and nullif(pg_catalog.btrim(p_review_notes), '') is null
  then
    raise exception 'Review notes are required for rejection';
  end if;

  select *
  into verification_record
  from public.vendor_verifications
  where id = p_verification_id
  for update;

  if not found then
    raise exception 'Verification record not found';
  end if;

  if verification_record.status <> 'pending' then
    raise exception 'Only pending verifications can be reviewed';
  end if;

  update public.vendor_verifications
  set
    status = p_decision,
    reviewed_by = current_user_id,
    reviewed_at = now(),
    review_notes = nullif(pg_catalog.btrim(p_review_notes), '')
  where id = p_verification_id;

  insert into public.audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    metadata
  )
  values (
    current_user_id,
    'vendor_verification.reviewed',
    'vendor_verification',
    p_verification_id,
    pg_catalog.jsonb_build_object(
      'vendor_id', verification_record.vendor_id,
      'decision', p_decision,
      'review_notes', p_review_notes
    )
  );
end;
$$;

revoke all on function public.review_vendor_verification(
  uuid, public.business_verification_status, text
) from public, anon;

grant execute on function public.review_vendor_verification(
  uuid, public.business_verification_status, text
) to authenticated;
