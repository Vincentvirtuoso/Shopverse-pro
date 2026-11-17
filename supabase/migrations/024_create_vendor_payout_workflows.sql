
-- =========================================================
-- 024: Vendor payout request and processing workflows
-- =========================================================


-- =========================================================
-- 1. ALLOW EARNINGS TO BE RETRIED AFTER FAILED PAYOUTS
-- =========================================================

-- Migration 019 permanently restricts each earning to one
-- payout item. Failed and cancelled payouts must be retryable.

ALTER TABLE public.vendor_payout_items
  DROP CONSTRAINT vendor_payout_items_unique_earning;


-- An earning may only belong to one pending or processing
-- payout at a time.

CREATE OR REPLACE FUNCTION public.validate_active_payout_allocation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.vendor_payout_items pi
    JOIN public.vendor_payouts p
      ON p.id = pi.payout_id
    WHERE pi.earning_id = NEW.earning_id
      AND pi.payout_id <> NEW.payout_id
      AND p.status IN ('pending', 'processing')
  ) THEN
    RAISE EXCEPTION
      'This earning already belongs to an active payout';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_active_payout_allocation_trigger
BEFORE INSERT ON public.vendor_payout_items
FOR EACH ROW
EXECUTE FUNCTION public.validate_active_payout_allocation();

REVOKE ALL ON FUNCTION
  public.validate_active_payout_allocation()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 2. PROTECT PAYOUT ITEM HISTORY
-- =========================================================

-- Payout item allocations are historical financial records.
-- Failed or cancelled payouts retain their original allocations.
-- A retry creates a new payout and new payout items.

CREATE OR REPLACE FUNCTION public.prevent_vendor_payout_item_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION
    'Payout item allocations are immutable';
END;
$$;

CREATE TRIGGER prevent_vendor_payout_item_modification_trigger
BEFORE UPDATE OR DELETE
ON public.vendor_payout_items
FOR EACH ROW
EXECUTE FUNCTION public.prevent_vendor_payout_item_modification();

REVOKE ALL ON FUNCTION
  public.prevent_vendor_payout_item_modification()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 3. VENDOR PAYOUT REQUEST
-- =========================================================

-- Vendors select the earnings they want included.
-- Each earning must be available and is allocated in full.
-- The payout amount and currency are calculated server-side.
--
-- Idempotency:
-- Repeating the same request with the same key and selection
-- returns the existing payout instead of creating another.

CREATE OR REPLACE FUNCTION public.request_vendor_payout(
  p_vendor_id UUID,
  p_payout_account_id UUID,
  p_earning_ids UUID[],
  p_idempotency_key TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id UUID;
  v_vendor_status public.vendor_status;

  v_existing_payout public.vendor_payouts%ROWTYPE;
  v_existing_earning_ids UUID[];
  v_requested_earning_ids UUID[];

  v_earning public.vendor_earnings%ROWTYPE;

  v_currency VARCHAR(3);
  v_amount BIGINT := 0;
  v_count INTEGER := 0;

  v_payout_id UUID;
BEGIN
  v_user_id := (SELECT auth.uid());

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication is required';
  END IF;

  IF p_vendor_id IS NULL
    OR p_payout_account_id IS NULL
    OR p_earning_ids IS NULL
    OR cardinality(p_earning_ids) = 0
  THEN
    RAISE EXCEPTION 'Invalid payout request';
  END IF;

  IF p_idempotency_key IS NULL
    OR length(trim(p_idempotency_key)) = 0
  THEN
    RAISE EXCEPTION 'An idempotency key is required';
  END IF;

  -- Reject duplicate earning IDs.
  IF cardinality(p_earning_ids) <> (
    SELECT COUNT(DISTINCT x)
    FROM unnest(p_earning_ids) AS t(x)
  ) THEN
    RAISE EXCEPTION
      'Duplicate earnings are not allowed';
  END IF;

  -- Lock the vendor row to serialize payout requests
  -- for this vendor.
  SELECT v.status
  INTO v_vendor_status
  FROM public.vendors v
  JOIN public.vendor_memberships vm
    ON vm.vendor_id = v.id
  JOIN public.users u
    ON u.id = vm.user_id
  WHERE v.id = p_vendor_id
    AND vm.user_id = v_user_id
    AND vm.role = 'owner'
    AND u.status = 'active'
  FOR UPDATE OF v;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'You are not authorized to request payouts for this vendor';
  END IF;

  IF v_vendor_status <> 'active' THEN
    RAISE EXCEPTION
      'Vendor must be active to request payouts';
  END IF;

  -- Check whether this idempotent request already exists.
  SELECT *
  INTO v_existing_payout
  FROM public.vendor_payouts
  WHERE vendor_id = p_vendor_id
    AND idempotency_key = p_idempotency_key
  FOR UPDATE;

  IF FOUND THEN
    SELECT array_agg(pi.earning_id ORDER BY pi.earning_id)
    INTO v_existing_earning_ids
    FROM public.vendor_payout_items pi
    WHERE pi.payout_id = v_existing_payout.id;

    SELECT array_agg(x ORDER BY x)
    INTO v_requested_earning_ids
    FROM unnest(p_earning_ids) AS t(x);

    IF v_existing_payout.payout_account_id
        IS DISTINCT FROM p_payout_account_id
      OR v_existing_earning_ids
        IS DISTINCT FROM v_requested_earning_ids
    THEN
      RAISE EXCEPTION
        'Idempotency key was already used with different payout details';
    END IF;

    RETURN v_existing_payout.id;
  END IF;

  -- Lock and validate all selected earnings.
  FOR v_earning IN
    SELECT e.*
    FROM public.vendor_earnings e
    WHERE e.id = ANY(p_earning_ids)
    ORDER BY e.id
    FOR UPDATE
  LOOP
    IF v_earning.vendor_id <> p_vendor_id THEN
      RAISE EXCEPTION
        'Selected earning belongs to another vendor';
    END IF;

    IF v_earning.status <> 'available' THEN
      RAISE EXCEPTION
        'Only available earnings can be paid out';
    END IF;

    IF v_currency IS NULL THEN
      v_currency := v_earning.currency;
    ELSIF v_currency <> v_earning.currency THEN
      RAISE EXCEPTION
        'All selected earnings must use the same currency';
    END IF;

    v_amount := v_amount + v_earning.net_amount;
    v_count := v_count + 1;
  END LOOP;

  IF v_count <> cardinality(p_earning_ids) THEN
    RAISE EXCEPTION
      'One or more selected earnings do not exist';
  END IF;

  IF v_amount <= 0 THEN
    RAISE EXCEPTION
      'Payout amount must be greater than zero';
  END IF;

  -- The existing destination trigger validates that the
  -- selected payout account is verified, belongs to the
  -- vendor, and matches the payout currency.
  INSERT INTO public.vendor_payouts (
    vendor_id,
    amount,
    currency,
    payout_account_id,
    idempotency_key
  )
  VALUES (
    p_vendor_id,
    v_amount,
    v_currency,
    p_payout_account_id,
    p_idempotency_key
  )
  RETURNING id INTO v_payout_id;

  -- Allocate each selected earning in full.
  -- Migration 019's trigger changes its status to reserved.
  INSERT INTO public.vendor_payout_items (
    payout_id,
    earning_id,
    amount
  )
  SELECT
    v_payout_id,
    e.id,
    e.net_amount
  FROM public.vendor_earnings e
  WHERE e.id = ANY(p_earning_ids)
  ORDER BY e.id;

  RETURN v_payout_id;
END;
$$;

REVOKE ALL ON FUNCTION
  public.request_vendor_payout(UUID, UUID, UUID[], TEXT)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION
  public.request_vendor_payout(UUID, UUID, UUID[], TEXT)
TO authenticated;


-- =========================================================
-- 4. CONTROL PAYOUT PROCESSING
-- =========================================================

-- Only trusted server-side operations can change payout
-- processing status.
--
-- Allowed transitions:
--
-- pending    -> processing
-- pending    -> failed
-- pending    -> cancelled
-- processing -> succeeded
-- processing -> failed
--
-- A processing payout cannot be cancelled because the
-- external provider may already have transferred funds.

CREATE OR REPLACE FUNCTION public.update_vendor_payout_status(
  p_payout_id UUID,
  p_new_status public.vendor_payout_status,
  p_provider TEXT DEFAULT NULL,
  p_provider_reference TEXT DEFAULT NULL,
  p_failure_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payout public.vendor_payouts%ROWTYPE;
  v_transition_allowed BOOLEAN := FALSE;
BEGIN
  IF COALESCE(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION
      'Only trusted server-side operations can process payouts';
  END IF;

  SELECT *
  INTO v_payout
  FROM public.vendor_payouts
  WHERE id = p_payout_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout not found';
  END IF;

  -- Idempotent status update.
  IF v_payout.status = p_new_status THEN
    RETURN;
  END IF;

  v_transition_allowed :=
    (
      v_payout.status = 'pending'
      AND p_new_status IN (
        'processing',
        'failed',
        'cancelled'
      )
    )
    OR
    (
      v_payout.status = 'processing'
      AND p_new_status IN (
        'succeeded',
        'failed'
      )
    );

  IF NOT v_transition_allowed THEN
    RAISE EXCEPTION
      'Invalid payout status transition: % -> %',
      v_payout.status,
      p_new_status;
  END IF;

  IF p_new_status = 'failed'
    AND (
      p_failure_reason IS NULL
      OR length(trim(p_failure_reason)) = 0
    )
  THEN
    RAISE EXCEPTION
      'A failure reason is required for failed payouts';
  END IF;

  IF p_provider_reference IS NOT NULL
    AND (
      p_provider IS NULL
      OR length(trim(p_provider)) = 0
    )
    AND v_payout.provider IS NULL
  THEN
    RAISE EXCEPTION
      'Provider is required when a provider reference is supplied';
  END IF;

  UPDATE public.vendor_payouts
  SET
    status = p_new_status,

    provider = COALESCE(
      NULLIF(trim(p_provider), ''),
      provider
    ),

    provider_reference = COALESCE(
      NULLIF(trim(p_provider_reference), ''),
      provider_reference
    ),

    failure_reason = CASE
      WHEN p_new_status = 'failed'
        THEN trim(p_failure_reason)
      WHEN p_new_status = 'succeeded'
        THEN NULL
      ELSE failure_reason
    END,

    processed_at = CASE
      WHEN p_new_status IN (
        'processing',
        'succeeded'
      )
      THEN COALESCE(processed_at, NOW())
      ELSE processed_at
    END,

    completed_at = CASE
      WHEN p_new_status = 'succeeded'
        THEN NOW()
      ELSE NULL
    END

  WHERE id = p_payout_id;

  -- Migration 019's existing status synchronization trigger
  -- updates the associated earnings:
  --
  -- succeeded -> paid
  -- failed    -> available
  -- cancelled -> available
END;
$$;

REVOKE ALL ON FUNCTION
  public.update_vendor_payout_status(
    UUID,
    public.vendor_payout_status,
    TEXT,
    TEXT,
    TEXT
  )
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
  public.update_vendor_payout_status(
    UUID,
    public.vendor_payout_status,
    TEXT,
    TEXT,
    TEXT
  )
TO service_role;


-- =========================================================
-- 5. END OF MIGRATION
-- =========================================================
