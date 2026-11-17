
-- =========================================================
-- 016: Shipping methods, rates and selections
-- =========================================================

CREATE TYPE public.shipping_rate_source AS ENUM (
  'supplier',
  'platform_fixed',
  'dynamic'
);

-- =========================================================
-- Shipping methods
-- =========================================================

CREATE TABLE public.shipping_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  name text NOT NULL
    CHECK (length(trim(name)) > 0),

  description text,

  is_active boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_shipping_methods_active
  ON public.shipping_methods(is_active);

CREATE TRIGGER set_shipping_methods_updated_at
  BEFORE UPDATE ON public.shipping_methods
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Shipping rates
-- =========================================================

CREATE TABLE public.shipping_rates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  shipping_method_id uuid NOT NULL
    REFERENCES public.shipping_methods(id) ON DELETE RESTRICT,

  name text NOT NULL
    CHECK (length(trim(name)) > 0),

  source public.shipping_rate_source NOT NULL,

  amount bigint NOT NULL
    CHECK (amount >= 0),

  currency varchar(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  estimated_min_days integer,
  estimated_max_days integer,

  origin_country char(2),
  destination_country char(2) NOT NULL,

  is_active boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT shipping_rate_estimate_check
    CHECK (
      (
        estimated_min_days IS NULL
        OR estimated_min_days >= 0
      )
      AND
      (
        estimated_max_days IS NULL
        OR estimated_max_days >= 0
      )
      AND
      (
        estimated_min_days IS NULL
        OR estimated_max_days IS NULL
        OR estimated_min_days <= estimated_max_days
      )
    ),

  CONSTRAINT shipping_rate_country_check
    CHECK (
      (origin_country IS NULL OR origin_country ~ '^[A-Z]{2}$')
      AND destination_country ~ '^[A-Z]{2}$'
    ),

  CONSTRAINT shipping_rate_id_method_unique
    UNIQUE (id, shipping_method_id)
);

CREATE INDEX idx_shipping_rates_method_id
  ON public.shipping_rates(shipping_method_id);

CREATE INDEX idx_shipping_rates_destination
  ON public.shipping_rates(destination_country);

CREATE INDEX idx_shipping_rates_active_destination
  ON public.shipping_rates(destination_country, is_active)
  WHERE is_active = true;

CREATE INDEX idx_shipping_rates_source
  ON public.shipping_rates(source);

CREATE TRIGGER set_shipping_rates_updated_at
  BEFORE UPDATE ON public.shipping_rates
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Shipping selections
-- =========================================================

CREATE TABLE public.shipping_selections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  fulfillment_id uuid NOT NULL UNIQUE
    REFERENCES public.fulfillments(id) ON DELETE RESTRICT,

  shipping_method_id uuid NOT NULL,

  shipping_rate_id uuid NOT NULL,

  -- Immutable snapshot of the selected rate.
  rate_snapshot jsonb NOT NULL
    CHECK (jsonb_typeof(rate_snapshot) = 'object'),

  selected_at timestamptz NOT NULL DEFAULT now(),

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT shipping_selection_rate_method_fkey
    FOREIGN KEY (shipping_rate_id, shipping_method_id)
    REFERENCES public.shipping_rates(id, shipping_method_id)
    ON DELETE RESTRICT
);

CREATE INDEX idx_shipping_selections_fulfillment_id
  ON public.shipping_selections(fulfillment_id);

CREATE INDEX idx_shipping_selections_rate_id
  ON public.shipping_selections(shipping_rate_id);

-- =========================================================
-- Shipping selection snapshot validation
-- =========================================================

CREATE FUNCTION public.create_shipping_rate_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_rate public.shipping_rates%ROWTYPE;
  v_fulfillment public.fulfillments%ROWTYPE;
  v_order_currency varchar(3);
BEGIN
  SELECT *
  INTO v_rate
  FROM public.shipping_rates
  WHERE id = NEW.shipping_rate_id
    AND shipping_method_id = NEW.shipping_method_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shipping rate does not exist for this method';
  END IF;

  IF NOT v_rate.is_active THEN
    RAISE EXCEPTION 'Shipping rate is inactive';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.shipping_methods
    WHERE id = NEW.shipping_method_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Shipping method is inactive';
  END IF;

  SELECT *
  INTO v_fulfillment
  FROM public.fulfillments
  WHERE id = NEW.fulfillment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Fulfillment does not exist';
  END IF;

  IF v_fulfillment.status NOT IN (
    'pending',
    'awaiting_supplier'
  ) THEN
    RAISE EXCEPTION 'Shipping cannot be selected after fulfillment processing begins';
  END IF;

  SELECT currency
  INTO v_order_currency
  FROM public.orders
  WHERE id = v_fulfillment.order_id;

  IF v_rate.currency <> v_order_currency THEN
    RAISE EXCEPTION 'Shipping rate currency must match order currency';
  END IF;

  NEW.rate_snapshot := jsonb_build_object(
    'id', v_rate.id,
    'name', v_rate.name,
    'source', v_rate.source,
    'amount', v_rate.amount,
    'currency', v_rate.currency,
    'estimatedMinDays', v_rate.estimated_min_days,
    'estimatedMaxDays', v_rate.estimated_max_days,
    'originCountry', v_rate.origin_country,
    'destinationCountry', v_rate.destination_country
  );

  NEW.selected_at := COALESCE(NEW.selected_at, now());

  RETURN NEW;
END;
$$;

CREATE TRIGGER create_shipping_rate_snapshot_trigger
  BEFORE INSERT ON public.shipping_selections
  FOR EACH ROW
  EXECUTE FUNCTION public.create_shipping_rate_snapshot();

REVOKE EXECUTE
  ON FUNCTION public.create_shipping_rate_snapshot()
  FROM PUBLIC, anon, authenticated;

-- =========================================================
-- Immutable shipping selection snapshots
-- =========================================================

CREATE FUNCTION public.prevent_shipping_selection_modification()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'Shipping selections are immutable';
END;
$$;

CREATE TRIGGER prevent_shipping_selection_modification_trigger
  BEFORE UPDATE OR DELETE ON public.shipping_selections
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_shipping_selection_modification();

REVOKE EXECUTE
  ON FUNCTION public.prevent_shipping_selection_modification()
  FROM PUBLIC, anon, authenticated;

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.shipping_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_selections ENABLE ROW LEVEL SECURITY;

-- Authenticated customers can view active shipping methods.
CREATE POLICY "Users can view active shipping methods"
  ON public.shipping_methods
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    OR public.is_active_platform_admin()
  );

-- Authenticated customers can view active shipping rates.
CREATE POLICY "Users can view active shipping rates"
  ON public.shipping_rates
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    OR public.is_active_platform_admin()
  );

-- Customers can view shipping selections belonging to their orders.
CREATE POLICY "Customers can view their shipping selections"
  ON public.shipping_selections
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.fulfillments
      JOIN public.orders
        ON orders.id = fulfillments.order_id
      WHERE fulfillments.id = shipping_selections.fulfillment_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all shipping selections.
CREATE POLICY "Platform admins can view all shipping selections"
  ON public.shipping_selections
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendor owners can view shipping selections for their fulfillments.
CREATE POLICY "Vendor owners can view their shipping selections"
  ON public.shipping_selections
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.fulfillments
      WHERE fulfillments.id = shipping_selections.fulfillment_id
        AND fulfillments.vendor_id IS NOT NULL
        AND public.is_vendor_owner(fulfillments.vendor_id)
    )
  );

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.shipping_methods TO authenticated;
GRANT SELECT ON public.shipping_rates TO authenticated;
GRANT SELECT ON public.shipping_selections TO authenticated;

-- No direct client writes.
-- Shipping method/rate management and shipping selection
-- will be handled through controlled workflows.
