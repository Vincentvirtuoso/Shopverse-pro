
-- =========================================================
-- 025: Vendor earning refund holds
-- =========================================================


-- =========================================================
-- 1. VENDOR EARNING HOLDS
-- =========================================================

CREATE TABLE public.vendor_earning_holds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  earning_id UUID NOT NULL
    REFERENCES public.vendor_earnings(id) ON DELETE RESTRICT,

  payment_refund_id UUID NOT NULL
    REFERENCES public.payment_refunds(id) ON DELETE RESTRICT,

  status TEXT NOT NULL DEFAULT 'active',

  resolution_note TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  released_at TIMESTAMPTZ,

  released_by UUID
    REFERENCES public.users(id) ON DELETE SET NULL,

  CONSTRAINT vendor_earning_holds_status_check
    CHECK (status IN ('active', 'released')),

  CONSTRAINT vendor_earning_holds_resolution_check
    CHECK (
      (
        status = 'active'
        AND released_at IS NULL
      )
      OR
      (
        status = 'released'
        AND released_at IS NOT NULL
      )
    ),

  CONSTRAINT vendor_earning_holds_resolution_note_check
    CHECK (
      resolution_note IS NULL
      OR char_length(resolution_note) <= 2000
    ),

  CONSTRAINT vendor_earning_holds_refund_earning_unique
    UNIQUE (earning_id, payment_refund_id)
);

CREATE INDEX vendor_earning_holds_active_earning_idx
  ON public.vendor_earning_holds(earning_id)
  WHERE status = 'active';

CREATE INDEX vendor_earning_holds_refund_idx
  ON public.vendor_earning_holds(payment_refund_id);


-- =========================================================
-- 2. CREATE HOLDS FOR EXISTING EARNINGS
-- =========================================================

CREATE OR REPLACE FUNCTION public.create_vendor_earning_holds_for_refund(
  p_payment_refund_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_id UUID;
  v_refund_status public.payment_refund_status;
BEGIN
  SELECT
    o.id,
    pr.status
  INTO
    v_order_id,
    v_refund_status
  FROM public.payment_refunds pr
  JOIN public.payments p
    ON p.id = pr.payment_id
  JOIN public.orders o
    ON o.id = p.order_id
  WHERE pr.id = p_payment_refund_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment refund or associated order not found';
  END IF;

  IF v_refund_status NOT IN ('pending', 'succeeded') THEN
    RETURN;
  END IF;

  INSERT INTO public.vendor_earning_holds (
    earning_id,
    payment_refund_id
  )
  SELECT
    e.id,
    p_payment_refund_id
  FROM public.vendor_earnings e
  WHERE e.order_id = v_order_id
  ON CONFLICT (earning_id, payment_refund_id)
  DO NOTHING;
END;
$$;


-- =========================================================
-- 3. SYNCHRONIZE HOLDS WITH REFUND STATUS
-- =========================================================

CREATE OR REPLACE FUNCTION public.sync_vendor_earning_refund_holds()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_refund_id UUID;
  v_refund_status public.payment_refund_status;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_refund_id := OLD.id;
  ELSE
    v_refund_id := NEW.id;
    v_refund_status := NEW.status;
  END IF;

  IF TG_OP = 'DELETE'
    OR v_refund_status = 'failed'
  THEN
    UPDATE public.vendor_earning_holds
    SET
      status = 'released',
      released_at = NOW(),
      released_by = NULL,
      resolution_note = CASE
        WHEN TG_OP = 'DELETE'
          THEN 'Refund record deleted'
        ELSE 'Refund failed'
      END
    WHERE payment_refund_id = v_refund_id
      AND status = 'active';

  ELSIF v_refund_status IN ('pending', 'succeeded') THEN
    PERFORM public.create_vendor_earning_holds_for_refund(
      v_refund_id
    );
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_vendor_earning_refund_holds_trigger
AFTER INSERT OR UPDATE OF status OR DELETE
ON public.payment_refunds
FOR EACH ROW
EXECUTE FUNCTION public.sync_vendor_earning_refund_holds();


-- =========================================================
-- 4. HANDLE EARNINGS CREATED AFTER A REFUND
-- =========================================================

-- Migration 023 creates earnings from commission snapshots.
-- This trigger also protects earnings when a refund record
-- already exists before the earning is created.

CREATE OR REPLACE FUNCTION public.apply_existing_refund_holds_to_earning()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.vendor_earning_holds (
    earning_id,
    payment_refund_id
  )
  SELECT
    NEW.id,
    pr.id
  FROM public.payments p
  JOIN public.payment_refunds pr
    ON pr.payment_id = p.id
  WHERE p.order_id = NEW.order_id
    AND pr.status IN ('pending', 'succeeded')
  ON CONFLICT (earning_id, payment_refund_id)
  DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER apply_existing_refund_holds_to_earning_trigger
AFTER INSERT ON public.vendor_earnings
FOR EACH ROW
EXECUTE FUNCTION public.apply_existing_refund_holds_to_earning();


-- =========================================================
-- 5. PREVENT PAYOUT ALLOCATION OF HELD EARNINGS
-- =========================================================

CREATE OR REPLACE FUNCTION public.prevent_payout_allocation_of_held_earnings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.vendor_earning_holds h
    WHERE h.earning_id = NEW.earning_id
      AND h.status = 'active'
  ) THEN
    RAISE EXCEPTION
      'This earning is on hold due to an unresolved refund';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER prevent_payout_allocation_of_held_earnings_trigger
BEFORE INSERT ON public.vendor_payout_items
FOR EACH ROW
EXECUTE FUNCTION public.prevent_payout_allocation_of_held_earnings();


-- =========================================================
-- 6. PREVENT PROCESSING PAYOUTS WITH HELD EARNINGS
-- =========================================================

CREATE OR REPLACE FUNCTION public.prevent_processing_held_payout()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status
    AND NEW.status = 'processing'
  THEN
    IF EXISTS (
      SELECT 1
      FROM public.vendor_payout_items pi
      JOIN public.vendor_earning_holds h
        ON h.earning_id = pi.earning_id
      WHERE pi.payout_id = NEW.id
        AND h.status = 'active'
    ) THEN
      RAISE EXCEPTION
        'Payout contains earnings with unresolved refund holds';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER prevent_processing_held_payout_trigger
BEFORE UPDATE OF status
ON public.vendor_payouts
FOR EACH ROW
EXECUTE FUNCTION public.prevent_processing_held_payout();


-- =========================================================
-- 7. ADMINISTRATIVE HOLD RESOLUTION
-- =========================================================

-- A successful refund must remain held until its financial
-- impact has been reconciled.
--
-- Only an active platform administrator may release it.
-- Pending refunds cannot be manually released.

CREATE OR REPLACE FUNCTION public.resolve_vendor_earning_hold(
  p_hold_id UUID,
  p_resolution_note TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_hold public.vendor_earning_holds%ROWTYPE;
  v_refund_status public.payment_refund_status;
BEGIN
  IF auth.uid() IS NULL
    OR NOT public.is_active_platform_admin()
  THEN
    RAISE EXCEPTION
      'Active platform administrator access is required';
  END IF;

  IF p_resolution_note IS NULL
    OR length(trim(p_resolution_note)) = 0
    OR char_length(p_resolution_note) > 2000
  THEN
    RAISE EXCEPTION
      'A valid resolution note is required';
  END IF;

  SELECT *
  INTO v_hold
  FROM public.vendor_earning_holds
  WHERE id = p_hold_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Earning hold not found';
  END IF;

  IF v_hold.status <> 'active' THEN
    RAISE EXCEPTION 'Earning hold has already been released';
  END IF;

  SELECT status
  INTO v_refund_status
  FROM public.payment_refunds
  WHERE id = v_hold.payment_refund_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Associated refund not found';
  END IF;

  IF v_refund_status <> 'succeeded' THEN
    RAISE EXCEPTION
      'Only successfully processed refunds can be manually reconciled';
  END IF;

  UPDATE public.vendor_earning_holds
  SET
    status = 'released',
    released_at = NOW(),
    released_by = auth.uid(),
    resolution_note = trim(p_resolution_note)
  WHERE id = p_hold_id;
END;
$$;


-- =========================================================
-- 8. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.vendor_earning_holds
  ENABLE ROW LEVEL SECURITY;

GRANT SELECT
ON public.vendor_earning_holds
TO authenticated;

CREATE POLICY "Vendors view own earning holds"
ON public.vendor_earning_holds
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.vendor_earnings e
    JOIN public.vendor_memberships vm
      ON vm.vendor_id = e.vendor_id
    WHERE e.id = vendor_earning_holds.earning_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all earning holds"
ON public.vendor_earning_holds
FOR SELECT
TO authenticated
USING (
  public.is_active_platform_admin()
);


-- =========================================================
-- 9. FUNCTION PERMISSIONS
-- =========================================================

REVOKE ALL ON FUNCTION
  public.create_vendor_earning_holds_for_refund(UUID)
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.sync_vendor_earning_refund_holds()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.apply_existing_refund_holds_to_earning()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.prevent_payout_allocation_of_held_earnings()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.prevent_processing_held_payout()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.resolve_vendor_earning_hold(UUID, TEXT)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION
  public.resolve_vendor_earning_hold(UUID, TEXT)
TO authenticated;


-- =========================================================
-- END OF MIGRATION 025
-- =========================================================
