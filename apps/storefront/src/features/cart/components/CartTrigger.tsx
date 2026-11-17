"use client";

import { useRouter } from "next/navigation";
import { ShoppingBagIcon } from "lucide-react";
import { Button } from "@splenddev/kreativ-ui/components";
import { useCart } from "@/features/cart/contexts/cart-context";

export function CartTrigger() {
  const router = useRouter();
  const { itemCount } = useCart();

  return (
    <Button
      type="button"
      variant="ghost"
      color="neutral"
      onClick={() => router.push("/cart")}
      aria-label={`Shopping cart, ${itemCount} items`}
      className="relative flex size-10 items-center justify-center rounded-full p-0 text-foreground hover:bg-surface-muted"
    >
      <ShoppingBagIcon size={20} aria-hidden="true" />

      {itemCount > 0 && (
        <span
          aria-hidden="true"
          className="absolute -right-0.5 -top-0.5 flex min-w-4.25 h-4.25 items-center justify-center rounded-full bg-brand px-1 text-[10px] font-semibold text-brand-fg"
        >
          {itemCount > 99 ? "99+" : itemCount}
        </span>
      )}

      <span className="sr-only" aria-live="polite">
        {itemCount} items in cart
      </span>
    </Button>
  );
}
