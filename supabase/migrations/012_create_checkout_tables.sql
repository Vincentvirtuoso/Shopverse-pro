
-- =========================================================
-- 012: Checkout tables
-- =========================================================

CREATE TYPE public.checkout_status AS ENUM (
  'active',
  'processing',
  'completed',
  'expired',
  'cancelled'
);

-- =========================================================
-- Checkouts
-- =========================================================

CREATE TABLE public.checkouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id uuid NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  status public.checkout_status NOT NULL DEFAULT 'active',

  currency varchar(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  subtotal_amount bigint NOT NULL DEFAULT 0
    CHECK (subtotal_amount >= 0),

  discount_total_amount bigint NOT NULL DEFAULT 0
    CHECK (discount_total_amount >= 0),

  shipping_total_amount bigint NOT NULL DEFAULT 0
    CHECK (shipping_total_amount >= 0),

  tax_total_amount bigint NOT NULL DEFAULT 0
    CHECK (tax_total_amount >= 0),

  grand_total_amount bigint NOT NULL DEFAULT 0
    CHECK (grand_total_amount >= 0),

  shipping_address_snapshot jsonb,
  billing_address_snapshot jsonb,

  order_id uuid UNIQUE,

  expires_at timestamptz NOT NULL,
  completed_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT checkout_discount_within_subtotal
    CHECK (discount_total_amount <= subtotal_amount),

  CONSTRAINT checkout_grand_total_consistency
    CHECK (
      grand_total_amount =
        subtotal_amount
        - discount_total_amount
        + shipping_total_amount
        + tax_total_amount
    ),

  CONSTRAINT checkout_address_snapshots_are_objects
    CHECK (
      (shipping_address_snapshot IS NULL OR jsonb_typeof(shipping_address_snapshot) = 'object')
      AND
      (billing_address_snapshot IS NULL OR jsonb_typeof(billing_address_snapshot) = 'object')
    ),

  CONSTRAINT checkout_completion_consistency
    CHECK (
      (
        status = 'completed'
        AND order_id IS NOT NULL
        AND completed_at IS NOT NULL
      )
      OR
      (
        status <> 'completed'
        AND order_id IS NULL
        AND completed_at IS NULL
      )
    )
);

-- One active checkout per registered customer.
CREATE UNIQUE INDEX idx_checkouts_one_active_per_user
  ON public.checkouts(user_id)
  WHERE status = 'active';

CREATE INDEX idx_checkouts_user_id
  ON public.checkouts(user_id);

CREATE INDEX idx_checkouts_status
  ON public.checkouts(status);

CREATE INDEX idx_checkouts_expires_at
  ON public.checkouts(expires_at)
  WHERE status = 'active';

-- =========================================================
-- Checkout items
-- =========================================================

CREATE TABLE public.checkout_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  checkout_id uuid NOT NULL
    REFERENCES public.checkouts(id) ON DELETE CASCADE,

  product_id uuid NOT NULL
    REFERENCES public.products(id) ON DELETE RESTRICT,

  variant_id uuid NOT NULL,

  vendor_id uuid
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  snapshot jsonb NOT NULL
    CHECK (jsonb_typeof(snapshot) = 'object'),

  quantity integer NOT NULL
    CHECK (quantity > 0),

  unit_price_amount bigint NOT NULL
    CHECK (unit_price_amount >= 0),

  discount_amount bigint NOT NULL DEFAULT 0
    CHECK (discount_amount >= 0),

  subtotal_amount bigint NOT NULL
    CHECK (subtotal_amount >= 0),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT checkout_item_variant_belongs_to_product
    FOREIGN KEY (variant_id, product_id)
    REFERENCES public.product_variants(id, product_id)
    ON DELETE RESTRICT,

  CONSTRAINT checkout_item_discount_limit
    CHECK (discount_amount <= unit_price_amount * quantity),

  CONSTRAINT checkout_item_subtotal_consistency
    CHECK (
      subtotal_amount = unit_price_amount * quantity
    ),

  CONSTRAINT checkout_item_unique_variant
    UNIQUE (checkout_id, variant_id)
);

CREATE INDEX idx_checkout_items_checkout_id
  ON public.checkout_items(checkout_id);

CREATE INDEX idx_checkout_items_product_id
  ON public.checkout_items(product_id);

CREATE INDEX idx_checkout_items_variant_id
  ON public.checkout_items(variant_id);

CREATE INDEX idx_checkout_items_vendor_id
  ON public.checkout_items(vendor_id)
  WHERE vendor_id IS NOT NULL;

-- =========================================================
-- Updated-at triggers
-- =========================================================

CREATE TRIGGER set_checkouts_updated_at
  BEFORE UPDATE ON public.checkouts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_checkout_items_updated_at
  BEFORE UPDATE ON public.checkout_items
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Inventory reservation relationship
-- =========================================================

ALTER TABLE public.inventory_reservations
  ADD CONSTRAINT inventory_reservations_checkout_id_fkey
  FOREIGN KEY (checkout_id)
  REFERENCES public.checkouts(id)
  ON DELETE RESTRICT;

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.checkouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkout_items ENABLE ROW LEVEL SECURITY;

-- Customers can only read their own checkouts.
CREATE POLICY "Users can view their own checkouts"
  ON public.checkouts
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Customers can only read items belonging to their own checkouts.
CREATE POLICY "Users can view their own checkout items"
  ON public.checkout_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.checkouts
      WHERE checkouts.id = checkout_items.checkout_id
        AND checkouts.user_id = (SELECT auth.uid())
    )
  );

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.checkouts TO authenticated;
GRANT SELECT ON public.checkout_items TO authenticated;

-- No direct client INSERT, UPDATE or DELETE permissions.
-- Checkout mutations will be performed through controlled
-- database functions and workflows.
