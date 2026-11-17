
-- =========================================================
-- 017: Shipment and tracking tables
-- =========================================================

CREATE TYPE public.shipment_status AS ENUM (
  'pending',
  'label_created',
  'in_transit',
  'out_for_delivery',
  'delivered',
  'exception',
  'returned'
);

-- =========================================================
-- Shipments
-- =========================================================

CREATE TABLE public.shipments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  fulfillment_id uuid NOT NULL
    REFERENCES public.fulfillments(id) ON DELETE RESTRICT,

  carrier text,

  tracking_number text,

  tracking_url text,

  status public.shipment_status NOT NULL DEFAULT 'pending',

  shipped_at timestamptz,
  delivered_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT shipment_tracking_number_check
    CHECK (
      tracking_number IS NULL
      OR length(trim(tracking_number)) > 0
    ),

  CONSTRAINT shipment_carrier_check
    CHECK (
      carrier IS NULL
      OR length(trim(carrier)) > 0
    ),

  CONSTRAINT shipment_tracking_url_check
    CHECK (
      tracking_url IS NULL
      OR tracking_url ~ '^https?://'
    ),

  CONSTRAINT shipment_delivered_at_check
    CHECK (
      delivered_at IS NULL
      OR shipped_at IS NOT NULL
    )
);

CREATE INDEX idx_shipments_fulfillment_id
  ON public.shipments(fulfillment_id);

CREATE INDEX idx_shipments_status
  ON public.shipments(status);

CREATE INDEX idx_shipments_tracking_number
  ON public.shipments(tracking_number)
  WHERE tracking_number IS NOT NULL;

CREATE INDEX idx_shipments_created_at
  ON public.shipments(created_at DESC);

-- =========================================================
-- Shipment tracking events
-- =========================================================

CREATE TABLE public.shipment_tracking_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  shipment_id uuid NOT NULL
    REFERENCES public.shipments(id) ON DELETE RESTRICT,

  status public.shipment_status NOT NULL,

  description text NOT NULL
    CHECK (length(trim(description)) > 0),

  location text,

  occurred_at timestamptz NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_shipment_tracking_events_shipment_id
  ON public.shipment_tracking_events(shipment_id);

CREATE INDEX idx_shipment_tracking_events_occurred_at
  ON public.shipment_tracking_events(shipment_id, occurred_at DESC);

-- =========================================================
-- Updated-at trigger
-- =========================================================

CREATE TRIGGER set_shipments_updated_at
  BEFORE UPDATE ON public.shipments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Tracking event history protection
-- =========================================================

CREATE FUNCTION public.prevent_tracking_event_modification()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'Shipment tracking events are append-only';
END;
$$;

CREATE TRIGGER prevent_tracking_event_modification_trigger
  BEFORE UPDATE OR DELETE ON public.shipment_tracking_events
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_tracking_event_modification();

REVOKE EXECUTE
  ON FUNCTION public.prevent_tracking_event_modification()
  FROM PUBLIC, anon, authenticated;

-- =========================================================
-- Tracking event status synchronization
-- =========================================================

CREATE FUNCTION public.sync_shipment_tracking_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.shipments
  SET
    status = NEW.status,
    shipped_at = CASE
      WHEN NEW.status IN (
        'in_transit',
        'out_for_delivery',
        'delivered'
      )
      THEN COALESCE(shipped_at, NEW.occurred_at)
      ELSE shipped_at
    END,
    delivered_at = CASE
      WHEN NEW.status = 'delivered'
      THEN NEW.occurred_at
      ELSE delivered_at
    END,
    updated_at = now()
  WHERE id = NEW.shipment_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER sync_shipment_tracking_status_trigger
  AFTER INSERT ON public.shipment_tracking_events
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_shipment_tracking_status();

REVOKE EXECUTE
  ON FUNCTION public.sync_shipment_tracking_status()
  FROM PUBLIC, anon, authenticated;

-- =========================================================
-- Row-level security
-- =========================================================

ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipment_tracking_events ENABLE ROW LEVEL SECURITY;

-- Customers can view shipments belonging to their orders.
CREATE POLICY "Customers can view their shipments"
  ON public.shipments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.fulfillments
      JOIN public.orders
        ON orders.id = fulfillments.order_id
      WHERE fulfillments.id = shipments.fulfillment_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all shipments.
CREATE POLICY "Platform admins can view all shipments"
  ON public.shipments
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendor owners can view shipments for their fulfillments.
CREATE POLICY "Vendor owners can view their shipments"
  ON public.shipments
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.fulfillments
      WHERE fulfillments.id = shipments.fulfillment_id
        AND fulfillments.vendor_id IS NOT NULL
        AND public.is_vendor_owner(fulfillments.vendor_id)
    )
  );

-- Customers can view tracking events belonging to their orders.
CREATE POLICY "Customers can view their shipment tracking events"
  ON public.shipment_tracking_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.shipments
      JOIN public.fulfillments
        ON fulfillments.id = shipments.fulfillment_id
      JOIN public.orders
        ON orders.id = fulfillments.order_id
      WHERE shipments.id = shipment_tracking_events.shipment_id
        AND orders.customer_id = (SELECT auth.uid())
    )
  );

-- Platform administrators can view all tracking events.
CREATE POLICY "Platform admins can view all tracking events"
  ON public.shipment_tracking_events
  FOR SELECT
  TO authenticated
  USING (public.is_active_platform_admin());

-- Vendor owners can view tracking events for their shipments.
CREATE POLICY "Vendor owners can view their shipment tracking events"
  ON public.shipment_tracking_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.shipments
      JOIN public.fulfillments
        ON fulfillments.id = shipments.fulfillment_id
      WHERE shipments.id = shipment_tracking_events.shipment_id
        AND fulfillments.vendor_id IS NOT NULL
        AND public.is_vendor_owner(fulfillments.vendor_id)
    )
  );

-- =========================================================
-- Data API permissions
-- =========================================================

GRANT SELECT ON public.shipments TO authenticated;
GRANT SELECT ON public.shipment_tracking_events TO authenticated;

-- No direct client writes.
-- Shipment creation, carrier updates and tracking events
-- will be handled through trusted workflows and integrations.
