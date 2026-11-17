
-- =========================================================
-- 010: Product images and storage
-- Shopverse
-- =========================================================

-- 1. Public product image storage bucket

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'product-images',
  'product-images',
  true,
  10485760,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/avif'
  ]
);

-- 2. Product image metadata

create table public.product_images (
  id uuid primary key default gen_random_uuid(),

  product_id uuid not null
    references public.products(id) on delete restrict,

  variant_id uuid,

  url text not null,
  alt text,

  position integer not null default 0
    check (position >= 0),

  is_primary boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint product_image_variant_product_fk
    foreign key (variant_id, product_id)
    references public.product_variants(id, product_id)
    on delete restrict,

  constraint product_image_url_not_empty
    check (nullif(pg_catalog.btrim(url), '') is not null),

  constraint variant_images_cannot_be_primary
    check (variant_id is null or is_primary = false)
);

-- General gallery positions must be unique per product.

create unique index product_images_general_position_unique
  on public.product_images(product_id, position)
  where variant_id is null;

-- Variant image positions must be unique per variant.

create unique index product_images_variant_position_unique
  on public.product_images(product_id, variant_id, position)
  where variant_id is not null;

-- Only one general gallery image can be primary per product.

create unique index product_images_one_primary_per_product
  on public.product_images(product_id)
  where variant_id is null and is_primary = true;

create index product_images_product_idx
  on public.product_images(product_id);

create index product_images_variant_idx
  on public.product_images(variant_id)
  where variant_id is not null;

create trigger set_product_images_updated_at
  before update on public.product_images
  for each row
  execute function public.set_updated_at();

-- 3. Validate product image storage URLs.
-- URLs must point to the Shopverse product-images bucket
-- and use the product's UUID as the first storage folder.

create or replace function public.validate_product_image_url()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  expected_path_prefix text;
begin
  expected_path_prefix :=
    '/storage/v1/object/public/product-images/'
    || new.product_id::text
    || '/';

    if pg_catalog.strpos(new.url, expected_path_prefix) = 0 then
    raise exception
      'Product image URL must reference its product image storage folder';
  end if;

  return new;
end;
$$;

create trigger validate_product_image_url_trigger
  before insert or update of url, product_id
  on public.product_images
  for each row
  execute function public.validate_product_image_url();

-- 4. Enable RLS

alter table public.product_images enable row level security;

-- 5. Product image metadata privileges

grant select on public.product_images to anon, authenticated;
grant insert, update, delete on public.product_images to authenticated;

-- 6. Product image metadata policies

create policy "Anyone can view images for accessible products"
  on public.product_images
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.products product
      where product.id = product_id
    )
  );

create policy "Product owners can add product images"
  on public.product_images
  for insert
  to authenticated
  with check (
    (select public.can_manage_product(product_id))
  );

create policy "Product owners can update product images"
  on public.product_images
  for update
  to authenticated
  using (
    (select public.can_manage_product(product_id))
  )
  with check (
    (select public.can_manage_product(product_id))
  );

create policy "Product owners can delete product images"
  on public.product_images
  for delete
  to authenticated
  using (
    (select public.can_manage_product(product_id))
  );

-- 7. Storage object policies

-- Public bucket: images can be retrieved without authentication.
-- Authenticated product owners can list their own product images.

create policy "Product owners can view their stored images"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'product-images'
    and (select public.can_manage_product(
      (storage.foldername(name))[1]::uuid
    ))
  );

create policy "Product owners can upload product images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and (select public.can_manage_product(
      (storage.foldername(name))[1]::uuid
    ))
  );

create policy "Product owners can update stored images"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and (select public.can_manage_product(
      (storage.foldername(name))[1]::uuid
    ))
  )
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and (select public.can_manage_product(
      (storage.foldername(name))[1]::uuid
    ))
  );

create policy "Product owners can delete stored images"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'product-images'
    and (select public.can_manage_product(
      (storage.foldername(name))[1]::uuid
    ))
  );
