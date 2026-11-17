import { CartPageClient } from "@/features/cart/components/CartPageClient";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Your Shopping Bag | Shopverse",
  description: "Review your Shopverse shopping bag.",
};

export default function CartPage() {
  return <CartPageClient />;
}
