
-- ============================================================
-- 018: Return Management
-- ============================================================

-- ------------------------------------------------------------
-- 1. ENUMS
-- ------------------------------------------------------------

CREATE TYPE public.return_status AS ENUM (
  'requested',
  'approved',
  'rejected',
  'awaiting_shipment',
  'in_transit',
  'received',
  'inspecting',
  'completed',
  'cancelled'
);

CREATE TYPE public.return_reason AS ENUM (
  'damaged',
  'defective',
  'wrong_item',
  'missing_parts',
  'not_as_described',
  'wrong_size',
  'changed_mind',
  'other'
);

CREATE TYPE public.return_resolution AS ENUM (
  'refund',
  'replacement',
  'no_refund'
);

-- ------------------------------------------------------------
-- 2. RETURN NUMBER GENERATION
-- ------------------------------------------------------------

CREATE SEQUENCE public.return_number_seq START WITH 1;

-- ------------------------------------------------------------
-- 3. RETURNS
-- ------------------------------------------------------------

CREATE TABLE public.returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  return_number text NOT NULL UNIQUE
    DEFAULT (
      'RET-' ||
      lpad(nextval('public.return_number_seq')::text, 8, '0')
    ),

  order_id uuid NOT NULL,
  customer_id uuid NOT NULL,

  status public.return_status NOT NULL DEFAULT 'requested',

  customer_notes text,
  review_notes text,

  reviewed_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  requested_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  received_at timestamptz,
  resolved_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT returns_order_customer_fk
    FOREIGN KEY (order_id, customer_id)
    REFERENCES public.orders(id, customer_id)
    ON DELETE RESTRICT,

  CONSTRAINT returns_id_order_unique
    UNIQUE (id, order_id),

  CONSTRAINT returns_review_consistency
    CHECK (
      (reviewed_at IS NULL AND reviewed_by IS NULL)
      OR
      (reviewed_at IS NOT NULL AND reviewed_by IS NOT NULL)
    ),

  CONSTRAINT returns_notes_length_check
    CHECK (
      customer_notes IS NULL
      OR char_length(customer_notes) <= 2000
    ),

  CONSTRAINT returns_review_notes_length_check
    CHECK (
      review_notes IS NULL
      OR char_length(review_notes) <= 4000
    )
);

CREATE INDEX idx_returns_order_id
  ON public.returns(order_id);

CREATE INDEX idx_returns_customer_id
  ON public.returns(customer_id);

CREATE INDEX idx_returns_status
  ON public.returns(status);

CREATE INDEX idx_returns_requested_at
  ON public.returns(requested_at DESC);

CREATE INDEX idx_returns_reviewed_by
  ON public.returns(reviewed_by)
  WHERE reviewed_by IS NOT NULL;

CREATE TRIGGER set_returns_updated_at
  BEFORE UPDATE ON public.returns
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ------------------------------------------------------------
-- 4. RETURN ITEMS
-- ------------------------------------------------------------

CREATE TABLE public.return_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  return_id uuid NOT NULL,
  order_id uuid NOT NULL,
  order_item_id uuid NOT NULL,

  requested_quantity integer NOT NULL,
  approved_quantity integer,

  reason public.return_reason NOT NULL,
  reason_details text,

  resolution public.return_resolution,
  resolution_notes text,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT return_items_return_order_fk
    FOREIGN KEY (return_id, order_id)
    REFERENCES public.returns(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT return_items_order_item_fk
    FOREIGN KEY (order_item_id, order_id)
    REFERENCES public.order_items(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT return_items_unique_order_item
    UNIQUE (return_id, order_item_id),

  CONSTRAINT return_items_requested_quantity_check
    CHECK (requested_quantity > 0),

  CONSTRAINT return_items_approved_quantity_check
    CHECK (
      approved_quantity IS NULL
      OR (
        approved_quantity >= 0
        AND approved_quantity <= requested_quantity
      )
    ),

  CONSTRAINT return_items_reason_details_length_check
    CHECK (
      reason_details IS NULL
      OR char_length(reason_details) <= 2000
    ),

  CONSTRAINT return_items_resolution_notes_length_check
    CHECK (
      resolution_notes IS NULL
      OR char_length(resolution_notes) <= 2000
    )
);

CREATE INDEX idx_return_items_return_id
  ON public.return_items(return_id);

CREATE INDEX idx_return_items_order_item_id
  ON public.return_items(order_item_id);

CREATE INDEX idx_return_items_order_id
  ON public.return_items(order_id);

CREATE TRIGGER set_return_items_updated_at
  BEFORE UPDATE ON public.return_items
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ------------------------------------------------------------
-- 5. RETURN QUANTITY PROTECTION
-- ------------------------------------------------------------

-- Prevents customers or trusted workflows from allocating more
-- return quantity than was originally purchased.
--
-- Pending, approved, shipped, received and completed returns
-- all count toward the quantity limit.
--
-- Rejected and cancelled requests release their quantities.

CREATE OR REPLACE FUNCTION public.validate_return_item_quantity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_purchased_quantity integer;
  v_existing_quantity bigint;
BEGIN
  -- Lock the order item to serialize concurrent return requests.
  SELECT oi.quantity
  INTO v_purchased_quantity
  FROM public.order_items oi
  WHERE oi.id = NEW.order_item_id
    AND oi.order_id = NEW.order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order item does not exist for this order';
  END IF;

  SELECT COALESCE(SUM(ri.requested_quantity), 0)
  INTO v_existing_quantity
  FROM public.return_items ri
  INNER JOIN public.returns r
    ON r.id = ri.return_id
  WHERE ri.order_item_id = NEW.order_item_id
    AND r.status NOT IN ('rejected', 'cancelled')
    AND (
      TG_OP = 'INSERT'
      OR ri.id <> NEW.id
    );

  IF v_existing_quantity + NEW.requested_quantity
      > v_purchased_quantity THEN
    RAISE EXCEPTION
      'Requested return quantity exceeds the remaining eligible quantity';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_return_item_quantity
  BEFORE INSERT OR UPDATE OF
    order_item_id,
    order_id,
    requested_quantity
  ON public.return_items
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_return_item_quantity();

-- ------------------------------------------------------------
-- 6. ROW LEVEL SECURITY
-- ------------------------------------------------------------

ALTER TABLE public.returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.return_items ENABLE ROW LEVEL SECURITY;

-- Customers can view their own return requests.

CREATE POLICY "Customers can view their returns"
  ON public.returns
  FOR SELECT
  TO authenticated
  USING (customer_id = (SELECT auth.uid()));

-- Platform administrators can view all returns.

CREATE POLICY "Platform admins can view all returns"
  ON public.returns
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendors can view returns containing their products.

CREATE POLICY "Vendor owners can view relevant returns"
  ON public.returns
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.return_items ri
      INNER JOIN public.order_items oi
        ON oi.id = ri.order_item_id
       AND oi.order_id = ri.order_id
      WHERE ri.return_id = returns.id
        AND oi.vendor_id IS NOT NULL
        AND public.is_vendor_owner(oi.vendor_id)
    )
  );

-- Customers can view their own return items.

CREATE POLICY "Customers can view their return items"
  ON public.return_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.returns r
      WHERE r.id = return_items.return_id
        AND r.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all return items.

CREATE POLICY "Platform admins can view all return items"
  ON public.return_items
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendors can view return items belonging to their products.

CREATE POLICY "Vendor owners can view relevant return items"
  ON public.return_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.order_items oi
      WHERE oi.id = return_items.order_item_id
        AND oi.order_id = return_items.order_id
        AND oi.vendor_id IS NOT NULL
        AND public.is_vendor_owner(oi.vendor_id)
    )
  );

-- ------------------------------------------------------------
-- 7. DATA API PRIVILEGES
-- ------------------------------------------------------------

GRANT SELECT ON public.returns TO authenticated;
GRANT SELECT ON public.return_items TO authenticated;

-- No direct INSERT, UPDATE or DELETE privileges.
-- Return submission and review will use controlled workflows.

REVOKE ALL ON SEQUENCE public.return_number_seq
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.validate_return_item_quantity()
  FROM PUBLIC, anon, authenticated;

-- ============================================================
-- END OF MIGRATION 018
-- ============================================================
