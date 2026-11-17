
-- =========================================================
-- 013: Order tables
-- =========================================================

CREATE TYPE public.order_status AS ENUM (
  'pending_payment',
  'paid',
  'processing',
  'partially_fulfilled',
  'fulfilled',
  'cancelled',
  'refunded',
  'partially_refunded'
);

-- =========================================================
-- Orders
-- =========================================================

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  order_number text NOT NULL UNIQUE
    CHECK (length(trim(order_number)) > 0),

  customer_id uuid NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  status public.order_status NOT NULL DEFAULT 'pending_payment',

  currency varchar(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  subtotal_amount bigint NOT NULL
    CHECK (subtotal_amount >= 0),

  discount_total_amount bigint NOT NULL DEFAULT 0
    CHECK (discount_total_amount >= 0),

  shipping_total_amount bigint NOT NULL DEFAULT 0
    CHECK (shipping_total_amount >= 0),

  tax_total_amount bigint NOT NULL DEFAULT 0
    CHECK (tax_total_amount >= 0),

  grand_total_amount bigint NOT NULL
    CHECK (grand_total_amount >= 0),

  shipping_address_snapshot jsonb,
  billing_address_snapshot jsonb,

  placed_at timestamptz,
  paid_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT order_discount_within_subtotal
    CHECK (discount_total_amount <= subtotal_amount),

  CONSTRAINT order_grand_total_consistency
    CHECK (
      grand_total_amount =
        subtotal_amount
        - discount_total_amount
        + shipping_total_amount
        + tax_total_amount
    ),

  CONSTRAINT order_address_snapshots_are_objects
    CHECK (
      (shipping_address_snapshot IS NULL OR jsonb_typeof(shipping_address_snapshot) = 'object')
      AND
      (billing_address_snapshot IS NULL OR jsonb_typeof(billing_address_snapshot) = 'object')
    )
);

CREATE INDEX idx_orders_customer_id
  ON public.orders(customer_id);

CREATE INDEX idx_orders_status
  ON public.orders(status);

CREATE INDEX idx_orders_created_at
  ON public.orders(created_at DESC);

CREATE INDEX idx_orders_customer_created_at
  ON public.orders(customer_id, created_at DESC);

-- =========================================================
-- Order items
-- =========================================================

CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  order_id uuid NOT NULL
    REFERENCES public.orders(id) ON DELETE RESTRICT,

  product_id uuid NOT NULL
    REFERENCES public.products(id) ON DELETE RESTRICT,

  variant_id uuid NOT NULL,

  -- Historical ownership at purchase time.
  -- NULL represents a platform-owned product.
  vendor_id uuid
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  snapshot jsonb NOT NULL
    CHECK (jsonb_typeof(snapshot) = 'object'),

  quantity integer NOT NULL
    CHECK (quantity > 0),

  unit_price_amount bigint NOT NULL
    CHECK (unit_price_amount >= 0),

  subtotal_amount bigint NOT NULL
    CHECK (subtotal_amount >= 0),

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT order_item_variant_belongs_to_product
    FOREIGN KEY (variant_id, product_id)
    REFERENCES public.product_variants(id, product_id)
    ON DELETE RESTRICT,

  CONSTRAINT order_item_subtotal_consistency
    CHECK (
      subtotal_amount = unit_price_amount * quantity
    )
);

CREATE INDEX idx_order_items_order_id
  ON public.order_items(order_id);

CREATE INDEX idx_order_items_product_id
  ON public.order_items(product_id);

CREATE INDEX idx_order_items_variant_id
  ON public.order_items(variant_id);

CREATE INDEX idx_order_items_vendor_id
  ON public.order_items(vendor_id)
  WHERE vendor_id IS NOT NULL;

-- =========================================================
-- Checkout relationship
-- =========================================================

ALTER TABLE public.checkouts
  ADD CONSTRAINT checkouts_order_id_fkey
  FOREIGN KEY (order_id)
  REFERENCES public.orders(id)
  ON DELETE RESTRICT;

-- =========================================================
-- Updated-at trigger
-- =========================================================

CREATE TRIGGER set_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Customers can view only their own orders.
CREATE POLICY "Users can view their own orders"
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (customer_id = (SELECT auth.uid()));

-- Platform administrators can view all orders.
CREATE POLICY "Platform admins can view all orders"
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Customers can view items belonging to their orders.
CREATE POLICY "Users can view their own order items"
  ON public.order_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.orders
      WHERE orders.id = order_items.order_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all order items.
CREATE POLICY "Platform admins can view all order items"
  ON public.order_items
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.orders TO authenticated;
GRANT SELECT ON public.order_items TO authenticated;

-- No direct client INSERT, UPDATE or DELETE permissions.
-- Order creation and state transitions will use controlled
-- database workflows.
