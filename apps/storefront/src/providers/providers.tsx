import type { ReactNode } from "react";
import { UIProvider } from "./ui-provider";
import { StorefrontChromeProvider } from "@/components/storefront/StorefrontChromeContext";
import { CartProvider } from "@/features/cart/contexts/cart-context";
import { SearchProvider } from "@/features/search/contexts/search-provider";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <UIProvider>
      <StorefrontChromeProvider>
        <CartProvider>
          <SearchProvider>{children}</SearchProvider>
        </CartProvider>
      </StorefrontChromeProvider>
    </UIProvider>
  );
}
