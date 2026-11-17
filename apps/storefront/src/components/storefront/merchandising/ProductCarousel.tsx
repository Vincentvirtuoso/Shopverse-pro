"use client";

import { useRef } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { ProductCard, type ProductCardData } from "./ProductCard";

type ProductCarouselProps = {
  products: ProductCardData[];
  onQuickAdd?: (product: ProductCardData) => void;
  onToggleWishlist?: (product: ProductCardData) => void;
  wishlistedIds?: string[];
  emptyMessage?: string;
};

export function ProductCarousel({
  products,
  onQuickAdd,
  onToggleWishlist,
  wishlistedIds = [],
  emptyMessage = "New discoveries are coming soon.",
}: ProductCarouselProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  const scroll = (direction: "left" | "right") => {
    const container = scrollRef.current;

    if (!container) return;

    container.scrollBy({
      left:
        direction === "right"
          ? container.clientWidth * 0.8
          : -container.clientWidth * 0.8,
      behavior: "smooth",
    });
  };

  if (!products.length) {
    return (
      <p className="py-12 text-center text-sm text-text-muted">
        {emptyMessage}
      </p>
    );
  }

  return (
    <section className="w-full">
      <div className="mb-5 flex items-center justify-end gap-2">
        <button
          type="button"
          onClick={() => scroll("left")}
          aria-label="Scroll products left"
          className="flex size-10 items-center justify-center rounded-full border border-border transition-colors hover:bg-surface"
        >
          <ChevronLeft className="size-4" />
        </button>

        <button
          type="button"
          onClick={() => scroll("right")}
          aria-label="Scroll products right"
          className="flex size-10 items-center justify-center rounded-full border border-border transition-colors hover:bg-surface"
        >
          <ChevronRight className="size-4" />
        </button>
      </div>

      <div
        ref={scrollRef}
        className="flex snap-x snap-mandatory gap-4 overflow-x-auto scroll-smooth pb-4 scrollbar-none [&::-webkit-scrollbar]:hidden sm:gap-5"
      >
        {products.map((product) => (
          <div
            key={product.id}
            className="w-[72%] shrink-0 snap-start sm:w-[42%] lg:w-[calc(25%-15px)]"
          >
            <ProductCard
              product={product}
              onQuickAdd={onQuickAdd}
              onToggleWishlist={onToggleWishlist}
              isWishlisted={wishlistedIds.includes(product.id)}
            />
          </div>
        ))}
      </div>
    </section>
  );
}
