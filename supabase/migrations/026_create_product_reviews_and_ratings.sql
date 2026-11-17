
-- =========================================================
-- 026: Product Reviews, Ratings, Vendor Responses & Reports
-- =========================================================

-- =========================================================
-- 1. ENUMS
-- =========================================================

CREATE TYPE public.review_status AS ENUM (
  'pending',
  'published',
  'rejected',
  'hidden'
);

CREATE TYPE public.review_report_reason AS ENUM (
  'spam',
  'abusive',
  'conflict_of_interest',
  'false_information',
  'other'
);

CREATE TYPE public.review_report_status AS ENUM (
  'pending',
  'resolved',
  'dismissed'
);

-- =========================================================
-- 2. PRODUCT REVIEWS
-- =========================================================

CREATE TABLE public.product_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  product_id UUID NOT NULL
    REFERENCES public.products(id) ON DELETE RESTRICT,

  order_id UUID NOT NULL,

  order_item_id UUID NOT NULL,

  customer_id UUID NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  rating SMALLINT NOT NULL
    CHECK (rating BETWEEN 1 AND 5),

  title VARCHAR(120),

  comment TEXT,

  images TEXT[] NOT NULL DEFAULT '{}',

  status public.review_status NOT NULL DEFAULT 'pending',

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT product_reviews_order_item_unique
    UNIQUE (order_item_id),

  CONSTRAINT product_reviews_order_item_fk
    FOREIGN KEY (order_item_id, order_id)
    REFERENCES public.order_items(id, order_id)
    ON DELETE RESTRICT,

  CONSTRAINT product_reviews_content_check
    CHECK (
      (title IS NULL OR char_length(btrim(title)) > 0)
      AND
      (comment IS NULL OR char_length(btrim(comment)) > 0)
      AND
      (title IS NOT NULL OR comment IS NOT NULL)
    ),

  CONSTRAINT product_reviews_images_limit
    CHECK (cardinality(images) <= 5)
);

CREATE INDEX idx_product_reviews_product_status
  ON public.product_reviews(product_id, status);

CREATE INDEX idx_product_reviews_customer
  ON public.product_reviews(customer_id);

CREATE INDEX idx_product_reviews_order
  ON public.product_reviews(order_id);

CREATE INDEX idx_product_reviews_published_rating
  ON public.product_reviews(product_id, rating)
  WHERE status = 'published';

CREATE TRIGGER set_product_reviews_updated_at
BEFORE UPDATE ON public.product_reviews
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- 3. REVIEW VALIDATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_product_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product_id UUID;
  v_order_customer_id UUID;
  v_order_status public.order_status;
BEGIN
  SELECT
    oi.product_id,
    o.customer_id,
    o.status
  INTO
    v_product_id,
    v_order_customer_id,
    v_order_status
  FROM public.order_items oi
  JOIN public.orders o
    ON o.id = oi.order_id
  WHERE oi.id = NEW.order_item_id
    AND oi.order_id = NEW.order_id
  FOR UPDATE OF oi, o;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Purchased order item does not exist';
  END IF;

  IF v_product_id <> NEW.product_id THEN
    RAISE EXCEPTION 'Review product does not match purchased product';
  END IF;

  IF v_order_customer_id <> NEW.customer_id THEN
    RAISE EXCEPTION 'Review customer does not own this order';
  END IF;

  IF v_order_status <> 'fulfilled' THEN
    RAISE EXCEPTION 'Only fully fulfilled orders can be reviewed';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF NEW.product_id <> OLD.product_id
      OR NEW.order_id <> OLD.order_id
      OR NEW.order_item_id <> OLD.order_item_id
      OR NEW.customer_id <> OLD.customer_id
    THEN
      RAISE EXCEPTION 'Review purchase references are immutable';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM unnest(NEW.images) AS image_path
    WHERE image_path IS NULL
      OR char_length(btrim(image_path)) = 0
  ) THEN
    RAISE EXCEPTION 'Review image paths cannot be empty';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_product_review_before_write
BEFORE INSERT OR UPDATE ON public.product_reviews
FOR EACH ROW
EXECUTE FUNCTION public.validate_product_review();

-- =========================================================
-- 4. SUBMIT PRODUCT REVIEW
-- =========================================================

CREATE OR REPLACE FUNCTION public.submit_product_review(
  p_order_item_id UUID,
  p_rating INTEGER,
  p_title TEXT DEFAULT NULL,
  p_comment TEXT DEFAULT NULL,
  p_images TEXT[] DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_customer_id UUID;
  v_product_id UUID;
  v_order_id UUID;
  v_order_status public.order_status;
  v_review_id UUID;
BEGIN
  v_customer_id := auth.uid();

  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_rating IS NULL OR p_rating NOT BETWEEN 1 AND 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;

  IF cardinality(COALESCE(p_images, '{}')) > 5 THEN
    RAISE EXCEPTION 'A maximum of 5 review images is allowed';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = v_customer_id
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Active customer account required';
  END IF;

  SELECT
    oi.product_id,
    oi.order_id,
    o.status
  INTO
    v_product_id,
    v_order_id,
    v_order_status
  FROM public.order_items oi
  JOIN public.orders o
    ON o.id = oi.order_id
  WHERE oi.id = p_order_item_id
    AND o.customer_id = v_customer_id
  FOR UPDATE OF oi, o;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Purchased order item not found';
  END IF;

  IF v_order_status <> 'fulfilled' THEN
    RAISE EXCEPTION 'Only fully fulfilled orders can be reviewed';
  END IF;

  INSERT INTO public.product_reviews (
    product_id,
    order_id,
    order_item_id,
    customer_id,
    rating,
    title,
    comment,
    images
  )
  VALUES (
    v_product_id,
    v_order_id,
    p_order_item_id,
    v_customer_id,
    p_rating,
    NULLIF(btrim(p_title), ''),
    NULLIF(btrim(p_comment), ''),
    COALESCE(p_images, '{}')
  )
  RETURNING id INTO v_review_id;

  RETURN v_review_id;
END;
$$;

-- =========================================================
-- 5. REVIEW MODERATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.moderate_product_review(
  p_review_id UUID,
  p_status public.review_status
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_active_platform_admin() THEN
    RAISE EXCEPTION 'Active platform administrator access required';
  END IF;

  IF p_status = 'pending' THEN
    RAISE EXCEPTION 'Moderation cannot set a review back to pending';
  END IF;

  UPDATE public.product_reviews
  SET status = p_status
  WHERE id = p_review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Review not found';
  END IF;
END;
$$;

-- =========================================================
-- 6. VENDOR REVIEW RESPONSES
-- =========================================================

CREATE TABLE public.product_review_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  review_id UUID NOT NULL
    REFERENCES public.product_reviews(id) ON DELETE CASCADE,

  vendor_id UUID NOT NULL
    REFERENCES public.vendors(id) ON DELETE RESTRICT,

  response TEXT NOT NULL
    CHECK (
      char_length(btrim(response)) BETWEEN 1 AND 3000
    ),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT product_review_responses_review_unique
    UNIQUE (review_id)
);

CREATE INDEX idx_product_review_responses_vendor
  ON public.product_review_responses(vendor_id);

CREATE TRIGGER set_product_review_responses_updated_at
BEFORE UPDATE ON public.product_review_responses
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.upsert_vendor_review_response(
  p_review_id UUID,
  p_response TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_vendor_id UUID;
  v_response_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Active account required';
  END IF;

  SELECT p.vendor_id
  INTO v_vendor_id
  FROM public.product_reviews r
  JOIN public.products p
    ON p.id = r.product_id
  JOIN public.vendors v
    ON v.id = p.vendor_id
  WHERE r.id = p_review_id
    AND r.status = 'published'
    AND v.status = 'active';

  IF NOT FOUND OR v_vendor_id IS NULL THEN
    RAISE EXCEPTION 'Published vendor product review not found';
  END IF;

  IF NOT public.is_vendor_owner(v_vendor_id) THEN
    RAISE EXCEPTION 'Only the product vendor owner can respond';
  END IF;

  INSERT INTO public.product_review_responses (
    review_id,
    vendor_id,
    response
  )
  VALUES (
    p_review_id,
    v_vendor_id,
    btrim(p_response)
  )
  ON CONFLICT (review_id)
  DO UPDATE SET
    response = EXCLUDED.response,
    updated_at = now()
  RETURNING id INTO v_response_id;

  RETURN v_response_id;
END;
$$;

-- =========================================================
-- 7. REVIEW REPORTS
-- =========================================================

CREATE TABLE public.product_review_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  review_id UUID NOT NULL
    REFERENCES public.product_reviews(id) ON DELETE CASCADE,

  customer_id UUID NOT NULL
    REFERENCES public.users(id) ON DELETE RESTRICT,

  reason public.review_report_reason NOT NULL,

  details TEXT,

  status public.review_report_status NOT NULL DEFAULT 'pending',

  reviewed_by UUID
    REFERENCES public.users(id) ON DELETE RESTRICT,

  reviewed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT product_review_reports_customer_unique
    UNIQUE (review_id, customer_id),

  CONSTRAINT product_review_reports_review_check
    CHECK (
      (status = 'pending' AND reviewed_by IS NULL AND reviewed_at IS NULL)
      OR
      (status <> 'pending' AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE INDEX idx_product_review_reports_status
  ON public.product_review_reports(status);

CREATE OR REPLACE FUNCTION public.validate_product_review_report()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_review_customer_id UUID;
BEGIN
  SELECT customer_id
  INTO v_review_customer_id
  FROM public.product_reviews
  WHERE id = NEW.review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Review not found';
  END IF;

  IF v_review_customer_id = NEW.customer_id THEN
    RAISE EXCEPTION 'Customers cannot report their own reviews';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_product_review_report_before_insert
BEFORE INSERT ON public.product_review_reports
FOR EACH ROW
EXECUTE FUNCTION public.validate_product_review_report();

-- =========================================================
-- 8. MODERATE REVIEW REPORT
-- =========================================================

CREATE OR REPLACE FUNCTION public.moderate_product_review_report(
  p_report_id UUID,
  p_status public.review_report_status
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_active_platform_admin() THEN
    RAISE EXCEPTION 'Active platform administrator access required';
  END IF;

  IF p_status = 'pending' THEN
    RAISE EXCEPTION 'Report cannot be returned to pending';
  END IF;

  UPDATE public.product_review_reports
  SET
    status = p_status,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  WHERE id = p_report_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending review report not found';
  END IF;
END;
$$;

-- =========================================================
-- 9. ROW LEVEL SECURITY
-- =========================================================

ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_review_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_review_reports ENABLE ROW LEVEL SECURITY;

-- Published reviews are publicly readable.

CREATE POLICY "Anyone can view published reviews"
ON public.product_reviews
FOR SELECT
TO anon, authenticated
USING (status = 'published');

-- Customers can view all their own reviews.

CREATE POLICY "Customers can view their own reviews"
ON public.product_reviews
FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- Platform administrators can view all reviews.

CREATE POLICY "Platform admins can view all reviews"
ON public.product_reviews
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- Published vendor responses are publicly readable.

CREATE POLICY "Anyone can view responses to published reviews"
ON public.product_review_responses
FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.product_reviews r
    WHERE r.id = review_id
      AND r.status = 'published'
  )
);

CREATE POLICY "Platform admins can view all review responses"
ON public.product_review_responses
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- Customers can report reviews and view their own reports.

CREATE POLICY "Customers can create review reports"
ON public.product_review_reports
FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Customers can view their own review reports"
ON public.product_review_reports
FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

CREATE POLICY "Platform admins can view all review reports"
ON public.product_review_reports
FOR SELECT
TO authenticated
USING (public.is_active_platform_admin());

-- =========================================================
-- 10. PRIVILEGES
-- =========================================================

REVOKE ALL ON public.product_reviews FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.product_review_responses FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.product_review_reports FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.product_reviews TO anon, authenticated;
GRANT SELECT ON public.product_review_responses TO anon, authenticated;

GRANT SELECT, INSERT ON public.product_review_reports TO authenticated;

REVOKE ALL ON FUNCTION public.validate_product_review() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.validate_product_review_report() FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.submit_product_review(UUID, INTEGER, TEXT, TEXT, TEXT[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.moderate_product_review(UUID, public.review_status) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.upsert_vendor_review_response(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.moderate_product_review_report(UUID, public.review_report_status) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.submit_product_review(UUID, INTEGER, TEXT, TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.moderate_product_review(UUID, public.review_status) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_vendor_review_response(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.moderate_product_review_report(UUID, public.review_report_status) TO authenticated;
