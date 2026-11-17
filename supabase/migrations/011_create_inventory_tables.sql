
-- =========================================================
-- 011: Inventory foundation
-- Shopverse
-- =========================================================

-- 1. Enums

create type public.inventory_tracking_mode as enum (
  'manual',
  'hybrid'
);

create type public.inventory_location_type as enum (
  'warehouse',
  'store',
  'fulfillment_center',
  'other'
);

create type public.inventory_location_ownership_type as enum (
  'platform',
  'vendor'
);

create type public.inventory_adjustment_reason as enum (
  'restock',
  'sale',
  'return',
  'damage',
  'correction'
);

create type public.inventory_reservation_status as enum (
  'active',
  'committed',
  'released',
  'expired'
);

-- 2. Inventory locations

create table public.inventory_locations (
  id uuid primary key default gen_random_uuid(),

  owner_type public.inventory_location_ownership_type not null,

  vendor_id uuid
    references public.vendors(id) on delete restrict,

  name text not null,
  code text not null,

  type public.inventory_location_type not null,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint inventory_location_ownership_check
    check (
      (owner_type = 'platform' and vendor_id is null)
      or
      (owner_type = 'vendor' and vendor_id is not null)
    ),

  constraint inventory_location_name_not_empty
    check (nullif(pg_catalog.btrim(name), '') is not null),

  constraint inventory_location_code_not_empty
    check (nullif(pg_catalog.btrim(code), '') is not null)
);

create unique index inventory_locations_platform_code_unique
  on public.inventory_locations(code)
  where vendor_id is null;

create unique index inventory_locations_vendor_code_unique
  on public.inventory_locations(vendor_id, code)
  where vendor_id is not null;

create index inventory_locations_vendor_idx
  on public.inventory_locations(vendor_id)
  where vendor_id is not null;

create index inventory_locations_active_idx
  on public.inventory_locations(is_active);

create trigger set_inventory_locations_updated_at
  before update on public.inventory_locations
  for each row
  execute function public.set_updated_at();

-- 3. Inventory levels

create table public.inventory_levels (
  id uuid primary key default gen_random_uuid(),

  variant_id uuid not null
    references public.product_variants(id) on delete restrict,

  location_id uuid not null
    references public.inventory_locations(id) on delete restrict,

  on_hand_quantity bigint not null default 0
    check (on_hand_quantity >= 0),

  reserved_quantity bigint not null default 0
    check (reserved_quantity >= 0),

  tracking_mode public.inventory_tracking_mode
    not null default 'manual',

  updated_at timestamptz not null default now(),

  constraint inventory_level_reserved_quantity_check
    check (reserved_quantity <= on_hand_quantity),

  constraint inventory_level_variant_location_unique
    unique (variant_id, location_id)
);

create index inventory_levels_location_idx
  on public.inventory_levels(location_id);

create index inventory_levels_variant_idx
  on public.inventory_levels(variant_id);

create trigger set_inventory_levels_updated_at
  before update on public.inventory_levels
  for each row
  execute function public.set_updated_at();

-- 4. Validate inventory location ownership.
-- A product variant and its inventory location must have
-- the same owner: platform or the same vendor.

create or replace function public.validate_inventory_level_ownership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  product_owner_type public.product_ownership_type;
  product_vendor_id uuid;

  location_owner_type public.inventory_location_ownership_type;
  location_vendor_id uuid;
begin
  select
    product.owner_type,
    product.vendor_id
  into
    product_owner_type,
    product_vendor_id
  from public.product_variants variant
  join public.products product
    on product.id = variant.product_id
  where variant.id = new.variant_id;

  if not found then
    raise exception 'Inventory variant does not exist';
  end if;

  select
    location.owner_type,
    location.vendor_id
  into
    location_owner_type,
    location_vendor_id
  from public.inventory_locations location
  where location.id = new.location_id;

  if not found then
    raise exception 'Inventory location does not exist';
  end if;

  if product_owner_type::text <> location_owner_type::text
    or product_vendor_id is distinct from location_vendor_id
  then
    raise exception
      'Inventory location must have the same owner as the product';
  end if;

  return new;
end;
$$;

create trigger validate_inventory_level_ownership_trigger
  before insert or update of variant_id, location_id
  on public.inventory_levels
  for each row
  execute function public.validate_inventory_level_ownership();

-- 5. Inventory adjustments
-- These record physical stock movements only.
-- Reservations and releases are recorded separately.

create table public.inventory_adjustments (
  id uuid primary key default gen_random_uuid(),

  inventory_level_id uuid not null
    references public.inventory_levels(id) on delete restrict,

  quantity_change bigint not null
    check (quantity_change <> 0),

  reason public.inventory_adjustment_reason not null,

  reference_id text,
  note text,

  created_at timestamptz not null default now(),

  constraint inventory_adjustment_reason_sign_check
    check (
      (reason in ('restock', 'return') and quantity_change > 0)
      or
      (reason in ('sale', 'damage') and quantity_change < 0)
      or
      reason = 'correction'
    )
);

create index inventory_adjustments_level_idx
  on public.inventory_adjustments(inventory_level_id);

create index inventory_adjustments_reason_idx
  on public.inventory_adjustments(reason);

create index inventory_adjustments_created_at_idx
  on public.inventory_adjustments(created_at desc);

-- 6. Inventory reservations
-- One reservation per checkout.
-- The checkout foreign key will be added after the checkout
-- table is introduced in a later migration.

create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),

  checkout_id uuid not null unique,

  status public.inventory_reservation_status
    not null default 'active',

  expires_at timestamptz not null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index inventory_reservations_status_expiry_idx
  on public.inventory_reservations(status, expires_at);

create trigger set_inventory_reservations_updated_at
  before update on public.inventory_reservations
  for each row
  execute function public.set_updated_at();

-- 7. Inventory reservation items

create table public.inventory_reservation_items (
  id uuid primary key default gen_random_uuid(),

  reservation_id uuid not null
    references public.inventory_reservations(id) on delete restrict,

  inventory_level_id uuid not null
    references public.inventory_levels(id) on delete restrict,

  quantity bigint not null
    check (quantity > 0),

  created_at timestamptz not null default now(),

  constraint inventory_reservation_item_unique
    unique (reservation_id, inventory_level_id)
);

create index inventory_reservation_items_level_idx
  on public.inventory_reservation_items(inventory_level_id);

-- 8. Prevent reservation items from referencing inactive
-- inventory locations.

create or replace function public.validate_inventory_reservation_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  location_is_active boolean;
  reservation_status_value public.inventory_reservation_status;
begin
  select
    location.is_active
  into location_is_active
  from public.inventory_levels level
  join public.inventory_locations location
    on location.id = level.location_id
  where level.id = new.inventory_level_id;

  if not found or not location_is_active then
    raise exception 'Inventory level is unavailable for reservation';
  end if;

  select status
  into reservation_status_value
  from public.inventory_reservations
  where id = new.reservation_id;

  if not found or reservation_status_value <> 'active' then
    raise exception 'Reservation must be active to add items';
  end if;

  return new;
end;
$$;

create trigger validate_inventory_reservation_item_trigger
  before insert or update of reservation_id, inventory_level_id, quantity
  on public.inventory_reservation_items
  for each row
  execute function public.validate_inventory_reservation_item();

-- 9. Authorization helper for inventory locations

create or replace function public.can_manage_inventory_location(
  p_location_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.inventory_locations location
    where location.id = p_location_id
      and (
        (
          location.owner_type = 'platform'
          and (select public.is_active_platform_admin())
        )
        or
        (
          location.owner_type = 'vendor'
          and (select public.is_vendor_owner(location.vendor_id))
          and exists (
            select 1
            from public.vendors vendor
            where vendor.id = location.vendor_id
              and vendor.status = 'active'
          )
        )
      )
  );
$$;

revoke all on function public.can_manage_inventory_location(uuid)
  from public, anon;

grant execute on function public.can_manage_inventory_location(uuid)
  to authenticated;

-- 10. Enable RLS

alter table public.inventory_locations enable row level security;
alter table public.inventory_levels enable row level security;
alter table public.inventory_adjustments enable row level security;
alter table public.inventory_reservations enable row level security;
alter table public.inventory_reservation_items enable row level security;

-- 11. Data API privileges

grant select on public.inventory_locations to authenticated;
grant select on public.inventory_levels to authenticated;
grant select on public.inventory_adjustments to authenticated;

-- Reservation access and all inventory writes will be
-- introduced through controlled workflows.

-- 12. Inventory location policies

create policy "Owners can view their inventory locations"
  on public.inventory_locations
  for select
  to authenticated
  using (
    (select public.can_manage_inventory_location(id))
  );

-- 13. Inventory level policies

create policy "Product owners can view their inventory levels"
  on public.inventory_levels
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.product_variants variant
      where variant.id = variant_id
        and (select public.can_manage_product(variant.product_id))
    )
  );

-- 14. Inventory adjustment policies
-- Adjustment history is read-only through the Data API.

create policy "Product owners can view inventory adjustment history"
  on public.inventory_adjustments
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.inventory_levels level
      join public.product_variants variant
        on variant.id = level.variant_id
      where level.id = inventory_level_id
        and (select public.can_manage_product(variant.product_id))
    )
  );

-- 15. Reservation tables intentionally have no Data API
-- grants or user-facing policies in this migration.
-- Checkout ownership and reservation operations will be
-- established alongside the checkout workflow.
