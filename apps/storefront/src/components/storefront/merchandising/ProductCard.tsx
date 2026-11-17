"use client";

import Link from "next/link";
import { PriceDisplay } from "../shared/PriceDisplay";
import { Card } from "@splenddev/kreativ-ui/components";

export type ProductCardData = {
  id: string;
  name: string;
  slug: string;
  imageUrl: string;
  hoverImageUrl?: string;
  vendorName: string;
  price: number;
  originalPrice?: number;
  currency?: string;
  badge?: string;
  isAvailable?: boolean;
};

type ProductCardProps = {
  product: ProductCardData;
  onQuickAdd?: (product: ProductCardData) => void;
  onToggleWishlist?: (product: ProductCardData) => void;
  isWishlisted?: boolean;
};

export function ProductCard({
  product,
  onQuickAdd,
  onToggleWishlist,
  isWishlisted = false,
}: ProductCardProps) {
  const available = product.isAvailable !== false;

  return (
    <Card className="group min-w-0" variant="ghost">
      <div className="relative overflow-hidden rounded-md bg-surface-muted">
        <Link
          href={`/products/${product.slug}`}
          aria-label={`View ${product.name}`}
          className="relative block aspect-4/5 overflow-hidden"
        >
          <img
            src={product.imageUrl}
            alt={product.name}
            loading="lazy"
            className="absolute inset-0 h-full w-full object-cover transition-transform duration-700 ease-out group-hover:scale-[1.04]"
          />

          {product.hoverImageUrl && (
            <img
              src={product.hoverImageUrl}
              alt=""
              loading="lazy"
              aria-hidden="true"
              className="absolute inset-0 h-full w-full object-cover opacity-0 transition-opacity duration-500 group-hover:opacity-100"
            />
          )}
        </Link>

        {product.badge && (
          <span className="absolute left-3 top-3 bg-background px-2.5 py-1 text-[10px] font-medium uppercase tracking-wider text-foreground">
            {product.badge}
          </span>
        )}

        {onToggleWishlist && (
          <button
            type="button"
            aria-label={
              isWishlisted
                ? `Remove ${product.name} from wishlist`
                : `Add ${product.name} to wishlist`
            }
            aria-pressed={isWishlisted}
            onClick={() => onToggleWishlist(product)}
            className="absolute right-3 top-3 flex size-9 items-center justify-center rounded-full bg-background/90 text-lg text-foreground backdrop-blur transition-colors hover:bg-white"
          >
            {isWishlisted ? "♥" : "♡"}
          </button>
        )}

        {onQuickAdd && available && (
          <div className="absolute inset-x-3 bottom-3 translate-y-3 opacity-0 transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100 focus-within:translate-y-0 focus-within:opacity-100">
            <button
              type="button"
              onClick={() => onQuickAdd(product)}
              className="w-full bg-background px-4 py-3 text-xs font-semibold text-foreground shadow-sm transition-colors hover:bg-brand hover:text-brand-fg"
            >
              Quick add
            </button>
          </div>
        )}

        {!available && (
          <div className="absolute inset-x-0 bottom-0 bg-neutral-950/75 px-3 py-3 text-center text-xs font-medium text-white">
            Currently unavailable
          </div>
        )}
      </div>

      <div className="space-y-1.5 pt-3">
        <p className="truncate text-[11px] uppercase tracking-wider text-text-muted">
          {product.vendorName}
        </p>

        <Link
          href={`/products/${product.slug}`}
          className="line-clamp-2 text-sm font-medium text-foreground transition-colors hover:text-brand"
        >
          {product.name}
        </Link>

        <PriceDisplay
          amount={product.price}
          originalAmount={product.originalPrice}
          currency={product.currency}
        />
      </div>
    </Card>
  );
}
