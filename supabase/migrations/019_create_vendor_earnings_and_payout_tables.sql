
-- 019_create_vendor_earnings_and_payout_tables.sql

-- =========================================================
-- 1. ENUMS
-- =========================================================

CREATE TYPE public.vendor_earning_status AS ENUM (
  'pending',
  'available',
  'reserved',
  'paid',
  'reversed'
);

CREATE TYPE public.vendor_payout_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'cancelled'
);

-- =========================================================
-- 2. VENDOR EARNINGS
-- =========================================================

CREATE TABLE public.vendor_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  vendor_id UUID NOT NULL
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  order_id UUID NOT NULL
    REFERENCES public.orders(id) ON DELETE RESTRICT,

  order_item_id UUID NOT NULL,

  gross_amount BIGINT NOT NULL,
  commission_amount BIGINT NOT NULL DEFAULT 0,
  deduction_amount BIGINT NOT NULL DEFAULT 0,
  net_amount BIGINT NOT NULL,

  currency VARCHAR(3) NOT NULL,

  status public.vendor_earning_status NOT NULL DEFAULT 'pending',

  available_at TIMESTAMPTZ NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT vendor_earnings_order_item_fk
    FOREIGN KEY (order_item_id, order_id)
    REFERENCES public.order_items(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT vendor_earnings_unique_order_item
    UNIQUE (order_item_id),

  CONSTRAINT vendor_earnings_amounts_check
    CHECK (
      gross_amount > 0
      AND commission_amount >= 0
      AND deduction_amount >= 0
      AND net_amount >= 0
      AND net_amount = gross_amount - commission_amount - deduction_amount
    ),

  CONSTRAINT vendor_earnings_currency_check
    CHECK (currency ~ '^[A-Z]{3}$')
);

CREATE INDEX vendor_earnings_vendor_status_idx
  ON public.vendor_earnings(vendor_id, status);

CREATE INDEX vendor_earnings_order_idx
  ON public.vendor_earnings(order_id);

CREATE INDEX vendor_earnings_available_idx
  ON public.vendor_earnings(vendor_id, available_at)
  WHERE status = 'pending';

CREATE TRIGGER set_vendor_earnings_updated_at
BEFORE UPDATE ON public.vendor_earnings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 3. VENDOR PAYOUTS
-- =========================================================

CREATE TABLE public.vendor_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  vendor_id UUID NOT NULL
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  amount BIGINT NOT NULL,

  currency VARCHAR(3) NOT NULL,

  status public.vendor_payout_status NOT NULL DEFAULT 'pending',

  provider TEXT,
  provider_reference TEXT,

  idempotency_key TEXT NOT NULL,

  failure_reason TEXT,

  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT vendor_payouts_amount_check
    CHECK (amount > 0),

  CONSTRAINT vendor_payouts_currency_check
    CHECK (currency ~ '^[A-Z]{3}$'),

  CONSTRAINT vendor_payouts_idempotency_key_check
    CHECK (length(trim(idempotency_key)) > 0),

  CONSTRAINT vendor_payouts_provider_reference_check
    CHECK (
      provider_reference IS NULL
      OR provider IS NOT NULL
    ),

  CONSTRAINT vendor_payouts_completion_check
    CHECK (
      (status = 'succeeded' AND completed_at IS NOT NULL)
      OR
      (status <> 'succeeded' AND completed_at IS NULL)
    )
);

CREATE UNIQUE INDEX vendor_payouts_idempotency_idx
  ON public.vendor_payouts(vendor_id, idempotency_key);

CREATE UNIQUE INDEX vendor_payouts_provider_reference_idx
  ON public.vendor_payouts(provider, provider_reference)
  WHERE provider_reference IS NOT NULL;

CREATE INDEX vendor_payouts_vendor_status_idx
  ON public.vendor_payouts(vendor_id, status);

CREATE INDEX vendor_payouts_requested_at_idx
  ON public.vendor_payouts(requested_at DESC);

CREATE TRIGGER set_vendor_payouts_updated_at
BEFORE UPDATE ON public.vendor_payouts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 4. PAYOUT ITEMS
-- =========================================================

CREATE TABLE public.vendor_payout_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  payout_id UUID NOT NULL
    REFERENCES public.vendor_payouts(id) ON DELETE RESTRICT,

  earning_id UUID NOT NULL
    REFERENCES public.vendor_earnings(id) ON DELETE RESTRICT,

  amount BIGINT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT vendor_payout_items_amount_check
    CHECK (amount > 0),

  CONSTRAINT vendor_payout_items_unique_earning
    UNIQUE (earning_id),

  CONSTRAINT vendor_payout_items_unique_pair
    UNIQUE (payout_id, earning_id)
);

CREATE INDEX vendor_payout_items_payout_idx
  ON public.vendor_payout_items(payout_id);

-- =========================================================
-- 5. VALIDATE PAYOUT ITEM ALLOCATIONS
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_vendor_payout_item()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_earning public.vendor_earnings%ROWTYPE;
  v_payout public.vendor_payouts%ROWTYPE;
  v_allocated BIGINT;
BEGIN
  SELECT *
  INTO v_payout
  FROM public.vendor_payouts
  WHERE id = NEW.payout_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout not found';
  END IF;

  IF v_payout.status <> 'pending' THEN
    RAISE EXCEPTION 'Payout must be pending to allocate earnings';
  END IF;

  SELECT *
  INTO v_earning
  FROM public.vendor_earnings
  WHERE id = NEW.earning_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Vendor earning not found';
  END IF;

  IF v_earning.status <> 'available' THEN
    RAISE EXCEPTION 'Only available earnings can be allocated';
  END IF;

  IF v_earning.vendor_id <> v_payout.vendor_id THEN
    RAISE EXCEPTION 'Payout and earning must belong to the same vendor';
  END IF;

  IF v_earning.currency <> v_payout.currency THEN
    RAISE EXCEPTION 'Payout and earning currencies must match';
  END IF;

  IF NEW.amount > v_earning.net_amount THEN
    RAISE EXCEPTION 'Allocation exceeds earning amount';
  END IF;

  IF NEW.amount <> v_earning.net_amount THEN
    RAISE EXCEPTION 'An earning must be allocated in full';
  END IF;

  SELECT COALESCE(SUM(amount), 0)
  INTO v_allocated
  FROM public.vendor_payout_items
  WHERE payout_id = NEW.payout_id
    AND id <> NEW.id;

  IF v_allocated + NEW.amount > v_payout.amount THEN
    RAISE EXCEPTION 'Allocated earnings exceed requested payout amount';
  END IF;

  UPDATE public.vendor_earnings
  SET status = 'reserved'
  WHERE id = NEW.earning_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_vendor_payout_item_before_insert
BEFORE INSERT ON public.vendor_payout_items
FOR EACH ROW
EXECUTE FUNCTION public.validate_vendor_payout_item();

-- =========================================================
-- 6. ENSURE PAYOUT AMOUNT IS FULLY ALLOCATED
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_vendor_payout_allocation_total()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payout_id UUID;
  v_status public.vendor_payout_status;
  v_amount BIGINT;
  v_allocated BIGINT;
BEGIN
  v_payout_id := COALESCE(NEW.payout_id, OLD.payout_id);

  SELECT status, amount
  INTO v_status, v_amount
  FROM public.vendor_payouts
  WHERE id = v_payout_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT COALESCE(SUM(amount), 0)
  INTO v_allocated
  FROM public.vendor_payout_items
  WHERE payout_id = v_payout_id;

  IF v_status = 'pending' AND v_allocated > v_amount THEN
    RAISE EXCEPTION 'Payout allocations exceed requested amount';
  END IF;

  IF v_status IN ('processing', 'succeeded')
    AND v_allocated <> v_amount
  THEN
    RAISE EXCEPTION 'Payout must be fully allocated before processing';
  END IF;

  RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER validate_payout_allocation_after_item
AFTER INSERT OR UPDATE OR DELETE ON public.vendor_payout_items
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.validate_vendor_payout_allocation_total();

CREATE CONSTRAINT TRIGGER validate_payout_allocation_after_status
AFTER UPDATE OF status ON public.vendor_payouts
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.validate_vendor_payout_allocation_total();

-- =========================================================
-- 7. KEEP EARNING STATUS SYNCHRONIZED
-- =========================================================

CREATE OR REPLACE FUNCTION public.sync_vendor_earning_payout_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payout_status public.vendor_payout_status;
BEGIN
  SELECT status
  INTO v_payout_status
  FROM public.vendor_payouts
  WHERE id = NEW.payout_id;

  IF v_payout_status = 'succeeded' THEN
    UPDATE public.vendor_earnings
    SET status = 'paid'
    WHERE id = NEW.earning_id
      AND status = 'reserved';

  ELSIF v_payout_status IN ('failed', 'cancelled') THEN
    UPDATE public.vendor_earnings
    SET status = 'available'
    WHERE id = NEW.earning_id
      AND status = 'reserved';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_vendor_earning_after_payout_item_insert
AFTER INSERT ON public.vendor_payout_items
FOR EACH ROW
EXECUTE FUNCTION public.sync_vendor_earning_payout_status();

CREATE OR REPLACE FUNCTION public.sync_vendor_payout_items_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'processing' THEN
    UPDATE public.vendor_earnings e
    SET status = 'reserved'
    FROM public.vendor_payout_items pi
    WHERE pi.payout_id = NEW.id
      AND e.id = pi.earning_id
      AND e.status = 'reserved';

    UPDATE public.vendor_payouts
    SET processed_at = COALESCE(processed_at, NOW())
    WHERE id = NEW.id;

  ELSIF NEW.status = 'succeeded' THEN
    UPDATE public.vendor_earnings e
    SET status = 'paid'
    FROM public.vendor_payout_items pi
    WHERE pi.payout_id = NEW.id
      AND e.id = pi.earning_id
      AND e.status = 'reserved';

    UPDATE public.vendor_payouts
    SET completed_at = NOW(),
        processed_at = COALESCE(processed_at, NOW())
    WHERE id = NEW.id;

  ELSIF NEW.status IN ('failed', 'cancelled') THEN
    UPDATE public.vendor_earnings e
    SET status = 'available'
    FROM public.vendor_payout_items pi
    WHERE pi.payout_id = NEW.id
      AND e.id = pi.earning_id
      AND e.status = 'reserved';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_vendor_payout_status
AFTER UPDATE OF status ON public.vendor_payouts
FOR EACH ROW
EXECUTE FUNCTION public.sync_vendor_payout_items_status();

-- =========================================================
-- 8. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.vendor_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_payout_items ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.vendor_earnings TO authenticated;
GRANT SELECT ON public.vendor_payouts TO authenticated;
GRANT SELECT ON public.vendor_payout_items TO authenticated;

CREATE POLICY "Vendors view own earnings"
ON public.vendor_earnings
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.vendor_memberships vm
    WHERE vm.vendor_id = vendor_earnings.vendor_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all earnings"
ON public.vendor_earnings
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

CREATE POLICY "Vendors view own payouts"
ON public.vendor_payouts
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.vendor_memberships vm
    WHERE vm.vendor_id = vendor_payouts.vendor_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all payouts"
ON public.vendor_payouts
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

CREATE POLICY "Vendors view own payout items"
ON public.vendor_payout_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.vendor_payouts p
    JOIN public.vendor_memberships vm
      ON vm.vendor_id = p.vendor_id
    WHERE p.id = vendor_payout_items.payout_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all payout items"
ON public.vendor_payout_items
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- =========================================================
-- 9. RESTRICT INTERNAL FUNCTION EXECUTION
-- =========================================================

REVOKE ALL ON FUNCTION public.validate_vendor_payout_item()
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.validate_vendor_payout_allocation_total()
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.sync_vendor_earning_payout_status()
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.sync_vendor_payout_items_status()
  FROM PUBLIC, anon, authenticated;
