
-- 021_create_commission_policy_tables.sql

-- =========================================================
-- 1. PLATFORM COMMISSION POLICIES
-- =========================================================

CREATE TABLE public.commission_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name TEXT NOT NULL,

  default_rate_basis_points INTEGER NOT NULL,
  logistics_rate_basis_points INTEGER NOT NULL DEFAULT 0,

  is_active BOOLEAN NOT NULL DEFAULT FALSE,

  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT commission_policy_name_check
    CHECK (length(trim(name)) > 0),

  CONSTRAINT commission_policy_default_rate_check
    CHECK (default_rate_basis_points BETWEEN 0 AND 10000),

  CONSTRAINT commission_policy_logistics_rate_check
    CHECK (logistics_rate_basis_points BETWEEN 0 AND 10000),

  CONSTRAINT commission_policy_effective_period_check
    CHECK (
      effective_until IS NULL
      OR effective_until > effective_from
    )
);

CREATE UNIQUE INDEX commission_policies_one_active_idx
  ON public.commission_policies(is_active)
  WHERE is_active = TRUE;

CREATE INDEX commission_policies_effective_idx
  ON public.commission_policies(effective_from, effective_until);

CREATE TRIGGER set_commission_policies_updated_at
BEFORE UPDATE ON public.commission_policies
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 2. CATEGORY COMMISSION OVERRIDES
-- =========================================================

CREATE TABLE public.category_commission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  category_id UUID NOT NULL
    REFERENCES public.categories(id) ON DELETE RESTRICT,

  rate_basis_points INTEGER NOT NULL,

  priority INTEGER NOT NULL DEFAULT 0,

  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT category_commission_rate_check
    CHECK (rate_basis_points BETWEEN 0 AND 10000),

  CONSTRAINT category_commission_priority_check
    CHECK (priority >= 0),

  CONSTRAINT category_commission_period_check
    CHECK (
      effective_until IS NULL
      OR effective_until > effective_from
    )
);

CREATE UNIQUE INDEX category_commission_one_active_idx
  ON public.category_commission_overrides(category_id)
  WHERE is_active = TRUE;

CREATE INDEX category_commission_priority_idx
  ON public.category_commission_overrides(
    category_id,
    priority DESC
  );

CREATE TRIGGER set_category_commission_updated_at
BEFORE UPDATE ON public.category_commission_overrides
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 3. VENDOR COMMISSION OVERRIDES
-- =========================================================

CREATE TABLE public.vendor_commission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  vendor_id UUID NOT NULL
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  rate_basis_points INTEGER NOT NULL,

  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_until TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT vendor_commission_rate_check
    CHECK (rate_basis_points BETWEEN 0 AND 10000),

  CONSTRAINT vendor_commission_period_check
    CHECK (
      effective_until IS NULL
      OR effective_until > effective_from
    )
);

CREATE UNIQUE INDEX vendor_commission_one_active_idx
  ON public.vendor_commission_overrides(vendor_id)
  WHERE is_active = TRUE;

CREATE INDEX vendor_commission_vendor_idx
  ON public.vendor_commission_overrides(vendor_id);

CREATE TRIGGER set_vendor_commission_updated_at
BEFORE UPDATE ON public.vendor_commission_overrides
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 4. ORDER ITEM COMMISSION SNAPSHOTS
-- =========================================================

CREATE TABLE public.order_item_commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  order_item_id UUID NOT NULL UNIQUE
    REFERENCES public.order_items(id) ON DELETE RESTRICT,

  commissionable_amount BIGINT NOT NULL,

  standard_rate_basis_points INTEGER NOT NULL,
  standard_rate_source TEXT NOT NULL,

  standard_commission_amount BIGINT NOT NULL,

  logistics_applied BOOLEAN NOT NULL DEFAULT FALSE,
  logistics_rate_basis_points INTEGER NOT NULL DEFAULT 0,
  logistics_commission_amount BIGINT NOT NULL DEFAULT 0,

  total_commission_amount BIGINT NOT NULL,
  vendor_net_amount BIGINT NOT NULL,

  currency VARCHAR(3) NOT NULL,

  policy_id UUID
    REFERENCES public.commission_policies(id) ON DELETE RESTRICT,

  category_override_id UUID
    REFERENCES public.category_commission_overrides(id) ON DELETE RESTRICT,

  vendor_override_id UUID
    REFERENCES public.vendor_commission_overrides(id) ON DELETE RESTRICT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT order_item_commission_amounts_check
    CHECK (
      commissionable_amount >= 0
      AND standard_commission_amount >= 0
      AND logistics_commission_amount >= 0
      AND total_commission_amount >= 0
      AND vendor_net_amount >= 0
    ),

  CONSTRAINT order_item_commission_rates_check
    CHECK (
      standard_rate_basis_points BETWEEN 0 AND 10000
      AND logistics_rate_basis_points BETWEEN 0 AND 10000
    ),

  CONSTRAINT order_item_commission_source_check
    CHECK (
      standard_rate_source IN (
        'platform_default',
        'category_override',
        'vendor_override'
      )
    ),

  CONSTRAINT order_item_commission_currency_check
    CHECK (currency ~ '^[A-Z]{3}$'),

  CONSTRAINT order_item_commission_logistics_check
    CHECK (
      (
        logistics_applied = TRUE
        AND logistics_rate_basis_points > 0
      )
      OR
      (
        logistics_applied = FALSE
        AND logistics_rate_basis_points = 0
        AND logistics_commission_amount = 0
      )
    ),

  CONSTRAINT order_item_commission_total_check
    CHECK (
      total_commission_amount =
        standard_commission_amount + logistics_commission_amount
    ),

  CONSTRAINT order_item_commission_net_check
    CHECK (
      vendor_net_amount =
        commissionable_amount - total_commission_amount
    )
);

CREATE INDEX order_item_commissions_policy_idx
  ON public.order_item_commissions(policy_id);

-- =========================================================
-- 5. VALIDATE COMMISSION SNAPSHOTS
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_order_item_commission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_item public.order_items%ROWTYPE;
  v_product_vendor_id UUID;
BEGIN
  SELECT *
  INTO v_order_item
  FROM public.order_items
  WHERE id = NEW.order_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order item not found';
  END IF;

  IF NEW.commissionable_amount > v_order_item.subtotal THEN
    RAISE EXCEPTION 'Commissionable amount exceeds order item subtotal';
  END IF;

  SELECT p.vendor_id
  INTO v_product_vendor_id
  FROM public.products p
  WHERE p.id = v_order_item.product_id;

  IF v_product_vendor_id IS DISTINCT FROM v_order_item.vendor_id THEN
    RAISE EXCEPTION 'Order item vendor does not match product ownership';
  END IF;

  IF v_order_item.vendor_id IS NULL THEN
    RAISE EXCEPTION 'Vendor commission snapshots require a vendor-owned order item';
  END IF;

  IF NEW.vendor_override_id IS NOT NULL
    AND NEW.standard_rate_source <> 'vendor_override'
  THEN
    RAISE EXCEPTION 'Vendor override reference does not match commission source';
  END IF;

  IF NEW.category_override_id IS NOT NULL
    AND NEW.standard_rate_source <> 'category_override'
  THEN
    RAISE EXCEPTION 'Category override reference does not match commission source';
  END IF;

  IF NEW.standard_rate_source = 'vendor_override'
    AND NEW.vendor_override_id IS NULL
  THEN
    RAISE EXCEPTION 'Vendor commission override reference is required';
  END IF;

  IF NEW.standard_rate_source = 'category_override'
    AND NEW.category_override_id IS NULL
  THEN
    RAISE EXCEPTION 'Category commission override reference is required';
  END IF;

  IF NEW.standard_rate_source = 'platform_default'
    AND (NEW.vendor_override_id IS NOT NULL
      OR NEW.category_override_id IS NOT NULL)
  THEN
    RAISE EXCEPTION 'Platform default cannot reference an override';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_item_commission_before_insert
BEFORE INSERT ON public.order_item_commissions
FOR EACH ROW
EXECUTE FUNCTION public.validate_order_item_commission();

-- Commission snapshots are immutable.
CREATE OR REPLACE FUNCTION public.prevent_order_item_commission_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'Order item commission snapshots cannot be modified or deleted';
END;
$$;

CREATE TRIGGER prevent_order_item_commission_update
BEFORE UPDATE OR DELETE ON public.order_item_commissions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_order_item_commission_modification();

-- =========================================================
-- 6. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.commission_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.category_commission_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_commission_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_item_commissions ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.order_item_commissions TO authenticated;

CREATE POLICY "Platform admins manage commission policies"
ON public.commission_policies
FOR ALL
TO authenticated
USING (public.is_active_platform_admin())
WITH CHECK (public.is_active_platform_admin());

CREATE POLICY "Platform admins manage category commission overrides"
ON public.category_commission_overrides
FOR ALL
TO authenticated
USING (public.is_active_platform_admin())
WITH CHECK (public.is_active_platform_admin());

CREATE POLICY "Platform admins manage vendor commission overrides"
ON public.vendor_commission_overrides
FOR ALL
TO authenticated
USING (public.is_active_platform_admin())
WITH CHECK (public.is_active_platform_admin());

CREATE POLICY "Vendors view own order item commissions"
ON public.order_item_commissions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    JOIN public.vendor_memberships vm
      ON vm.vendor_id = oi.vendor_id
    WHERE oi.id = order_item_commissions.order_item_id
      AND vm.user_id = (SELECT auth.uid())
      AND vm.role = 'owner'
  )
);

CREATE POLICY "Platform admins view all order item commissions"
ON public.order_item_commissions
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- =========================================================
-- 7. INTERNAL FUNCTION PERMISSIONS
-- =========================================================

REVOKE ALL ON FUNCTION public.validate_order_item_commission()
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.prevent_order_item_commission_modification()
  FROM PUBLIC, anon, authenticated;
