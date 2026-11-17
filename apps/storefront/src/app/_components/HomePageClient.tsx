"use client";

import { AnnouncementBar } from "@/components/storefront/AnnouncementBar";
import { StorefrontHeader } from "@/components/storefront/StorefrontHeader";
import { StorefrontFooter } from "@/components/storefront/StorefrontFooter";
import { Button, Heading } from "@splenddev/kreativ-ui/components";
import { SectionHeading } from "@/components/storefront/shared/SectionHeading";
import { ProductGrid } from "@/components/storefront/merchandising/ProductGrid";
import { ProductCarousel } from "@/components/storefront/merchandising/ProductCarousel";
import { ProductEditorial } from "@/components/storefront/merchandising/ProductEditorial";
import { CategoryShowcase } from "@/components/storefront/merchandising/CategoryShowcase";
import { CampaignBanner } from "@/components/storefront/merchandising/CampaignBanner";
import { VendorSpotlight } from "@/components/storefront/merchandising/VendorSpotlight";
import { mockProducts } from "@/features/products/mock-products";

const mockCategories = [
  {
    id: "living",
    name: "Living",
    slug: "living",
    imageUrl: "/images/categories/living.webp",
    imageAlt: "Contemporary living space",
  },
  {
    id: "fashion",
    name: "Fashion",
    slug: "fashion",
    imageUrl: "/images/categories/fashion.webp",
    imageAlt: "Fashion collection",
  },
  {
    id: "accessories",
    name: "Accessories",
    slug: "accessories",
    imageUrl: "/images/categories/accessories.webp",
    imageAlt: "Curated accessories",
  },
  {
    id: "beauty",
    name: "Beauty",
    slug: "beauty",
    imageUrl: "/images/categories/beauty.webp",
    imageAlt: "Beauty collection",
  },
];

export function HomePageClient() {
  return (
    <>
      {/* Hero */}
      <section className="mx-auto grid max-w-7xl gap-10 px-5 py-16 lg:grid-cols-2 lg:items-center lg:px-8 lg:py-24">
        <div className="max-w-xl">
          <p className="mb-6 text-xs font-semibold uppercase tracking-[0.2em] text-brand">
            Welcome to Shopverse
          </p>

          <Heading
            className="font-heading text-6xl leading-[0.95] tracking-tight text-foreground sm:text-7xl lg:text-8xl"
            level={1}
          >
            Good things.
            <br />
            Great finds.
            <br />
            <span className="text-brand">All in one place.</span>
          </Heading>

          <p className="mt-7 max-w-md text-base leading-7 text-text-muted">
            Discover thoughtfully selected products from vendors worth knowing.
            Find your next favourite thing.
          </p>

          <div className="mt-9 flex flex-wrap gap-4">
            <Button
              size="xl"
              color="brand"
              onClick={() => {
                window.location.href = "/products";
              }}
            >
              Explore products
            </Button>

            <Button
              size="xl"
              color="neutral"
              variant="outline"
              onClick={() => {
                window.location.href = "/categories";
              }}
            >
              Browse categories
            </Button>
          </div>
        </div>

        <div
          className="min-h-90 bg-cover bg-center sm:min-h-120 lg:min-h-140"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&q=90')",
          }}
          role="img"
          aria-label="Curated retail store interior"
        />
      </section>

      {/* Trending */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <SectionHeading
          eyebrow="Worth a closer look"
          title="Trending discoveries."
          description="Interesting finds getting attention right now."
          href="/products"
          linkLabel="View all products"
        />

        <ProductCarousel products={mockProducts} />
      </section>

      {/* Categories */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <CategoryShowcase categories={mockCategories} />
      </section>

      {/* Editorial */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <ProductEditorial
          eyebrow="The Shopverse edit"
          title="Make room for things that feel like you."
          description="From thoughtful everyday essentials to distinctive statement pieces, discover products worth bringing into your world."
          imageUrl="/images/editorial/editorial-living.webp"
          imageAlt="Thoughtfully styled contemporary interior"
          href="/collections/featured"
          linkLabel="Explore the collection"
        />
      </section>

      {/* Bestsellers */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <SectionHeading
          eyebrow="Customer favourites"
          title="The ones people love."
          description="Popular picks from across the Shopverse marketplace."
          href="/products?sort=bestselling"
          linkLabel="Explore bestsellers"
        />

        <ProductGrid products={mockProducts} columns={4} />
      </section>

      {/* Vendor spotlight */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <VendorSpotlight
          vendor={{
            id: "vendor-001",
            name: "The Form House",
            slug: "the-form-house",
            description:
              "A design-led studio bringing together functional objects and thoughtful details for everyday spaces.",
            location: "Lagos, Nigeria",
            productCount: 28,
            coverImageUrl: "/images/vendors/vendor-form-house.webp",
            coverImageAlt: "The Form House studio collection",
          }}
        />
      </section>

      {/* Campaign */}
      <section className="mx-auto max-w-7xl px-5 py-14 lg:px-8 lg:py-20">
        <CampaignBanner
          eyebrow="A little inspiration"
          title="Discover something unexpected."
          description="Explore distinctive finds from vendors worth knowing."
          imageUrl="/images/campaigns/seasonal-edit.webp"
          imageAlt="Seasonal product collection"
          href="/collections/featured"
          linkLabel="Explore the edit"
          theme="dark"
        />
      </section>
    </>
  );
}
