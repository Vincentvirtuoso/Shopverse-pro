
-- 020_create_vendor_payout_account_tables.sql

-- =========================================================
-- 1. ENUM
-- =========================================================

CREATE TYPE public.payout_account_status AS ENUM (
  'pending_verification',
  'verified',
  'rejected',
  'disabled'
);

-- =========================================================
-- 2. VENDOR PAYOUT ACCOUNTS
-- =========================================================

CREATE TABLE public.vendor_payout_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  vendor_id UUID NOT NULL
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  provider TEXT NOT NULL,

  provider_account_id TEXT,

  account_name TEXT NOT NULL,
  account_number_last4 VARCHAR(4) NOT NULL,

  bank_code TEXT NOT NULL,
  bank_name TEXT NOT NULL,

  currency VARCHAR(3) NOT NULL,
  country_code VARCHAR(2) NOT NULL,

  status public.payout_account_status NOT NULL
    DEFAULT 'pending_verification',

  is_default BOOLEAN NOT NULL DEFAULT FALSE,

  verified_at TIMESTAMPTZ,

  created_by UUID NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT payout_account_last4_check
    CHECK (account_number_last4 ~ '^[0-9]{4}$'),

  CONSTRAINT payout_account_currency_check
    CHECK (currency ~ '^[A-Z]{3}$'),

  CONSTRAINT payout_account_country_check
    CHECK (country_code ~ '^[A-Z]{2}$'),

  CONSTRAINT payout_account_provider_check
    CHECK (length(trim(provider)) > 0),

  CONSTRAINT payout_account_name_check
    CHECK (length(trim(account_name)) > 0),

  CONSTRAINT payout_account_bank_name_check
    CHECK (length(trim(bank_name)) > 0),

  CONSTRAINT payout_account_verification_check
    CHECK (
      (status = 'verified' AND verified_at IS NOT NULL)
      OR
      (status <> 'verified' AND verified_at IS NULL)
    )
);

CREATE INDEX vendor_payout_accounts_vendor_idx
  ON public.vendor_payout_accounts(vendor_id);

CREATE INDEX vendor_payout_accounts_vendor_status_idx
  ON public.vendor_payout_accounts(vendor_id, status);

CREATE UNIQUE INDEX vendor_payout_accounts_default_idx
  ON public.vendor_payout_accounts(vendor_id)
  WHERE is_default = TRUE;

CREATE UNIQUE INDEX vendor_payout_accounts_provider_reference_idx
  ON public.vendor_payout_accounts(provider, provider_account_id)
  WHERE provider_account_id IS NOT NULL;

CREATE TRIGGER set_vendor_payout_accounts_updated_at
BEFORE UPDATE ON public.vendor_payout_accounts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 3. PRIVATE PROVIDER CREDENTIALS
-- =========================================================

CREATE TABLE public.vendor_payout_account_credentials (
  payout_account_id UUID PRIMARY KEY
    REFERENCES public.vendor_payout_accounts(id) ON DELETE RESTRICT,

  provider TEXT NOT NULL,

  provider_recipient_token TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT payout_account_credentials_token_check
    CHECK (length(trim(provider_recipient_token)) > 0)
);

CREATE TRIGGER set_vendor_payout_credentials_updated_at
BEFORE UPDATE ON public.vendor_payout_account_credentials
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- No authenticated or anonymous access to provider credentials.
ALTER TABLE public.vendor_payout_account_credentials
  ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 4. PAYOUT DESTINATION SNAPSHOTS
-- =========================================================

ALTER TABLE public.vendor_payouts
  ADD COLUMN payout_account_id UUID
    REFERENCES public.vendor_payout_accounts(id)
    ON DELETE RESTRICT;

ALTER TABLE public.vendor_payouts
  ADD COLUMN destination_snapshot JSONB;

ALTER TABLE public.vendor_payouts
  ADD CONSTRAINT vendor_payout_destination_snapshot_check
  CHECK (
    destination_snapshot IS NULL
    OR jsonb_typeof(destination_snapshot) = 'object'
  );

CREATE INDEX vendor_payouts_account_idx
  ON public.vendor_payouts(payout_account_id);

-- =========================================================
-- 5. VALIDATE PAYOUT DESTINATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_vendor_payout_destination()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_account public.vendor_payout_accounts%ROWTYPE;
BEGIN
  IF NEW.payout_account_id IS NULL THEN
    RAISE EXCEPTION 'A payout account is required';
  END IF;

  SELECT *
  INTO v_account
  FROM public.vendor_payout_accounts
  WHERE id = NEW.payout_account_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout account not found';
  END IF;

  IF v_account.vendor_id <> NEW.vendor_id THEN
    RAISE EXCEPTION 'Payout account belongs to another vendor';
  END IF;

  IF v_account.status <> 'verified' THEN
    RAISE EXCEPTION 'Payout account must be verified';
  END IF;

  IF v_account.currency <> NEW.currency THEN
    RAISE EXCEPTION 'Payout account currency does not match payout currency';
  END IF;

  IF NEW.destination_snapshot IS NULL THEN
    NEW.destination_snapshot := jsonb_build_object(
      'provider', v_account.provider,
      'accountName', v_account.account_name,
      'accountNumberLast4', v_account.account_number_last4,
      'bankCode', v_account.bank_code,
      'bankName', v_account.bank_name,
      'currency', v_account.currency,
      'countryCode', v_account.country_code
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_vendor_payout_destination_before_insert
BEFORE INSERT ON public.vendor_payouts
FOR EACH ROW
EXECUTE FUNCTION public.validate_vendor_payout_destination();

-- =========================================================
-- 6. PROTECT PAYOUT DESTINATION SNAPSHOTS
-- =========================================================

CREATE OR REPLACE FUNCTION public.prevent_vendor_payout_destination_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.payout_account_id IS DISTINCT FROM OLD.payout_account_id
    OR NEW.destination_snapshot IS DISTINCT FROM OLD.destination_snapshot
  THEN
    RAISE EXCEPTION 'Payout destination cannot be changed after request creation';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER prevent_vendor_payout_destination_update
BEFORE UPDATE ON public.vendor_payouts
FOR EACH ROW
EXECUTE FUNCTION public.prevent_vendor_payout_destination_change();

-- =========================================================
-- 7. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.vendor_payout_accounts
  ENABLE ROW LEVEL SECURITY;

GRANT SELECT (
  id,
  vendor_id,
  provider,
  account_name,
  account_number_last4,
  bank_code,
  bank_name,
  currency,
  country_code,
  status,
  is_default,
  verified_at,
  created_by,
  created_at,
  updated_at
)
ON public.vendor_payout_accounts
TO authenticated;

CREATE POLICY "Vendor owners view own payout accounts"
ON public.vendor_payout_accounts
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.vendor_memberships vm
    WHERE vm.vendor_id = vendor_payout_accounts.vendor_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all payout accounts"
ON public.vendor_payout_accounts
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

CREATE POLICY "Platform admins manage payout accounts"
ON public.vendor_payout_accounts
FOR ALL
TO authenticated
USING (public.is_active_platform_admin())
WITH CHECK (public.is_active_platform_admin());

-- Provider credentials deliberately have no Data API grants
-- or authenticated/anonymous policies.

REVOKE ALL ON public.vendor_payout_account_credentials
  FROM PUBLIC, anon, authenticated;

-- =========================================================
-- 8. FUNCTION PERMISSIONS
-- =========================================================

REVOKE ALL ON FUNCTION public.validate_vendor_payout_destination()
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.prevent_vendor_payout_destination_change()
  FROM PUBLIC, anon, authenticated;
