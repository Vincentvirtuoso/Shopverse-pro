
-- =========================================================
-- 009: Categories and product discounts
-- Shopverse
-- =========================================================

-- 1. Enums

create type public.category_status as enum (
  'active',
  'inactive'
);

create type public.product_discount_type as enum (
  'percentage',
  'fixed_amount'
);

create type public.product_discount_status as enum (
  'draft',
  'scheduled',
  'active',
  'expired',
  'disabled'
);

-- 2. Categories
-- Categories are owned and managed by the Shopverse platform.

create table public.categories (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text not null unique,

  description text,
  image_url text,

  parent_category_id uuid
    references public.categories(id) on delete restrict,

  status public.category_status not null default 'active',

  position integer not null default 0
    check (position >= 0),

  seo_title text,
  seo_description text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint category_name_not_empty
    check (nullif(pg_catalog.btrim(name), '') is not null),

  constraint category_slug_format
    check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

  constraint category_not_own_parent
    check (parent_category_id is null or parent_category_id <> id)
);

create index categories_parent_idx
  on public.categories(parent_category_id);

create index categories_status_position_idx
  on public.categories(status, position);

create trigger set_categories_updated_at
  before update on public.categories
  for each row
  execute function public.set_updated_at();

-- Prevent circular category hierarchies.

create or replace function public.prevent_category_hierarchy_cycle()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  creates_cycle boolean;
begin
  if new.parent_category_id is null then
    return new;
  end if;

  with recursive ancestors(id, parent_category_id, visited) as (
    select
      category.id,
      category.parent_category_id,
      array[category.id]
    from public.categories category
    where category.id = new.parent_category_id

    union all

    select
      parent.id,
      parent.parent_category_id,
      ancestors.visited || parent.id
    from public.categories parent
    join ancestors
      on parent.id = ancestors.parent_category_id
    where not parent.id = any(ancestors.visited)
  )
  select exists (
    select 1
    from ancestors
    where id = new.id
  )
  into creates_cycle;

  if creates_cycle then
    raise exception 'Category hierarchy cannot contain a cycle';
  end if;

  return new;
end;
$$;

create trigger prevent_category_hierarchy_cycle_trigger
  before insert or update of parent_category_id
  on public.categories
  for each row
  execute function public.prevent_category_hierarchy_cycle();

-- 3. Product-category relationships

create table public.product_categories (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  category_id uuid not null
    references public.categories(id) on delete restrict,

  created_at timestamptz not null default now(),

  constraint product_category_unique
    unique (product_id, category_id)
);

create index product_categories_product_idx
  on public.product_categories(product_id);

create index product_categories_category_idx
  on public.product_categories(category_id);

-- 4. Product discount value and scheduling

create table public.product_discounts (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  variant_id uuid,

  discount_type public.product_discount_type not null,

  -- Percentage discounts use discount_percentage.
  -- Fixed discounts use discount_amount and discount_currency.

  discount_percentage numeric(7, 4),
  discount_amount bigint,
  discount_currency varchar(3),

  status public.product_discount_status
    not null default 'draft',

  starts_at timestamptz,
  ends_at timestamptz,

  created_by uuid not null
    references public.users(id) on delete restrict,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_discount_variant_product_fk
    foreign key (variant_id, product_id)
    references public.product_variants(id, product_id)
    on delete restrict,

  constraint product_discount_value_check
    check (
        (
        discount_type = 'percentage'
        and discount_percentage is not null
        and discount_percentage > 0
        and discount_percentage <= 100
        and discount_amount is null
        and discount_currency is null
        )
        or
        (
        discount_type = 'fixed_amount'
        and discount_percentage is null
        and discount_amount is not null
        and discount_amount > 0
        and discount_currency is not null
        and discount_currency ~ '^[A-Z]{3}$'
        )
    ),

  constraint product_discount_schedule_check
    check (
      starts_at is null
      or ends_at is null
      or ends_at > starts_at
    )
);

create index product_discounts_product_idx
  on public.product_discounts(product_id);

create index product_discounts_variant_idx
  on public.product_discounts(variant_id)
  where variant_id is not null;

create index product_discounts_status_schedule_idx
  on public.product_discounts(status, starts_at, ends_at);

create index product_discounts_creator_idx
  on public.product_discounts(created_by);

create trigger set_product_discounts_updated_at
  before update on public.product_discounts
  for each row
  execute function public.set_updated_at();

-- Fixed discounts must use the product's base currency.

create or replace function public.validate_product_discount_currency()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  product_currency varchar(3);
begin
  if new.discount_type <> 'fixed_amount' then
    return new;
  end if;

  select product.base_currency
  into product_currency
  from public.products product
  where product.id = new.product_id;

  if not found then
    raise exception 'Discount product does not exist';
  end if;

  if new.discount_currency <> product_currency then
    raise exception
      'Fixed discount currency must match the product base currency';
  end if;

  return new;
end;
$$;

create trigger validate_product_discount_currency_trigger
  before insert or update of
    product_id,
    discount_type,
    discount_amount,
    discount_currency
  on public.product_discounts
  for each row
  execute function public.validate_product_discount_currency();

-- 5. Product management authorization helper
-- Platform admins can manage platform products.
-- Active vendor owners can manage their own vendor products.

create or replace function public.can_manage_product(
  p_product_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.products product
    where product.id = p_product_id
      and (
        (
          product.owner_type = 'platform'
          and (select public.is_active_platform_admin())
        )
        or
        (
          product.owner_type = 'vendor'
          and exists (
            select 1
            from public.vendor_memberships membership
            join public.vendors vendor
              on vendor.id = membership.vendor_id
            join public.users app_user
              on app_user.id = membership.user_id
            where membership.vendor_id = product.vendor_id
              and membership.user_id = (select auth.uid())
              and membership.role = 'owner'
              and vendor.status = 'active'
              and app_user.status = 'active'
          )
        )
      )
  );
$$;

revoke all on function public.can_manage_product(uuid)
  from public, anon;

grant execute on function public.can_manage_product(uuid)
  to authenticated;

-- 6. Enable RLS

alter table public.categories enable row level security;
alter table public.product_categories enable row level security;
alter table public.product_discounts enable row level security;

-- 7. Data API privileges

grant select on public.categories to anon, authenticated;
grant insert, update, delete on public.categories to authenticated;

grant select, insert, delete
  on public.product_categories to authenticated;

grant select on public.product_discounts
  to anon, authenticated;

-- Discount writes will be exposed through controlled workflows.

-- 8. Category policies

create policy "Anyone can view active categories"
  on public.categories
  for select
  to anon
  using (status = 'active');

create policy "Authenticated users can view active categories"
  on public.categories
  for select
  to authenticated
  using (
    status = 'active'
    or (select public.is_active_platform_admin())
  );

create policy "Platform admins manage categories"
  on public.categories
  for all
  to authenticated
  using (
    (select public.is_active_platform_admin())
  )
  with check (
    (select public.is_active_platform_admin())
  );

-- 9. Product-category policies

create policy "Users can view categories assigned to accessible products"
  on public.product_categories
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Product owners can assign active categories"
  on public.product_categories
  for insert
  to authenticated
  with check (
    (select public.can_manage_product(product_id))
    and exists (
      select 1
      from public.categories category
      where category.id = category_id
        and category.status = 'active'
    )
  );

create policy "Product owners can remove category assignments"
  on public.product_categories
  for delete
  to authenticated
  using (
    (select public.can_manage_product(product_id))
  );

-- 10. Product discount policies

create policy "Anyone can view currently active discounts"
  on public.product_discounts
  for select
  to anon
  using (
    status = 'active'
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
    and exists (
      select 1
      from public.products product
      where product.id = product_id
        and product.status = 'active'
    )
  );

create policy "Authenticated users can view accessible discounts"
  on public.product_discounts
  for select
  to authenticated
  using (
    (
      status = 'active'
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now())
      and exists (
        select 1
        from public.products product
        where product.id = product_id
          and product.status = 'active'
      )
    )
    or (select public.can_manage_product(product_id))
    or (select public.is_active_platform_admin())
  );
