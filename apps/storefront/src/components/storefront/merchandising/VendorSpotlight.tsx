import Image from "next/image";
import Link from "next/link";

export type VendorSpotlightData = {
  id: string;
  name: string;
  slug: string;
  description: string;
  logoUrl?: string;
  coverImageUrl: string;
  coverImageAlt: string;
  location?: string;
  productCount?: number;
};

type VendorSpotlightProps = {
  vendor: VendorSpotlightData;
  eyebrow?: string;
};

export function VendorSpotlight({
  vendor,
  eyebrow = "Meet the maker",
}: VendorSpotlightProps) {
  return (
    <section className="grid overflow-hidden border border-border bg-surface md:grid-cols-[1.15fr_0.85fr]">
      <div className="relative min-h-75 md:min-h-110">
        <Image
          src={vendor.coverImageUrl}
          alt={vendor.coverImageAlt}
          fill
          sizes="(max-width: 768px) 100vw, 60vw"
          className="object-cover"
        />
      </div>

      <div className="flex flex-col justify-center px-7 py-10 sm:px-12 lg:px-16">
        <p className="mb-6 font-mono text-[10px] uppercase tracking-[0.2em] text-text-muted">
          {eyebrow}
        </p>

        {vendor.logoUrl && (
          <div className="relative mb-6 size-14 overflow-hidden rounded-full bg-background">
            <Image
              src={vendor.logoUrl}
              alt={`${vendor.name} logo`}
              fill
              sizes="56px"
              className="object-cover"
            />
          </div>
        )}

        <h2 className="font-heading text-4xl leading-tight tracking-tight text-foreground sm:text-5xl">
          {vendor.name}
        </h2>

        {vendor.location && (
          <p className="mt-3 text-xs uppercase tracking-wider text-text-muted">
            {vendor.location}
          </p>
        )}

        <p className="mt-6 max-w-md text-sm leading-7 text-text-muted">
          {vendor.description}
        </p>

        {vendor.productCount !== undefined && (
          <p className="mt-5 text-xs text-text-muted">
            {vendor.productCount} products available
          </p>
        )}

        <Link
          href={`/vendors/${vendor.slug}`}
          className="mt-8 inline-flex w-fit items-center gap-3 border-b border-foreground pb-2 text-sm font-medium text-foreground transition-opacity hover:opacity-60"
        >
          Explore storefront
          <span aria-hidden="true">↗</span>
        </Link>
      </div>
    </section>
  );
}
