
-- =========================================================
-- 027: Digital Assets & Purchase Access
-- =========================================================

-- =========================================================
-- 1. ENUM
-- =========================================================

CREATE TYPE public.digital_asset_type AS ENUM (
  'pdf',
  'ebook',
  'image',
  'audio',
  'video',
  'archive',
  'other'
);

-- =========================================================
-- 2. DIGITAL ASSETS
-- =========================================================

CREATE TABLE public.digital_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  product_id UUID NOT NULL
    REFERENCES public.products(id) ON DELETE RESTRICT,

  name VARCHAR(255) NOT NULL
    CHECK (char_length(btrim(name)) > 0),

  file_type public.digital_asset_type NOT NULL,

  -- Private Supabase Storage path, never a public URL.
  storage_path TEXT NOT NULL,

  file_size BIGINT NOT NULL
    CHECK (file_size > 0),

  download_limit INTEGER
    CHECK (download_limit IS NULL OR download_limit > 0),

  is_active BOOLEAN NOT NULL DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT digital_assets_storage_path_check
    CHECK (
      storage_path !~ '^/'
      AND storage_path NOT LIKE '%://%'
      AND storage_path LIKE product_id::TEXT || '/%'
    )
);

CREATE INDEX idx_digital_assets_product
  ON public.digital_assets(product_id);

CREATE INDEX idx_digital_assets_active
  ON public.digital_assets(product_id)
  WHERE is_active = TRUE;

-- =========================================================
-- 3. DIGITAL PURCHASE ACCESS
-- =========================================================

CREATE TABLE public.digital_purchase_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  order_id UUID NOT NULL,

  order_item_id UUID NOT NULL,

  customer_id UUID NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  asset_id UUID NOT NULL
    REFERENCES public.digital_assets(id) ON DELETE RESTRICT,

  download_count INTEGER NOT NULL DEFAULT 0
    CHECK (download_count >= 0),

  -- Snapshot from the asset when access is granted.
  download_limit INTEGER
    CHECK (download_limit IS NULL OR download_limit > 0),

  expires_at TIMESTAMPTZ,

  revoked_at TIMESTAMPTZ,

  revocation_reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT digital_purchase_access_order_item_fk
    FOREIGN KEY (order_item_id, order_id)
    REFERENCES public.order_items(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT digital_purchase_access_unique
    UNIQUE (order_item_id, asset_id),

  CONSTRAINT digital_purchase_access_revocation_check
    CHECK (
      (revoked_at IS NULL AND revocation_reason IS NULL)
      OR
      (revoked_at IS NOT NULL AND revocation_reason IS NOT NULL)
    )
);

CREATE INDEX idx_digital_purchase_access_customer
  ON public.digital_purchase_access(customer_id);

CREATE INDEX idx_digital_purchase_access_order
  ON public.digital_purchase_access(order_id);

CREATE INDEX idx_digital_purchase_access_asset
  ON public.digital_purchase_access(asset_id);

CREATE INDEX idx_digital_purchase_access_active
  ON public.digital_purchase_access(customer_id, expires_at)
  WHERE revoked_at IS NULL;

-- =========================================================
-- 4. VALIDATE DIGITAL ASSETS
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_digital_asset()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product_type TEXT;
BEGIN
  IF TG_OP = 'UPDATE'
    AND NEW.product_id <> OLD.product_id
  THEN
    RAISE EXCEPTION 'Digital asset product association is immutable';
  END IF;

  SELECT type::TEXT
    INTO v_product_type
  FROM public.products
  WHERE id = NEW.product_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF v_product_type <> 'digital' THEN
    RAISE EXCEPTION 'Digital assets can only belong to digital products';
  END IF;

  IF NEW.storage_path !~ (
    '^' || NEW.product_id::TEXT || '/[A-Za-z0-9._/-]+$'
  ) THEN
    RAISE EXCEPTION 'Invalid digital asset storage path';
  END IF;

  IF NEW.storage_path ~ '(^|/)\.\.(/|$)' THEN
    RAISE EXCEPTION 'Storage path cannot contain parent-directory segments';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_digital_asset_before_write
BEFORE INSERT OR UPDATE ON public.digital_assets
FOR EACH ROW
EXECUTE FUNCTION public.validate_digital_asset();

-- =========================================================
-- 5. PRIVATE STORAGE BUCKET
-- =========================================================

INSERT INTO storage.buckets (
  id,
  name,
  public
)
VALUES (
  'digital-products',
  'digital-products',
  FALSE
)
ON CONFLICT (id)
DO UPDATE SET public = FALSE;

-- =========================================================
-- 6. STORAGE ACCESS VALIDATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.can_manage_digital_asset_storage(
  p_object_name TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_product_id UUID;
BEGIN
  IF split_part(p_object_name, '/', 1)
    !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  THEN
    RETURN FALSE;
  END IF;

  v_product_id := split_part(p_object_name, '/', 1)::UUID;

  RETURN public.can_manage_product(v_product_id);
END;
$$;

CREATE POLICY "Digital asset owners can upload files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'digital-products'
  AND public.can_manage_digital_asset_storage(name)
);

CREATE POLICY "Digital asset owners can view stored files"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'digital-products'
  AND public.can_manage_digital_asset_storage(name)
);

CREATE POLICY "Digital asset owners can update files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'digital-products'
  AND public.can_manage_digital_asset_storage(name)
)
WITH CHECK (
  bucket_id = 'digital-products'
  AND public.can_manage_digital_asset_storage(name)
);

CREATE POLICY "Digital asset owners can delete files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'digital-products'
  AND public.can_manage_digital_asset_storage(name)
);

-- Customers do not receive direct Storage object access.
-- Downloads must go through the authorized server-side workflow.

-- =========================================================
-- 7. GRANT ACCESS FOR A PAID ORDER
-- =========================================================

CREATE OR REPLACE FUNCTION public.grant_digital_access_for_order(
  p_order_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_inserted_count INTEGER;
BEGIN
  INSERT INTO public.digital_purchase_access (
    order_id,
    order_item_id,
    customer_id,
    asset_id,
    download_limit
  )
  SELECT
    oi.order_id,
    oi.id,
    o.customer_id,
    da.id,
    da.download_limit
  FROM public.order_items oi
  JOIN public.orders o
    ON o.id = oi.order_id
  JOIN public.products p
    ON p.id = oi.product_id
  JOIN public.digital_assets da
    ON da.product_id = p.id
  WHERE oi.order_id = p_order_id
    AND p.type::TEXT = 'digital'
    AND da.is_active = TRUE
  ON CONFLICT (order_item_id, asset_id)
  DO NOTHING;

  GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

  RETURN v_inserted_count;
END;
$$;

-- =========================================================
-- 8. SYNC ACCESS WITH PAYMENT STATUS
-- =========================================================

CREATE OR REPLACE FUNCTION public.sync_digital_purchase_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'succeeded' THEN

    PERFORM public.grant_digital_access_for_order(NEW.order_id);

  ELSIF NEW.status = 'refunded' THEN

    UPDATE public.digital_purchase_access
    SET
      revoked_at = now(),
      revocation_reason = 'payment_refunded'
    WHERE order_id = NEW.order_id
      AND revoked_at IS NULL;

  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_digital_access_after_payment
AFTER INSERT OR UPDATE OF status
ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.sync_digital_purchase_access();

-- =========================================================
-- 9. GRANT ACCESS FOR ASSETS ADDED AFTER PURCHASE
-- =========================================================

CREATE OR REPLACE FUNCTION public.grant_digital_access_for_asset()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_active = FALSE THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.digital_purchase_access (
    order_id,
    order_item_id,
    customer_id,
    asset_id,
    download_limit
  )
  SELECT
    oi.order_id,
    oi.id,
    o.customer_id,
    NEW.id,
    NEW.download_limit
  FROM public.order_items oi
  JOIN public.orders o
    ON o.id = oi.order_id
  JOIN public.payments pay
    ON pay.order_id = o.id
  JOIN public.products p
    ON p.id = oi.product_id
  WHERE p.id = NEW.product_id
    AND p.type::TEXT = 'digital'
    AND pay.status = 'succeeded'
  ON CONFLICT (order_item_id, asset_id)
  DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER grant_access_after_digital_asset_write
AFTER INSERT OR UPDATE OF is_active
ON public.digital_assets
FOR EACH ROW
EXECUTE FUNCTION public.grant_digital_access_for_asset();

-- =========================================================
-- 10. AUTHORIZE A DIGITAL DOWNLOAD
-- =========================================================

CREATE OR REPLACE FUNCTION public.authorize_digital_download(
  p_access_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_storage_path TEXT;
  v_customer_id UUID;
  v_download_count INTEGER;
  v_download_limit INTEGER;
  v_expires_at TIMESTAMPTZ;
  v_revoked_at TIMESTAMPTZ;
  v_is_active BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT
    da.storage_path,
    access.customer_id,
    access.download_count,
    access.download_limit,
    access.expires_at,
    access.revoked_at,
    da.is_active
  INTO
    v_storage_path,
    v_customer_id,
    v_download_count,
    v_download_limit,
    v_expires_at,
    v_revoked_at,
    v_is_active
  FROM public.digital_purchase_access access
  JOIN public.digital_assets da
    ON da.id = access.asset_id
  WHERE access.id = p_access_id
  FOR UPDATE OF access;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Digital purchase access not found';
  END IF;

  IF v_customer_id <> auth.uid() THEN
    RAISE EXCEPTION 'You do not own this digital purchase';
  END IF;

  IF v_revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'Digital purchase access has been revoked';
  END IF;

  IF NOT v_is_active THEN
    RAISE EXCEPTION 'This digital asset is currently unavailable';
  END IF;

  IF v_expires_at IS NOT NULL
    AND v_expires_at <= now()
  THEN
    RAISE EXCEPTION 'Digital purchase access has expired';
  END IF;

  IF v_download_limit IS NOT NULL
    AND v_download_count >= v_download_limit
  THEN
    RAISE EXCEPTION 'Digital download limit reached';
  END IF;

  UPDATE public.digital_purchase_access
  SET download_count = download_count + 1
  WHERE id = p_access_id;

  RETURN v_storage_path;
END;
$$;

-- =========================================================
-- 11. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.digital_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digital_purchase_access ENABLE ROW LEVEL SECURITY;

-- Asset owners can manage assets belonging to their products.

CREATE POLICY "Product owners can manage digital assets"
ON public.digital_assets
FOR ALL
TO authenticated
USING (
  public.can_manage_product(product_id)
)
WITH CHECK (
  public.can_manage_product(product_id)
);

-- Customers can view assets they have purchased.

CREATE POLICY "Customers can view entitled digital assets"
ON public.digital_assets
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.digital_purchase_access access
    WHERE access.asset_id = digital_assets.id
      AND access.customer_id = auth.uid()
  )
);

-- Platform administrators can view all digital assets.

CREATE POLICY "Platform admins can view all digital assets"
ON public.digital_assets
FOR SELECT
TO authenticated
USING (
  public.is_active_platform_admin()
);

-- Customers can view their own purchase access.

CREATE POLICY "Customers can view their digital purchase access"
ON public.digital_purchase_access
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
);

CREATE POLICY "Platform admins can view all digital purchase access"
ON public.digital_purchase_access
FOR SELECT
TO authenticated
USING (
  public.is_active_platform_admin()
);

-- =========================================================
-- 12. PRIVILEGES
-- =========================================================

REVOKE ALL ON public.digital_assets
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON public.digital_purchase_access
FROM PUBLIC, anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.digital_assets
TO authenticated;

GRANT SELECT
ON public.digital_purchase_access
TO authenticated;

REVOKE ALL ON FUNCTION
  public.validate_digital_asset()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.can_manage_digital_asset_storage(TEXT)
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.grant_digital_access_for_order(UUID)
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.sync_digital_purchase_access()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.grant_digital_access_for_asset()
FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION
  public.authorize_digital_download(UUID)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION
  public.authorize_digital_download(UUID)
TO authenticated;
