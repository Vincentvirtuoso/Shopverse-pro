
-- =========================================================
-- 023: Vendor earning generation and release workflow
-- =========================================================


-- =========================================================
-- 1. UPDATE VENDOR EARNINGS
-- =========================================================

-- Earnings are created before delivery.
-- available_at represents the scheduled release timestamp.
-- It remains NULL until the complete order-item quantity
-- has been delivered.

ALTER TABLE public.vendor_earnings
  ALTER COLUMN available_at DROP NOT NULL;

ALTER TABLE public.vendor_earnings
  ADD COLUMN delivery_completed_at TIMESTAMPTZ;

ALTER TABLE public.vendor_earnings
  ADD CONSTRAINT vendor_earnings_delivery_release_check
  CHECK (
    (
      delivery_completed_at IS NULL
      AND available_at IS NULL
    )
    OR
    (
      delivery_completed_at IS NOT NULL
      AND available_at IS NOT NULL
      AND available_at >= delivery_completed_at
    )
  );

CREATE INDEX vendor_earnings_release_pending_idx
  ON public.vendor_earnings(available_at)
  WHERE status = 'pending'
    AND available_at IS NOT NULL;


-- =========================================================
-- 2. SNAPSHOT RETURN ELIGIBILITY WHEN AN ORDER IS CREATED
-- =========================================================

CREATE OR REPLACE FUNCTION public.snapshot_order_return_eligibility()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_policy_id UUID;
  v_return_eligibility_days INTEGER;
BEGIN
  SELECT
    p.id,
    p.return_eligibility_days
  INTO
    v_policy_id,
    v_return_eligibility_days
  FROM public.return_eligibility_policies p
  WHERE p.is_active = TRUE
    AND p.effective_from <= NOW()
    AND (
      p.effective_until IS NULL
      OR p.effective_until > NOW()
    )
  ORDER BY p.effective_from DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'No active return eligibility policy is effective';
  END IF;

  INSERT INTO public.order_return_eligibility_snapshots (
    order_id,
    policy_id,
    return_eligibility_days
  )
  VALUES (
    NEW.id,
    v_policy_id,
    v_return_eligibility_days
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER snapshot_order_return_eligibility_trigger
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.snapshot_order_return_eligibility();

REVOKE ALL ON FUNCTION
  public.snapshot_order_return_eligibility()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 3. CREATE VENDOR EARNINGS FROM COMMISSION SNAPSHOTS
-- =========================================================

CREATE OR REPLACE FUNCTION public.create_vendor_earning_from_commission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_vendor_id UUID;
BEGIN
  SELECT oi.vendor_id
  INTO v_vendor_id
  FROM public.order_items oi
  WHERE oi.id = NEW.order_item_id;

  -- Platform-owned products do not generate vendor earnings.
  IF v_vendor_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.vendor_earnings (
    vendor_id,
    order_id,
    order_item_id,
    gross_amount,
    commission_amount,
    deduction_amount,
    net_amount,
    currency,
    status,
    available_at
  )
  VALUES (
    v_vendor_id,
    (
      SELECT oi.order_id
      FROM public.order_items oi
      WHERE oi.id = NEW.order_item_id
    ),
    NEW.order_item_id,
    NEW.commissionable_amount,
    NEW.total_commission_amount,
    0,
    NEW.vendor_net_amount,
    NEW.currency,
    'pending',
    NULL
  )
  ON CONFLICT (order_item_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER create_vendor_earning_from_commission_trigger
AFTER INSERT ON public.order_item_commissions
FOR EACH ROW
EXECUTE FUNCTION public.create_vendor_earning_from_commission();

REVOKE ALL ON FUNCTION
  public.create_vendor_earning_from_commission()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 4. RECALCULATE AN ORDER ITEM'S EARNING ELIGIBILITY
-- =========================================================

CREATE OR REPLACE FUNCTION public.recalculate_vendor_earning(
  p_order_item_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_earning_id UUID;
  v_order_id UUID;
  v_order_quantity BIGINT;
  v_delivered_quantity BIGINT;
  v_delivery_completed_at TIMESTAMPTZ;
  v_return_eligibility_days INTEGER;
  v_available_at TIMESTAMPTZ;
  v_has_active_return BOOLEAN;
BEGIN
  SELECT
    e.id,
    e.order_id
  INTO
    v_earning_id,
    v_order_id
  FROM public.vendor_earnings e
  WHERE e.order_item_id = p_order_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT oi.quantity
  INTO v_order_quantity
  FROM public.order_items oi
  WHERE oi.id = p_order_item_id;

  SELECT s.return_eligibility_days
  INTO v_return_eligibility_days
  FROM public.order_return_eligibility_snapshots s
  WHERE s.order_id = v_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'Return eligibility snapshot missing for order %',
      v_order_id;
  END IF;

  -- Count quantities that have actually been delivered.
  SELECT
    COALESCE(
      SUM(si.quantity) FILTER (
        WHERE sh.status = 'delivered'
          AND sh.delivered_at IS NOT NULL
      ),
      0
    ),
    MAX(sh.delivered_at) FILTER (
      WHERE sh.status = 'delivered'
        AND sh.delivered_at IS NOT NULL
    )
  INTO
    v_delivered_quantity,
    v_delivery_completed_at
  FROM public.shipment_items si
  JOIN public.shipments sh
    ON sh.id = si.shipment_id
  WHERE si.order_item_id = p_order_item_id;

  -- Every purchased unit must be delivered before
  -- the return eligibility period begins.
  IF v_delivered_quantity < v_order_quantity THEN
    v_delivery_completed_at := NULL;
  END IF;

  IF v_delivery_completed_at IS NOT NULL THEN
    v_available_at :=
      v_delivery_completed_at
      + make_interval(days => v_return_eligibility_days);
  ELSE
    v_available_at := NULL;
  END IF;

  -- An unresolved return request holds the affected earning.
  SELECT EXISTS (
    SELECT 1
    FROM public.return_items ri
    JOIN public.returns r
      ON r.id = ri.return_id
    WHERE ri.order_item_id = p_order_item_id
      AND ri.order_id = v_order_id
      AND r.status NOT IN (
        'rejected',
        'cancelled',
        'completed'
      )
  )
  INTO v_has_active_return;

  UPDATE public.vendor_earnings e
  SET
    delivery_completed_at = v_delivery_completed_at,
    available_at = v_available_at,

    status = CASE
      WHEN e.status IN ('pending', 'available') THEN
        CASE
          WHEN v_available_at IS NOT NULL
            AND v_available_at <= NOW()
            AND NOT v_has_active_return
          THEN 'available'::public.vendor_earning_status
          ELSE 'pending'::public.vendor_earning_status
        END
      ELSE e.status
    END

  WHERE e.id = v_earning_id;
END;
$$;

REVOKE ALL ON FUNCTION
  public.recalculate_vendor_earning(UUID)
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 5. RECALCULATE WHEN SHIPMENT ITEMS CHANGE
-- =========================================================

CREATE OR REPLACE FUNCTION public.recalculate_earning_after_shipment_item_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    PERFORM public.recalculate_vendor_earning(
      OLD.order_item_id
    );
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    PERFORM public.recalculate_vendor_earning(
      NEW.order_item_id
    );
  END IF;

  RETURN NULL;
END;
$$;

CREATE TRIGGER recalculate_earning_after_shipment_item_change_trigger
AFTER INSERT OR UPDATE OR DELETE
ON public.shipment_items
FOR EACH ROW
EXECUTE FUNCTION
  public.recalculate_earning_after_shipment_item_change();

REVOKE ALL ON FUNCTION
  public.recalculate_earning_after_shipment_item_change()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 6. RECALCULATE WHEN SHIPMENT DELIVERY STATUS CHANGES
-- =========================================================

CREATE OR REPLACE FUNCTION public.recalculate_earnings_after_shipment_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_item_id UUID;
BEGIN
  FOR v_order_item_id IN
    SELECT DISTINCT si.order_item_id
    FROM public.shipment_items si
    WHERE si.shipment_id = NEW.id
  LOOP
    PERFORM public.recalculate_vendor_earning(
      v_order_item_id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER recalculate_earnings_after_shipment_update_trigger
AFTER UPDATE OF status, delivered_at
ON public.shipments
FOR EACH ROW
WHEN (
  OLD.status IS DISTINCT FROM NEW.status
  OR OLD.delivered_at IS DISTINCT FROM NEW.delivered_at
)
EXECUTE FUNCTION
  public.recalculate_earnings_after_shipment_update();

REVOKE ALL ON FUNCTION
  public.recalculate_earnings_after_shipment_update()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 7. RECALCULATE WHEN RETURN STATUS CHANGES
-- =========================================================

CREATE OR REPLACE FUNCTION public.recalculate_earnings_after_return_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_item_id UUID;
BEGIN
  FOR v_order_item_id IN
    SELECT DISTINCT ri.order_item_id
    FROM public.return_items ri
    WHERE ri.return_id = NEW.id
  LOOP
    PERFORM public.recalculate_vendor_earning(
      v_order_item_id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER recalculate_earnings_after_return_status_change_trigger
AFTER UPDATE OF status
ON public.returns
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION
  public.recalculate_earnings_after_return_status_change();

REVOKE ALL ON FUNCTION
  public.recalculate_earnings_after_return_status_change()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 8. RECALCULATE WHEN RETURN ITEMS CHANGE
-- =========================================================

CREATE OR REPLACE FUNCTION public.recalculate_earnings_after_return_item_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    PERFORM public.recalculate_vendor_earning(
      OLD.order_item_id
    );
  END IF;

  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    PERFORM public.recalculate_vendor_earning(
      NEW.order_item_id
    );
  END IF;

  RETURN NULL;
END;
$$;

CREATE TRIGGER recalculate_earnings_after_return_item_change_trigger
AFTER INSERT OR UPDATE OR DELETE
ON public.return_items
FOR EACH ROW
EXECUTE FUNCTION
  public.recalculate_earnings_after_return_item_change();

REVOKE ALL ON FUNCTION
  public.recalculate_earnings_after_return_item_change()
FROM PUBLIC, anon, authenticated;


-- =========================================================
-- 9. RELEASE EARNINGS WHOSE ELIGIBILITY PERIOD HAS ENDED
-- =========================================================

-- This function should be called periodically by a trusted
-- server-side scheduled worker.
--
-- It rechecks delivery and return status before releasing
-- each earning, rather than blindly changing its status.

CREATE OR REPLACE FUNCTION public.release_eligible_vendor_earnings()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_item_id UUID;
  v_processed_count INTEGER := 0;
BEGIN
  FOR v_order_item_id IN
    SELECT e.order_item_id
    FROM public.vendor_earnings e
    WHERE e.status = 'pending'
      AND e.available_at IS NOT NULL
      AND e.available_at <= NOW()
    ORDER BY e.available_at
    FOR UPDATE OF e SKIP LOCKED
  LOOP
    PERFORM public.recalculate_vendor_earning(
      v_order_item_id
    );

    v_processed_count := v_processed_count + 1;
  END LOOP;

  RETURN v_processed_count;
END;
$$;

REVOKE ALL ON FUNCTION
  public.release_eligible_vendor_earnings()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION
  public.release_eligible_vendor_earnings()
TO service_role;


-- =========================================================
-- END OF MIGRATION 023
-- =========================================================
