
-- =========================================================
-- 028: Supplier Management & Product Sourcing
-- =========================================================

-- =========================================================
-- 1. ENUMS
-- =========================================================

CREATE TYPE public.supplier_provider AS ENUM (
  'aliexpress',
  'alibaba',
  'custom'
);

CREATE TYPE public.supplier_status AS ENUM (
  'pending',
  'connected',
  'disconnected',
  'suspended'
);

CREATE TYPE public.supplier_product_status AS ENUM (
  'available',
  'unavailable',
  'discontinued',
  'unknown'
);

-- =========================================================
-- 2. SUPPLIERS
-- =========================================================

CREATE TABLE public.suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  owner_type public.product_ownership_type NOT NULL,

  vendor_id UUID
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  name VARCHAR(255) NOT NULL
    CHECK (char_length(btrim(name)) > 0),

  provider public.supplier_provider NOT NULL,

  status public.supplier_status NOT NULL DEFAULT 'pending',

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT suppliers_ownership_check
    CHECK (
      (owner_type = 'platform' AND vendor_id IS NULL)
      OR
      (owner_type = 'vendor' AND vendor_id IS NOT NULL)
    ),

  CONSTRAINT suppliers_id_ownership_unique
    UNIQUE (id, owner_type, vendor_id)
);

CREATE INDEX idx_suppliers_vendor
  ON public.suppliers(vendor_id)
  WHERE vendor_id IS NOT NULL;

CREATE INDEX idx_suppliers_owner_status
  ON public.suppliers(owner_type, status);

CREATE TRIGGER set_suppliers_updated_at
BEFORE UPDATE ON public.suppliers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 3. SUPPLIER PRODUCTS
-- =========================================================

CREATE TABLE public.supplier_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  supplier_id UUID NOT NULL
    REFERENCES public.suppliers(id) ON DELETE RESTRICT,

  external_product_id TEXT NOT NULL
    CHECK (char_length(btrim(external_product_id)) > 0),

  external_url TEXT NOT NULL
    CHECK (
      external_url ~* '^https?://'
    ),

  title VARCHAR(500) NOT NULL
    CHECK (char_length(btrim(title)) > 0),

  status public.supplier_product_status NOT NULL DEFAULT 'unknown',

  last_synced_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT supplier_products_external_id_unique
    UNIQUE (supplier_id, external_product_id),

  CONSTRAINT supplier_products_id_supplier_unique
    UNIQUE (id, supplier_id)
);

CREATE INDEX idx_supplier_products_supplier
  ON public.supplier_products(supplier_id);

CREATE INDEX idx_supplier_products_status
  ON public.supplier_products(supplier_id, status);

CREATE TRIGGER set_supplier_products_updated_at
BEFORE UPDATE ON public.supplier_products
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 4. SUPPLIER PRODUCT VARIANTS
-- =========================================================

CREATE TABLE public.supplier_product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  supplier_product_id UUID NOT NULL
    REFERENCES public.supplier_products(id) ON DELETE RESTRICT,

  external_variant_id TEXT NOT NULL
    CHECK (char_length(btrim(external_variant_id)) > 0),

  title VARCHAR(500) NOT NULL
    CHECK (char_length(btrim(title)) > 0),

  sku TEXT,

  cost_amount BIGINT NOT NULL
    CHECK (cost_amount >= 0),

  currency VARCHAR(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  available_quantity INTEGER
    CHECK (available_quantity IS NULL OR available_quantity >= 0),

  status public.supplier_product_status NOT NULL DEFAULT 'unknown',

  last_synced_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT supplier_product_variants_external_id_unique
    UNIQUE (supplier_product_id, external_variant_id),

  CONSTRAINT supplier_product_variants_id_product_unique
    UNIQUE (id, supplier_product_id)
);

CREATE INDEX idx_supplier_product_variants_product
  ON public.supplier_product_variants(supplier_product_id);

CREATE INDEX idx_supplier_product_variants_status
  ON public.supplier_product_variants(supplier_product_id, status);

CREATE TRIGGER set_supplier_product_variants_updated_at
BEFORE UPDATE ON public.supplier_product_variants
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 5. PRODUCT SUPPLIER SOURCES
-- =========================================================

CREATE TABLE public.product_supplier_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  product_variant_id UUID NOT NULL
    REFERENCES public.product_variants(id) ON DELETE RESTRICT,

  supplier_product_variant_id UUID NOT NULL
    REFERENCES public.supplier_product_variants(id) ON DELETE RESTRICT,

  is_preferred BOOLEAN NOT NULL DEFAULT FALSE,

  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT product_supplier_sources_unique
    UNIQUE (product_variant_id, supplier_product_variant_id)
);

CREATE INDEX idx_product_supplier_sources_variant
  ON public.product_supplier_sources(product_variant_id);

CREATE INDEX idx_product_supplier_sources_supplier_variant
  ON public.product_supplier_sources(supplier_product_variant_id);

CREATE UNIQUE INDEX product_supplier_sources_one_preferred
  ON public.product_supplier_sources(product_variant_id)
  WHERE is_preferred = TRUE AND is_active = TRUE;

CREATE TRIGGER set_product_supplier_sources_updated_at
BEFORE UPDATE ON public.product_supplier_sources
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 6. SUPPLIER OWNERSHIP VALIDATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_supplier_product_ownership()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_type public.product_ownership_type;
  v_vendor_id UUID;
BEGIN
  SELECT owner_type, vendor_id
  INTO v_owner_type, v_vendor_id
  FROM public.suppliers
  WHERE id = NEW.supplier_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Supplier not found';
  END IF;

  IF TG_OP = 'UPDATE'
    AND NEW.supplier_id <> OLD.supplier_id
  THEN
    RAISE EXCEPTION 'Supplier product ownership is immutable';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_supplier_product_before_write
BEFORE INSERT OR UPDATE ON public.supplier_products
FOR EACH ROW
EXECUTE FUNCTION public.validate_supplier_product_ownership();

-- =========================================================
-- 7. SOURCE OWNERSHIP VALIDATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_product_supplier_source()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product_owner public.product_ownership_type;
  v_product_vendor_id UUID;

  v_supplier_owner public.product_ownership_type;
  v_supplier_vendor_id UUID;
BEGIN
  SELECT
    p.owner_type,
    p.vendor_id
  INTO
    v_product_owner,
    v_product_vendor_id
  FROM public.product_variants pv
  JOIN public.products p
    ON p.id = pv.product_id
  WHERE pv.id = NEW.product_variant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Shopverse product variant not found';
  END IF;

  SELECT
    s.owner_type,
    s.vendor_id
  INTO
    v_supplier_owner,
    v_supplier_vendor_id
  FROM public.supplier_product_variants spv
  JOIN public.supplier_products sp
    ON sp.id = spv.supplier_product_id
  JOIN public.suppliers s
    ON s.id = sp.supplier_id
  WHERE spv.id = NEW.supplier_product_variant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Supplier product variant not found';
  END IF;

  IF v_product_owner <> v_supplier_owner
    OR v_product_vendor_id IS DISTINCT FROM v_supplier_vendor_id
  THEN
    RAISE EXCEPTION
      'Supplier and Shopverse product ownership must match';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF NEW.product_variant_id <> OLD.product_variant_id
      OR NEW.supplier_product_variant_id <> OLD.supplier_product_variant_id
    THEN
      RAISE EXCEPTION 'Supplier source associations are immutable';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_product_supplier_source_before_write
BEFORE INSERT OR UPDATE ON public.product_supplier_sources
FOR EACH ROW
EXECUTE FUNCTION public.validate_product_supplier_source();

-- =========================================================
-- 8. SUPPLIER OWNERSHIP HELPER
-- =========================================================

CREATE OR REPLACE FUNCTION public.can_manage_supplier(
  p_supplier_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.suppliers s
    WHERE s.id = p_supplier_id
      AND (
        (
          s.owner_type = 'platform'
          AND (SELECT public.is_active_platform_admin())
        )
        OR
        (
          s.owner_type = 'vendor'
          AND (SELECT public.is_vendor_owner(s.vendor_id))
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.can_manage_supplier(UUID)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.can_manage_supplier(UUID)
TO authenticated;

-- =========================================================
-- 9. ENABLE RLS
-- =========================================================

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_supplier_sources ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 10. SUPPLIER POLICIES
-- =========================================================

CREATE POLICY "Authorized owners can view suppliers"
ON public.suppliers
FOR SELECT
TO authenticated
USING (
  (
    owner_type = 'platform'
    AND (SELECT public.is_active_platform_admin())
  )
  OR
  (
    owner_type = 'vendor'
    AND (SELECT public.is_vendor_owner(vendor_id))
  )
);

CREATE POLICY "Authorized owners can manage suppliers"
ON public.suppliers
FOR ALL
TO authenticated
USING (
  (
    owner_type = 'platform'
    AND (SELECT public.is_active_platform_admin())
  )
  OR
  (
    owner_type = 'vendor'
    AND (SELECT public.is_vendor_owner(vendor_id))
  )
)
WITH CHECK (
  (
    owner_type = 'platform'
    AND (SELECT public.is_active_platform_admin())
  )
  OR
  (
    owner_type = 'vendor'
    AND (SELECT public.is_vendor_owner(vendor_id))
  )
);

-- =========================================================
-- 11. SUPPLIER PRODUCT POLICIES
-- =========================================================

CREATE POLICY "Authorized owners can view supplier products"
ON public.supplier_products
FOR SELECT
TO authenticated
USING (
  (SELECT public.can_manage_supplier(supplier_id))
);

CREATE POLICY "Authorized owners can manage supplier products"
ON public.supplier_products
FOR ALL
TO authenticated
USING (
  (SELECT public.can_manage_supplier(supplier_id))
)
WITH CHECK (
  (SELECT public.can_manage_supplier(supplier_id))
);

-- =========================================================
-- 12. SUPPLIER VARIANT POLICIES
-- =========================================================

CREATE POLICY "Authorized owners can view supplier variants"
ON public.supplier_product_variants
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.supplier_products sp
    WHERE sp.id = supplier_product_id
      AND public.can_manage_supplier(sp.supplier_id)
  )
);

CREATE POLICY "Authorized owners can manage supplier variants"
ON public.supplier_product_variants
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.supplier_products sp
    WHERE sp.id = supplier_product_id
      AND public.can_manage_supplier(sp.supplier_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.supplier_products sp
    WHERE sp.id = supplier_product_id
      AND public.can_manage_supplier(sp.supplier_id)
  )
);

-- =========================================================
-- 13. PRODUCT SUPPLIER SOURCE POLICIES
-- =========================================================

CREATE POLICY "Product owners can view supplier sources"
ON public.product_supplier_sources
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.product_variants pv
    JOIN public.products p
      ON p.id = pv.product_id
    WHERE pv.id = product_variant_id
      AND (
        (
          p.owner_type = 'platform'
          AND (SELECT public.is_active_platform_admin())
        )
        OR
        (
          p.owner_type = 'vendor'
          AND (SELECT public.is_vendor_owner(p.vendor_id))
        )
      )
  )
);

CREATE POLICY "Product owners can manage supplier sources"
ON public.product_supplier_sources
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.product_variants pv
    JOIN public.products p
      ON p.id = pv.product_id
    WHERE pv.id = product_variant_id
      AND (
        (
          p.owner_type = 'platform'
          AND (SELECT public.is_active_platform_admin())
        )
        OR
        (
          p.owner_type = 'vendor'
          AND (SELECT public.is_vendor_owner(p.vendor_id))
        )
      )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.product_variants pv
    JOIN public.products p
      ON p.id = pv.product_id
    WHERE pv.id = product_variant_id
      AND (
        (
          p.owner_type = 'platform'
          AND (SELECT public.is_active_platform_admin())
        )
        OR
        (
          p.owner_type = 'vendor'
          AND (SELECT public.is_vendor_owner(p.vendor_id))
        )
      )
  )
);

-- =========================================================
-- 14. DATA API PRIVILEGES
-- =========================================================

REVOKE ALL ON public.suppliers
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON public.supplier_products
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON public.supplier_product_variants
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON public.product_supplier_sources
FROM PUBLIC, anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.suppliers
TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.supplier_products
TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.supplier_product_variants
TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.product_supplier_sources
TO authenticated;

-- =========================================================
-- 15. FUNCTION PRIVILEGES
-- =========================================================

REVOKE ALL ON FUNCTION
  public.validate_supplier_product_ownership()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.validate_product_supplier_source()
FROM PUBLIC, anon, authenticated;
