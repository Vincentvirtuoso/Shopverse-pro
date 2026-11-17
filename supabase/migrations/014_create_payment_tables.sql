
-- =========================================================
-- 014: Payment and refund tables
-- =========================================================

CREATE TYPE public.payment_provider AS ENUM (
  'stripe',
  'paystack',
  'paypal'
);

CREATE TYPE public.payment_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'cancelled',
  'partially_refunded',
  'refunded'
);

CREATE TYPE public.payment_refund_status AS ENUM (
  'pending',
  'succeeded',
  'failed'
);

-- =========================================================
-- Order/customer relationship
-- =========================================================

-- Allows payment records to enforce that their customer
-- is the actual customer who owns the referenced order.

ALTER TABLE public.orders
  ADD CONSTRAINT orders_id_customer_id_unique
  UNIQUE (id, customer_id);

-- =========================================================
-- Payments
-- =========================================================

CREATE TABLE public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  order_id uuid NOT NULL,
  customer_id uuid NOT NULL,

  provider public.payment_provider NOT NULL,

  provider_reference text,

  status public.payment_status NOT NULL DEFAULT 'pending',

  amount bigint NOT NULL
    CHECK (amount > 0),

  currency varchar(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  refunded_amount bigint NOT NULL DEFAULT 0
    CHECK (refunded_amount >= 0),

  idempotency_key text NOT NULL
    CHECK (length(trim(idempotency_key)) > 0),

  paid_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT payment_order_customer_fkey
    FOREIGN KEY (order_id, customer_id)
    REFERENCES public.orders(id, customer_id)
    ON DELETE RESTRICT,

  CONSTRAINT payment_refund_amount_limit
    CHECK (refunded_amount <= amount),

  CONSTRAINT payment_paid_at_consistency
    CHECK (
      (
        status IN (
          'succeeded',
          'partially_refunded',
          'refunded'
        )
        AND paid_at IS NOT NULL
      )
      OR
      (
        status NOT IN (
          'succeeded',
          'partially_refunded',
          'refunded'
        )
        AND paid_at IS NULL
      )
    ),

  CONSTRAINT payment_refund_status_consistency
    CHECK (
      (
        status = 'partially_refunded'
        AND refunded_amount > 0
        AND refunded_amount < amount
      )
      OR
      (
        status = 'refunded'
        AND refunded_amount = amount
      )
      OR
      (
        status NOT IN ('partially_refunded', 'refunded')
        AND refunded_amount = 0
      )
      OR
      (
        status = 'succeeded'
        AND refunded_amount = 0
      )
    )
);

-- Idempotency is unique per provider.
-- Provider account scoping can be introduced when multiple
-- merchant accounts per provider are supported.

CREATE UNIQUE INDEX idx_payments_provider_idempotency
  ON public.payments(provider, idempotency_key);

CREATE UNIQUE INDEX idx_payments_provider_reference
  ON public.payments(provider, provider_reference)
  WHERE provider_reference IS NOT NULL;

CREATE INDEX idx_payments_order_id
  ON public.payments(order_id);

CREATE INDEX idx_payments_customer_id
  ON public.payments(customer_id);

CREATE INDEX idx_payments_status
  ON public.payments(status);

CREATE INDEX idx_payments_created_at
  ON public.payments(created_at DESC);

-- Prevent multiple successful payment captures for one order.
CREATE UNIQUE INDEX idx_payments_one_successful_capture_per_order
  ON public.payments(order_id)
  WHERE status IN (
    'succeeded',
    'partially_refunded',
    'refunded'
  );

-- =========================================================
-- Payment refunds
-- =========================================================

CREATE TABLE public.payment_refunds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  payment_id uuid NOT NULL
    REFERENCES public.payments(id) ON DELETE RESTRICT,

  amount bigint NOT NULL
    CHECK (amount > 0),

  currency varchar(3) NOT NULL
    CHECK (currency ~ '^[A-Z]{3}$'),

  reason text,

  provider_reference text,

  status public.payment_refund_status NOT NULL DEFAULT 'pending',

  idempotency_key text NOT NULL
    CHECK (length(trim(idempotency_key)) > 0),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT payment_refunds_idempotency_unique
    UNIQUE (payment_id, idempotency_key)
);

CREATE UNIQUE INDEX idx_payment_refunds_provider_reference
  ON public.payment_refunds(provider_reference)
  WHERE provider_reference IS NOT NULL;

CREATE INDEX idx_payment_refunds_payment_id
  ON public.payment_refunds(payment_id);

CREATE INDEX idx_payment_refunds_status
  ON public.payment_refunds(status);

CREATE INDEX idx_payment_refunds_created_at
  ON public.payment_refunds(created_at DESC);

-- =========================================================
-- Payment validation
-- =========================================================

CREATE FUNCTION public.validate_payment_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order_currency varchar(3);
  v_order_total bigint;
BEGIN
  SELECT currency, grand_total_amount
  INTO v_order_currency, v_order_total
  FROM public.orders
  WHERE id = NEW.order_id
    AND customer_id = NEW.customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order does not exist for this customer';
  END IF;

  IF NEW.currency <> v_order_currency THEN
    RAISE EXCEPTION 'Payment currency must match order currency';
  END IF;

  IF NEW.amount <> v_order_total THEN
    RAISE EXCEPTION 'Payment amount must match order total';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_payment_order_trigger
  BEFORE INSERT OR UPDATE OF
    order_id,
    customer_id,
    amount,
    currency
  ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_payment_order();

-- =========================================================
-- Refund validation and aggregate tracking
-- =========================================================

CREATE FUNCTION public.validate_and_track_payment_refund()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payment public.payments%ROWTYPE;
  v_successful_refunds bigint;
BEGIN
  -- Lock the payment row to serialize refund processing.
  SELECT *
  INTO v_payment
  FROM public.payments
  WHERE id = COALESCE(NEW.payment_id, OLD.payment_id)
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment does not exist';
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NEW.currency <> v_payment.currency THEN
      RAISE EXCEPTION 'Refund currency must match payment currency';
    END IF;

    IF v_payment.status NOT IN (
      'succeeded',
      'partially_refunded'
    ) THEN
      RAISE EXCEPTION 'Only successful payments can be refunded';
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.payment_id <> OLD.payment_id THEN
      RAISE EXCEPTION 'A refund cannot be moved to another payment';
    END IF;

    IF NEW.amount <> OLD.amount OR NEW.currency <> OLD.currency THEN
      RAISE EXCEPTION 'Refund amount and currency cannot be changed';
    END IF;

    IF OLD.status <> 'pending' THEN
      RAISE EXCEPTION 'Only pending refunds can change status';
    END IF;

    IF NEW.status = 'pending' THEN
      RAISE EXCEPTION 'Refund status transition is invalid';
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status = 'succeeded' THEN
      RAISE EXCEPTION 'Successful refunds cannot be deleted';
    END IF;

    RETURN OLD;
  END IF;

  SELECT COALESCE(SUM(amount), 0)
  INTO v_successful_refunds
  FROM public.payment_refunds
  WHERE payment_id = v_payment.id
    AND status = 'succeeded'
    AND (
      TG_OP <> 'UPDATE'
      OR id <> OLD.id
    );

  IF TG_OP <> 'DELETE' AND NEW.status = 'succeeded' THEN
    v_successful_refunds :=
      v_successful_refunds + NEW.amount;
  END IF;

  IF v_successful_refunds > v_payment.amount THEN
    RAISE EXCEPTION 'Total successful refunds cannot exceed payment amount';
  END IF;

  UPDATE public.payments
  SET
    refunded_amount = v_successful_refunds,
    status = CASE
      WHEN v_successful_refunds = v_payment.amount
        THEN 'refunded'::public.payment_status
      WHEN v_successful_refunds > 0
        THEN 'partially_refunded'::public.payment_status
      ELSE 'succeeded'::public.payment_status
    END,
    updated_at = now()
  WHERE id = v_payment.id;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER track_payment_refunds_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON public.payment_refunds
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_and_track_payment_refund();

-- =========================================================
-- Updated-at triggers
-- =========================================================

CREATE TRIGGER set_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_payment_refunds_updated_at
  BEFORE UPDATE ON public.payment_refunds
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_refunds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own payments"
  ON public.payments
  FOR SELECT
  TO authenticated
  USING (customer_id = (SELECT auth.uid()));

CREATE POLICY "Platform admins can view all payments"
  ON public.payments
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

CREATE POLICY "Users can view their own refunds"
  ON public.payment_refunds
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.payments
      WHERE payments.id = payment_refunds.payment_id
        AND payments.customer_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Platform admins can view all refunds"
  ON public.payment_refunds
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.payments TO authenticated;
GRANT SELECT ON public.payment_refunds TO authenticated;

-- No direct client writes.
-- Payment creation, provider callbacks, refund requests and
-- refund processing will use controlled server-side workflows.
