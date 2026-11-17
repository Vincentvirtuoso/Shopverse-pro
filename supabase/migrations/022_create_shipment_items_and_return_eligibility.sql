
-- =========================================================
-- 022: Shipment item allocations and return eligibility
-- =========================================================

-- =========================================================
-- 1. SHIPMENT ITEMS
-- =========================================================

CREATE TABLE public.shipment_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  shipment_id UUID NOT NULL
    REFERENCES public.shipments(id) ON DELETE RESTRICT,

  fulfillment_item_id UUID NOT NULL
    REFERENCES public.fulfillment_items(id) ON DELETE RESTRICT,

  order_item_id UUID NOT NULL
    REFERENCES public.order_items(id) ON DELETE RESTRICT,

  quantity INTEGER NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT shipment_items_quantity_check
    CHECK (quantity > 0),

  CONSTRAINT shipment_items_unique_allocation
    UNIQUE (shipment_id, fulfillment_item_id)
);

CREATE INDEX shipment_items_shipment_idx
  ON public.shipment_items(shipment_id);

CREATE INDEX shipment_items_fulfillment_item_idx
  ON public.shipment_items(fulfillment_item_id);

CREATE INDEX shipment_items_order_item_idx
  ON public.shipment_items(order_item_id);

-- =========================================================
-- 2. VALIDATE SHIPMENT ITEM ALLOCATIONS
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_shipment_item_allocation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_shipment public.shipments%ROWTYPE;
  v_fulfillment_item public.fulfillment_items%ROWTYPE;
  v_allocated_quantity BIGINT;
BEGIN
  SELECT *
  INTO v_shipment
  FROM public.shipments
  WHERE id = NEW.shipment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shipment not found';
  END IF;

  IF v_shipment.status NOT IN ('pending', 'label_created') THEN
    RAISE EXCEPTION
      'Shipment allocations cannot change after dispatch';
  END IF;

  SELECT *
  INTO v_fulfillment_item
  FROM public.fulfillment_items
  WHERE id = NEW.fulfillment_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Fulfillment item not found';
  END IF;

  IF v_fulfillment_item.fulfillment_id
      <> v_shipment.fulfillment_id THEN
    RAISE EXCEPTION
      'Fulfillment item does not belong to this shipment fulfillment';
  END IF;

  IF v_fulfillment_item.order_item_id <> NEW.order_item_id THEN
    RAISE EXCEPTION
      'Order item does not match the fulfillment item';
  END IF;

  SELECT COALESCE(SUM(si.quantity), 0)
  INTO v_allocated_quantity
  FROM public.shipment_items si
  WHERE si.fulfillment_item_id = NEW.fulfillment_item_id
    AND si.id <> NEW.id;

  IF v_allocated_quantity + NEW.quantity
      > v_fulfillment_item.quantity THEN
    RAISE EXCEPTION
      'Shipment allocation exceeds fulfillment item quantity';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_shipment_item_allocation_trigger
BEFORE INSERT OR UPDATE OF
  shipment_id,
  fulfillment_item_id,
  order_item_id,
  quantity
ON public.shipment_items
FOR EACH ROW
EXECUTE FUNCTION public.validate_shipment_item_allocation();

-- =========================================================
-- 3. RETURN ELIGIBILITY POLICIES
-- =========================================================

CREATE TABLE public.return_eligibility_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name TEXT NOT NULL,

  return_eligibility_days INTEGER NOT NULL,

  is_active BOOLEAN NOT NULL DEFAULT FALSE,

  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT return_eligibility_policy_name_check
    CHECK (length(trim(name)) > 0),

  CONSTRAINT return_eligibility_days_check
    CHECK (return_eligibility_days BETWEEN 0 AND 365),

  CONSTRAINT return_eligibility_period_check
    CHECK (
      effective_until IS NULL
      OR effective_until > effective_from
    )
);

CREATE UNIQUE INDEX return_eligibility_one_active_policy_idx
  ON public.return_eligibility_policies(is_active)
  WHERE is_active = TRUE;

CREATE INDEX return_eligibility_policy_effective_idx
  ON public.return_eligibility_policies(
    effective_from,
    effective_until
  );

CREATE TRIGGER set_return_eligibility_policies_updated_at
BEFORE UPDATE ON public.return_eligibility_policies
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 4. ORDER RETURN ELIGIBILITY SNAPSHOTS
-- =========================================================

CREATE TABLE public.order_return_eligibility_snapshots (
  order_id UUID PRIMARY KEY
    REFERENCES public.orders(id) ON DELETE RESTRICT,

  policy_id UUID NOT NULL
    REFERENCES public.return_eligibility_policies(id)
    ON DELETE RESTRICT,

  return_eligibility_days INTEGER NOT NULL,

  snapshotted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT order_return_eligibility_days_check
    CHECK (return_eligibility_days BETWEEN 0 AND 365)
);

CREATE INDEX order_return_eligibility_policy_idx
  ON public.order_return_eligibility_snapshots(policy_id);

-- =========================================================
-- 5. PROTECT ORDER POLICY SNAPSHOTS
-- =========================================================

CREATE OR REPLACE FUNCTION public.prevent_return_eligibility_snapshot_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION
    'Order return eligibility snapshots are immutable';
END;
$$;

CREATE TRIGGER prevent_return_eligibility_snapshot_update
BEFORE UPDATE OR DELETE
ON public.order_return_eligibility_snapshots
FOR EACH ROW
EXECUTE FUNCTION public.prevent_return_eligibility_snapshot_modification();

-- =========================================================
-- 6. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.shipment_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.return_eligibility_policies
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.order_return_eligibility_snapshots
  ENABLE ROW LEVEL SECURITY;

-- Shipment item read access.

GRANT SELECT ON public.shipment_items TO authenticated;

CREATE POLICY "Customers can view their shipment items"
ON public.shipment_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.shipments s
    JOIN public.fulfillments f
      ON f.id = s.fulfillment_id
    JOIN public.orders o
      ON o.id = f.order_id
    WHERE s.id = shipment_items.shipment_id
      AND o.customer_id = (SELECT auth.uid())
  )
);

CREATE POLICY "Platform admins can view all shipment items"
ON public.shipment_items
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

CREATE POLICY "Vendor owners can view their shipment items"
ON public.shipment_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.fulfillments f
    JOIN public.vendor_memberships vm
      ON vm.vendor_id = f.vendor_id
    JOIN public.shipments s
      ON s.fulfillment_id = f.id
    WHERE s.id = shipment_items.shipment_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

-- Return eligibility policy management.

GRANT SELECT, INSERT, UPDATE
ON public.return_eligibility_policies
TO authenticated;

CREATE POLICY "Platform admins manage return eligibility policies"
ON public.return_eligibility_policies
FOR ALL
TO authenticated
USING (public.is_active_platform_admin())
WITH CHECK (public.is_active_platform_admin());

-- Order snapshots are readable by the customer and platform admins.

GRANT SELECT
ON public.order_return_eligibility_snapshots
TO authenticated;

CREATE POLICY "Customers can view their return eligibility snapshots"
ON public.order_return_eligibility_snapshots
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.orders o
    WHERE o.id = order_return_eligibility_snapshots.order_id
      AND o.customer_id = (SELECT auth.uid())
  )
);

CREATE POLICY "Platform admins can view return eligibility snapshots"
ON public.order_return_eligibility_snapshots
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- =========================================================
-- 7. INTERNAL FUNCTION PERMISSIONS
-- =========================================================

REVOKE ALL ON FUNCTION public.validate_shipment_item_allocation()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.prevent_return_eligibility_snapshot_modification()
FROM PUBLIC, anon, authenticated;

-- No direct client writes to shipment allocations or snapshots.
-- Trusted workflows will create these records.

-- =========================================================
-- END OF MIGRATION 022
-- =========================================================
