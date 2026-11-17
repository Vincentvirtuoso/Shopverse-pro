import { ProductCard, type ProductCardData } from "./ProductCard";

type ProductGridProps = {
  products: ProductCardData[];
  columns?: 2 | 3 | 4;
  onQuickAdd?: (product: ProductCardData) => void;
  onToggleWishlist?: (product: ProductCardData) => void;
  wishlistedIds?: string[];
  emptyMessage?: string;
};

const columnClasses = {
  2: "grid-cols-2",
  3: "grid-cols-2 sm:grid-cols-3",
  4: "grid-cols-2 sm:grid-cols-3 lg:grid-cols-4",
};

export function ProductGrid({
  products,
  columns = 4,
  onQuickAdd,
  onToggleWishlist,
  wishlistedIds = [],
  emptyMessage = "No products to display yet.",
}: ProductGridProps) {
  if (products.length === 0) {
    return (
      <div className="py-16 text-center text-sm text-text-muted">
        {emptyMessage}
      </div>
    );
  }

  return (
    <div
      className={`grid ${columnClasses[columns]} gap-x-4 gap-y-10 sm:gap-x-6 lg:gap-y-12`}
    >
      {products.map((product) => (
        <ProductCard
          key={product.id}
          product={product}
          onQuickAdd={onQuickAdd}
          onToggleWishlist={onToggleWishlist}
          isWishlisted={wishlistedIds.includes(product.id)}
        />
      ))}
    </div>
  );
}
