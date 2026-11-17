import type { ProductCardData } from "@/components/storefront/merchandising/ProductCard";

export const mockProducts: ProductCardData[] = [
  {
    id: "product-1",
    name: "Everyday Leather Tote",
    slug: "everyday-leather-tote",
    imageUrl:
      "https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=800&q=85",
    vendorName: "Atelier Studio",
    price: 48000,
    originalPrice: 56000,
    badge: "Bestseller",
  },
  {
    id: "product-2",
    name: "Sculpted Ceramic Vase",
    slug: "sculpted-ceramic-vase",
    imageUrl:
      "https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=800&q=85",
    vendorName: "Form & Found",
    price: 26500,
    badge: "New arrival",
  },
  {
    id: "product-3",
    name: "Minimal Everyday Watch",
    slug: "minimal-everyday-watch",
    imageUrl:
      "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=85",
    vendorName: "Northline",
    price: 72500,
  },
  {
    id: "product-4",
    name: "Classic Leather Sneakers",
    slug: "classic-leather-sneakers",
    imageUrl:
      "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&q=85",
    vendorName: "Common Ground",
    price: 39500,
    badge: "Popular",
  },
];
