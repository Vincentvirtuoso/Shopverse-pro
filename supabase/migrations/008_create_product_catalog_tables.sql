
-- =========================================================
-- 008: Product catalog tables
-- Shopverse
-- =========================================================

-- 1. Enums

create type public.product_ownership_type as enum (
  'platform',
  'vendor'
);

create type public.product_type as enum (
  'physical',
  'digital'
);

create type public.product_status as enum (
  'draft',
  'pending_review',
  'active',
  'rejected',
  'archived'
);

create type public.product_variant_status as enum (
  'active',
  'inactive',
  'discontinued',
  'archived'
);

create type public.product_sku_source as enum (
  'generated',
  'manual'
);

create type public.catalog_attribute_data_type as enum (
  'text',
  'number',
  'boolean'
);

create type public.catalog_attribute_usage as enum (
  'variant_option',
  'descriptive',
  'both'
);

create type public.product_attribute_scope as enum (
  'product',
  'variant'
);

create type public.product_barcode_type as enum (
  'upc',
  'ean',
  'gtin'
);

create type public.product_weight_unit as enum (
  'g',
  'kg',
  'oz',
  'lb'
);

create type public.product_dimension_unit as enum (
  'mm',
  'cm',
  'in'
);

-- 2. Catalog attribute definitions

create table public.catalog_attributes (
  id uuid primary key default gen_random_uuid(),

  name text not null,
  slug text not null unique,

  data_type public.catalog_attribute_data_type not null,
  usage public.catalog_attribute_usage not null,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger set_catalog_attributes_updated_at
  before update on public.catalog_attributes
  for each row
  execute function public.set_updated_at();

-- 3. Products

create table public.products (
  id uuid primary key default gen_random_uuid(),

  owner_type public.product_ownership_type not null,
  vendor_id uuid
    references public.vendors(id) on delete restrict,

  name text not null,
  slug text not null unique,
  description text not null default '',

  type public.product_type not null,
  status public.product_status not null default 'draft',

  base_currency varchar(3) not null
    check (base_currency ~ '^[A-Z]{3}$'),

  -- Physical product shipping details.
  -- Digital products must have all shipping fields null.

  weight_value numeric(12, 4),
  weight_unit public.product_weight_unit,

  dimension_length numeric(12, 4),
  dimension_width numeric(12, 4),
  dimension_height numeric(12, 4),
  dimension_unit public.product_dimension_unit,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_ownership_check
    check (
      (owner_type = 'platform' and vendor_id is null)
      or
      (owner_type = 'vendor' and vendor_id is not null)
    ),

  constraint product_weight_check
    check (
      (weight_value is null and weight_unit is null)
      or
      (weight_value > 0 and weight_unit is not null)
    ),

  constraint product_dimensions_check
    check (
      (
        dimension_length is null
        and dimension_width is null
        and dimension_height is null
        and dimension_unit is null
      )
      or
      (
        dimension_length > 0
        and dimension_width > 0
        and dimension_height > 0
        and dimension_unit is not null
      )
    ),

  constraint digital_product_shipping_check
    check (
      type <> 'digital'
      or (
        weight_value is null
        and weight_unit is null
        and dimension_length is null
        and dimension_width is null
        and dimension_height is null
        and dimension_unit is null
      )
    )
);

create index products_vendor_idx
  on public.products(vendor_id)
  where vendor_id is not null;

create index products_status_idx
  on public.products(status);

create index products_owner_status_idx
  on public.products(owner_type, status);

create trigger set_products_updated_at
  before update on public.products
  for each row
  execute function public.set_updated_at();

-- 4. Product options

create table public.product_options (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  attribute_id uuid
    references public.catalog_attributes(id) on delete restrict,

  name text not null,
  position integer not null default 0
    check (position >= 0),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_option_position_unique
    unique (product_id, position),

  constraint product_option_product_id_unique
    unique (id, product_id)
);

create index product_options_product_idx
  on public.product_options(product_id);

create trigger set_product_options_updated_at
  before update on public.product_options
  for each row
  execute function public.set_updated_at();

-- 5. Product option values

create table public.product_option_values (
  id uuid primary key default gen_random_uuid(),

  option_id uuid not null
    references public.product_options(id) on delete restrict,

  value text not null,

  position integer not null default 0
    check (position >= 0),

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_option_value_unique
    unique (option_id, value),

  constraint product_option_value_position_unique
    unique (option_id, position),

  constraint product_option_value_id_option_unique
    unique (id, option_id)
);

create index product_option_values_option_idx
  on public.product_option_values(option_id);

create trigger set_product_option_values_updated_at
  before update on public.product_option_values
  for each row
  execute function public.set_updated_at();

-- 6. Product variants

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  sku text not null unique,
  sku_source public.product_sku_source not null default 'generated',

  title text not null,

  price_amount bigint not null
    check (price_amount >= 0),

  compare_at_price_amount bigint
    check (
      compare_at_price_amount is null
      or compare_at_price_amount >= price_amount
    ),

  barcode_type public.product_barcode_type,
  barcode_value text,

  status public.product_variant_status
    not null default 'active',

  -- Null means inherit product shipping details.
  -- Object can override weight and/or dimensions.

  shipping_overrides jsonb,

  -- Purchase limits

  min_per_order integer not null default 1
    check (min_per_order > 0),

  max_per_order integer,
  max_per_customer integer,
  max_total_quantity integer,

  -- Backorder settings

  backorder_enabled boolean not null default false,
  backorder_max_quantity integer,

  -- Preorder settings

  preorder_enabled boolean not null default false,
  preorder_expected_available_at timestamptz,
  preorder_quantity_limit integer,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_variant_product_id_unique
    unique (id, product_id),

  constraint product_variant_barcode_check
    check (
      (barcode_type is null and barcode_value is null)
      or
      (
        barcode_type is not null
        and nullif(pg_catalog.btrim(barcode_value), '') is not null
      )
    ),

  constraint product_variant_shipping_override_check
    check (
      shipping_overrides is null
      or jsonb_typeof(shipping_overrides) = 'object'
    ),

  constraint product_variant_purchase_limits_check
    check (
      (max_per_order is null or max_per_order >= min_per_order)
      and (max_per_customer is null or max_per_customer > 0)
      and (max_total_quantity is null or max_total_quantity > 0)
    ),

  constraint product_variant_backorder_check
    check (
      backorder_max_quantity is null
      or backorder_max_quantity > 0
    ),

  constraint product_variant_preorder_check
    check (
      preorder_quantity_limit is null
      or preorder_quantity_limit > 0
    )
);

create index product_variants_product_idx
  on public.product_variants(product_id);

create index product_variants_status_idx
  on public.product_variants(product_id, status);

create unique index product_variant_barcode_unique
  on public.product_variants(barcode_type, barcode_value)
  where barcode_type is not null;

create trigger set_product_variants_updated_at
  before update on public.product_variants
  for each row
  execute function public.set_updated_at();

-- 7. Variant option selections
-- Each variant can select only one value per option.
-- Composite foreign keys ensure options and values
-- belong to the same product.

create table public.product_variant_option_selections (
  variant_id uuid not null,
  product_id uuid not null,
  option_id uuid not null,
  option_value_id uuid not null,

  created_at timestamptz not null default now(),

  primary key (variant_id, option_id),

  constraint selection_variant_product_fk
    foreign key (variant_id, product_id)
    references public.product_variants(id, product_id)
    on delete restrict,

  constraint selection_option_product_fk
    foreign key (option_id, product_id)
    references public.product_options(id, product_id)
    on delete restrict,

  constraint selection_value_option_fk
    foreign key (option_value_id, option_id)
    references public.product_option_values(id, option_id)
    on delete restrict
);

create index variant_selections_product_idx
  on public.product_variant_option_selections(product_id);

-- 8. Excluded variant combinations
-- UUID arrays preserve the TypeScript model.
-- Values are canonicalized and validated before insertion.

create table public.excluded_variant_combinations (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  option_value_ids uuid[] not null,

  created_at timestamptz not null default now(),

  constraint excluded_combination_not_empty
    check (cardinality(option_value_ids) > 0),

  constraint excluded_combination_unique
    unique (product_id, option_value_ids)
);

create index excluded_variant_combinations_product_idx
  on public.excluded_variant_combinations(product_id);

create or replace function public.validate_excluded_variant_combination()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  canonical_values uuid[];
  valid_count integer;
begin
  if exists (
    select 1
    from unnest(new.option_value_ids) as item(value)
    where item.value is null
  ) then
    raise exception 'Excluded combination contains a null option value';
  end if;

  select pg_catalog.array_agg(item.value order by item.value)
  into canonical_values
  from (
    select distinct value
    from unnest(new.option_value_ids) as values_list(value)
  ) item;

  if cardinality(canonical_values) <> cardinality(new.option_value_ids) then
    raise exception 'Excluded combination contains duplicate option values';
  end if;

  select count(*)::integer
  into valid_count
  from public.product_option_values option_value
  join public.product_options option_record
    on option_record.id = option_value.option_id
  where option_value.id = any(new.option_value_ids)
    and option_record.product_id = new.product_id;

  if valid_count <> cardinality(new.option_value_ids) then
    raise exception 'Excluded combination contains values from another product';
  end if;

  new.option_value_ids := canonical_values;

  return new;
end;
$$;

create trigger validate_excluded_variant_combination_trigger
  before insert or update on public.excluded_variant_combinations
  for each row
  execute function public.validate_excluded_variant_combination();

-- 9. Product and variant descriptive attributes

create table public.product_attribute_values (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  variant_id uuid,

  scope public.product_attribute_scope not null,

  attribute_id uuid
    references public.catalog_attributes(id) on delete restrict,

  name text not null,

  value_type public.catalog_attribute_data_type not null,

  value_text text,
  value_number numeric,
  value_boolean boolean,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_attribute_scope_check
    check (
      (scope = 'product' and variant_id is null)
      or
      (scope = 'variant' and variant_id is not null)
    ),

  constraint product_attribute_value_type_check
    check (
      (
        value_type = 'text'
        and value_text is not null
        and value_number is null
        and value_boolean is null
      )
      or
      (
        value_type = 'number'
        and value_text is null
        and value_number is not null
        and value_boolean is null
      )
      or
      (
        value_type = 'boolean'
        and value_text is null
        and value_number is null
        and value_boolean is not null
      )
    ),

  constraint product_attribute_variant_product_fk
    foreign key (variant_id, product_id)
    references public.product_variants(id, product_id)
    on delete restrict
);

create index product_attribute_values_product_idx
  on public.product_attribute_values(product_id);

create index product_attribute_values_variant_idx
  on public.product_attribute_values(variant_id)
  where variant_id is not null;

create trigger set_product_attribute_values_updated_at
  before update on public.product_attribute_values
  for each row
  execute function public.set_updated_at();

-- 10. Attribute relationship validation
-- Options may only reference attributes used for variant options.
-- Descriptive values may only reference descriptive attributes.

create or replace function public.validate_product_attribute_usage()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  attribute_record public.catalog_attributes%rowtype;
begin
  if new.attribute_id is null then
    return new;
  end if;

  select *
  into attribute_record
  from public.catalog_attributes
  where id = new.attribute_id;

  if not found then
    raise exception 'Catalog attribute not found';
  end if;

  if tg_table_name = 'product_options' then
    if attribute_record.usage not in ('variant_option', 'both') then
      raise exception 'Attribute cannot be used as a variant option';
    end if;
  else
    if attribute_record.usage not in ('descriptive', 'both') then
      raise exception 'Attribute cannot be used as a descriptive value';
    end if;

    if attribute_record.data_type <> new.value_type then
      raise exception 'Attribute value type does not match its definition';
    end if;
  end if;

  return new;
end;
$$;

create trigger validate_product_option_attribute_trigger
  before insert or update of attribute_id
  on public.product_options
  for each row
  execute function public.validate_product_attribute_usage();

create trigger validate_product_attribute_definition_trigger
  before insert or update of attribute_id, value_type
  on public.product_attribute_values
  for each row
  execute function public.validate_product_attribute_usage();

-- 11. Enforce at least one variant per product.
-- Deferred checks allow a product and its variants to be
-- created in the same database transaction.

create or replace function public.ensure_product_has_variant()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  target_product_id uuid;
begin
  if tg_table_name = 'products' then
    target_product_id := new.id;
  elsif tg_op = 'DELETE' then
    target_product_id := old.product_id;
  else
    target_product_id := new.product_id;
  end if;

  if exists (
    select 1
    from public.products
    where id = target_product_id
  )
  and not exists (
    select 1
    from public.product_variants
    where product_id = target_product_id
  ) then
    raise exception 'Every product must have at least one variant';
  end if;

  if tg_table_name = 'product_variants'
    and tg_op = 'UPDATE'
    and old.product_id is distinct from new.product_id
  then
    if exists (
      select 1
      from public.products
      where id = old.product_id
    )
    and not exists (
      select 1
      from public.product_variants
      where product_id = old.product_id
    ) then
      raise exception 'Every product must have at least one variant';
    end if;
  end if;

  return null;
end;
$$;

create constraint trigger products_require_variant_trigger
  after insert on public.products
  deferrable initially deferred
  for each row
  execute function public.ensure_product_has_variant();

create constraint trigger product_variants_require_product_variant_trigger
  after insert or update or delete on public.product_variants
  deferrable initially deferred
  for each row
  execute function public.ensure_product_has_variant();

-- 12. Vendor ownership helper

create or replace function public.is_vendor_owner(
  p_vendor_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.vendor_memberships membership
    join public.users app_user
      on app_user.id = membership.user_id
    where membership.vendor_id = p_vendor_id
      and membership.user_id = (select auth.uid())
      and app_user.status = 'active'
  );
$$;

revoke all on function public.is_vendor_owner(uuid)
  from public, anon;

grant execute on function public.is_vendor_owner(uuid)
  to authenticated;

-- 13. Enable RLS

alter table public.catalog_attributes enable row level security;
alter table public.products enable row level security;
alter table public.product_options enable row level security;
alter table public.product_option_values enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_variant_option_selections enable row level security;
alter table public.excluded_variant_combinations enable row level security;
alter table public.product_attribute_values enable row level security;

-- 14. Data API privileges
-- Writes will be introduced through controlled catalog workflows.

grant select on public.catalog_attributes to anon, authenticated;
grant select on public.products to anon, authenticated;
grant select on public.product_options to anon, authenticated;
grant select on public.product_option_values to anon, authenticated;
grant select on public.product_variants to anon, authenticated;
grant select on public.product_variant_option_selections to anon, authenticated;
grant select on public.excluded_variant_combinations to authenticated;
grant select on public.product_attribute_values to anon, authenticated;

-- 15. Catalog attribute policies

create policy "Anyone can view active catalog attributes"
  on public.catalog_attributes
  for select
  to anon, authenticated
  using (
    is_active
    or (select public.is_active_platform_admin())
  );

-- 16. Product policies

create policy "Users can view published products and authorized products"
  on public.products
  for select
  to anon, authenticated
  using (
    status = 'active'
    or (
      auth.uid() is not null
      and (
        (
          owner_type = 'vendor'
          and (select public.is_vendor_owner(vendor_id))
        )
        or (select public.is_active_platform_admin())
      )
    )
  );

-- 17. Product child-table policies

create policy "Users can view options for accessible products"
  on public.product_options
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Users can view option values for accessible products"
  on public.product_option_values
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.product_options option_record
      join public.products product
        on product.id = option_record.product_id
      where option_record.id = option_id
    )
  );

create policy "Users can view variants for accessible products"
  on public.product_variants
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Users can view selections for accessible products"
  on public.product_variant_option_selections
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Authorized users can view excluded combinations"
  on public.excluded_variant_combinations
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Users can view attributes for accessible products"
  on public.product_attribute_values
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );
