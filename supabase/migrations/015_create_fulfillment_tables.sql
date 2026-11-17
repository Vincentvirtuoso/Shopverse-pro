
-- =========================================================
-- 015: Fulfillment tables
-- =========================================================

CREATE TYPE public.fulfillment_status AS ENUM (
  'pending',
  'awaiting_supplier',
  'processing',
  'shipped',
  'delivered',
  'failed',
  'cancelled'
);

CREATE TYPE public.fulfillment_source_type AS ENUM (
  'platform',
  'vendor'
);

-- =========================================================
-- Fulfillments
-- =========================================================

CREATE TABLE public.fulfillments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  order_id uuid NOT NULL
    REFERENCES public.orders(id) ON DELETE RESTRICT,

  source_type public.fulfillment_source_type NOT NULL,

  vendor_id uuid
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  -- Supplier integration is deferred.
  -- The supplier relationship will be added when that
  -- domain is introduced.
  supplier_id uuid,

  status public.fulfillment_status NOT NULL DEFAULT 'pending',

  external_order_reference text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT fulfillment_source_consistency
    CHECK (
      (
        source_type = 'platform'
        AND vendor_id IS NULL
      )
      OR
      (
        source_type = 'vendor'
        AND vendor_id IS NOT NULL
      )
    ),

  CONSTRAINT fulfillment_supplier_reference_check
    CHECK (
      supplier_id IS NULL
      OR source_type = 'platform'
      OR source_type = 'vendor'
    ),

  CONSTRAINT fulfillment_id_order_id_unique
    UNIQUE (id, order_id)
);

CREATE INDEX idx_fulfillments_order_id
  ON public.fulfillments(order_id);

CREATE INDEX idx_fulfillments_vendor_id
  ON public.fulfillments(vendor_id)
  WHERE vendor_id IS NOT NULL;

CREATE INDEX idx_fulfillments_status
  ON public.fulfillments(status);

CREATE INDEX idx_fulfillments_supplier_id
  ON public.fulfillments(supplier_id)
  WHERE supplier_id IS NOT NULL;

CREATE INDEX idx_fulfillments_created_at
  ON public.fulfillments(created_at DESC);

-- =========================================================
-- Fulfillment items
-- =========================================================

ALTER TABLE public.order_items
  ADD CONSTRAINT order_items_id_order_id_unique
  UNIQUE (id, order_id);

CREATE TABLE public.fulfillment_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  fulfillment_id uuid NOT NULL,
  order_id uuid NOT NULL,

  order_item_id uuid NOT NULL,

  quantity integer NOT NULL
    CHECK (quantity > 0),

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT fulfillment_item_fulfillment_order_fkey
    FOREIGN KEY (fulfillment_id, order_id)
    REFERENCES public.fulfillments(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT fulfillment_item_order_item_fkey
    FOREIGN KEY (order_item_id, order_id)
    REFERENCES public.order_items(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT fulfillment_item_unique_order_item
    UNIQUE (fulfillment_id, order_item_id)
);

CREATE INDEX idx_fulfillment_items_fulfillment_id
  ON public.fulfillment_items(fulfillment_id);

CREATE INDEX idx_fulfillment_items_order_item_id
  ON public.fulfillment_items(order_item_id);

CREATE INDEX idx_fulfillment_items_order_id
  ON public.fulfillment_items(order_id);

-- =========================================================
-- Fulfillment item validation
-- =========================================================

CREATE FUNCTION public.validate_fulfillment_item()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_fulfillment public.fulfillments%ROWTYPE;
  v_order_item public.order_items%ROWTYPE;
  v_allocated_quantity bigint;
BEGIN
  SELECT *
  INTO v_fulfillment
  FROM public.fulfillments
  WHERE id = NEW.fulfillment_id
    AND order_id = NEW.order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Fulfillment does not exist for this order';
  END IF;

  IF v_fulfillment.status NOT IN (
    'pending',
    'awaiting_supplier'
  ) THEN
    RAISE EXCEPTION 'Items cannot be changed after fulfillment processing begins';
  END IF;

  SELECT *
  INTO v_order_item
  FROM public.order_items
  WHERE id = NEW.order_item_id
    AND order_id = NEW.order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order item does not belong to this order';
  END IF;

  -- The fulfillment source must match the historical
  -- ownership recorded on the purchased order item.
  IF v_fulfillment.source_type = 'platform'
     AND v_order_item.vendor_id IS NOT NULL THEN
    RAISE EXCEPTION 'Vendor-owned order items require vendor fulfillment';
  END IF;

  IF v_fulfillment.source_type = 'vendor'
     AND v_order_item.vendor_id IS DISTINCT FROM v_fulfillment.vendor_id THEN
    RAISE EXCEPTION 'Order item belongs to a different vendor';
  END IF;

  SELECT COALESCE(SUM(quantity), 0)
  INTO v_allocated_quantity
  FROM public.fulfillment_items
  WHERE order_item_id = NEW.order_item_id
    AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

  IF v_allocated_quantity + NEW.quantity > v_order_item.quantity THEN
    RAISE EXCEPTION 'Fulfillment quantity exceeds purchased quantity';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_fulfillment_item_trigger
  BEFORE INSERT OR UPDATE
  ON public.fulfillment_items
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_fulfillment_item();

-- =========================================================
-- Updated-at trigger
-- =========================================================

CREATE TRIGGER set_fulfillments_updated_at
  BEFORE UPDATE ON public.fulfillments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.fulfillments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fulfillment_items ENABLE ROW LEVEL SECURITY;

-- Customers can view fulfillments belonging to their orders.
CREATE POLICY "Customers can view their own fulfillments"
  ON public.fulfillments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.orders
      WHERE orders.id = fulfillments.order_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all fulfillments.
CREATE POLICY "Platform admins can view all fulfillments"
  ON public.fulfillments
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendor owners can view their vendor fulfillments.
CREATE POLICY "Vendor owners can view their fulfillments"
  ON public.fulfillments
  FOR SELECT
  TO authenticated
  USING (
    vendor_id IS NOT NULL
    AND public.is_vendor_owner(vendor_id)
  );

-- Customers can view items belonging to their orders.
CREATE POLICY "Customers can view their fulfillment items"
  ON public.fulfillment_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.orders
      WHERE orders.id = fulfillment_items.order_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all fulfillment items.
CREATE POLICY "Platform admins can view all fulfillment items"
  ON public.fulfillment_items
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendor owners can view their fulfillment items.
CREATE POLICY "Vendor owners can view their fulfillment items"
  ON public.fulfillment_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.fulfillments
      WHERE fulfillments.id = fulfillment_items.fulfillment_id
        AND fulfillments.vendor_id IS NOT NULL
        AND public.is_vendor_owner(fulfillments.vendor_id)
    )
  );

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.fulfillments TO authenticated;
GRANT SELECT ON public.fulfillment_items TO authenticated;

-- No direct client writes.
-- Fulfillment creation, allocation and status transitions
-- will use controlled workflows.
