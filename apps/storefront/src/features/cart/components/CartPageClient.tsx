"use client";

import Link from "next/link";
import { useMemo } from "react";
import { MinusIcon, PlusIcon, Trash2Icon, ShoppingBagIcon } from "lucide-react";
import { Button, Heading } from "@splenddev/kreativ-ui/components";
import { useCart } from "../contexts/cart-context";

function formatMoney(amountMinor: number, currency: string) {
  const fractionDigits = new Intl.NumberFormat("en", {
    style: "currency",
    currency,
  }).resolvedOptions().maximumFractionDigits;

  return new Intl.NumberFormat("en-NG", {
    style: "currency",
    currency,
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(amountMinor / 10 ** fractionDigits!);
}

export function CartPageClient() {
  const { items, itemCount, removeItem, setQuantity } = useCart();

  const vendorGroups = useMemo(() => {
    const groups = new Map<
      string,
      { vendorName: string; items: typeof items }
    >();

    for (const item of items) {
      const group = groups.get(item.vendorId);

      if (group) {
        group.items.push(item);
      } else {
        groups.set(item.vendorId, {
          vendorName: item.vendorName,
          items: [item],
        });
      }
    }

    return Array.from(groups.entries()).map(([vendorId, group]) => ({
      vendorId,
      ...group,
    }));
  }, [items]);

  const currencyGroups = useMemo(() => {
    const totals = new Map<string, number>();

    for (const item of items) {
      totals.set(
        item.currency,
        (totals.get(item.currency) ?? 0) + item.unitAmountMinor * item.quantity,
      );
    }

    return Array.from(totals.entries());
  }, [items]);

  const hasSingleCurrency = currencyGroups.length <= 1;
  const subtotal = currencyGroups[0]?.[1] ?? 0;
  const currency = currencyGroups[0]?.[0] ?? "NGN";

  if (items.length === 0) {
    return (
      <main className="mx-auto flex min-h-[65vh] max-w-7xl flex-col items-center justify-center px-5 py-20 text-center">
        <div className="mb-6 flex size-20 items-center justify-center rounded-full bg-surface-muted text-text-muted">
          <ShoppingBagIcon size={30} strokeWidth={1.4} />
        </div>

        <Heading level={1} className="font-heading text-3xl text-foreground">
          Your bag is taking a break.
        </Heading>

        <p className="mt-3 max-w-sm text-sm leading-6 text-text-muted">
          You haven't added anything yet. Discover something worth bringing
          home.
        </p>

        <Link
          href="/"
          className="mt-8 inline-flex items-center justify-center rounded-md bg-brand px-6 py-3 text-sm font-semibold text-brand-fg transition-colors hover:bg-brand-hover"
        >
          Explore Shopverse
        </Link>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-7xl px-5 py-12 sm:px-8 lg:px-12 lg:py-16">
      <div className="mb-10 flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="mb-2 font-mono text-[10px] uppercase tracking-[0.18em] text-text-muted">
            Your selections
          </p>

          <Heading
            level={1}
            className="font-heading text-3xl text-foreground sm:text-4xl"
          >
            Your shopping bag
          </Heading>
        </div>

        <p className="text-sm text-text-muted">
          {itemCount} {itemCount === 1 ? "item" : "items"}
        </p>
      </div>

      <div className="grid gap-12 lg:grid-cols-[1fr_340px] lg:gap-16">
        <section aria-label="Cart items" className="space-y-10">
          {vendorGroups.map((group) => (
            <div key={group.vendorId}>
              <div className="mb-5 flex items-center justify-between border-b border-border pb-3">
                <h2 className="text-sm font-semibold text-foreground">
                  {group.vendorName}
                </h2>
                <span className="text-xs text-text-muted">
                  {group.items.length}{" "}
                  {group.items.length === 1 ? "product" : "products"}
                </span>
              </div>

              <div className="space-y-6">
                {group.items.map((item) => {
                  const lineTotal = item.unitAmountMinor * item.quantity;

                  return (
                    <article
                      key={`${item.productId}:${item.variantId ?? "default"}`}
                      className="flex gap-4 sm:gap-6"
                    >
                      <Link
                        href={`/products/${item.slug}`}
                        className="relative aspect-4/5 w-24 shrink-0 overflow-hidden rounded-md bg-surface-muted sm:w-32"
                      >
                        <img
                          src={item.imageUrl}
                          alt={item.name}
                          className="size-full object-cover"
                        />
                      </Link>

                      <div className="flex min-w-0 flex-1 flex-col justify-between gap-4 sm:flex-row sm:items-start">
                        <div className="min-w-0">
                          <Link
                            href={`/products/${item.slug}`}
                            className="font-medium text-foreground transition-colors hover:text-brand"
                          >
                            {item.name}
                          </Link>

                          <p className="mt-1 text-sm text-text-muted">
                            {formatMoney(item.unitAmountMinor, item.currency)}
                          </p>

                          <div className="mt-4 inline-flex items-center rounded-md border border-border">
                            <Button
                              type="button"
                              variant="ghost"
                              color="neutral"
                              size="sm"
                              aria-label={`Decrease quantity of ${item.name}`}
                              disabled={item.quantity <= 1}
                              onClick={() =>
                                setQuantity(
                                  item.productId,
                                  item.variantId,
                                  item.quantity - 1,
                                )
                              }
                              className="size-9 min-w-0 p-0"
                            >
                              <MinusIcon size={14} />
                            </Button>

                            <span
                              className="min-w-8 text-center text-sm tabular-nums"
                              aria-live="polite"
                            >
                              {item.quantity}
                            </span>

                            <Button
                              type="button"
                              variant="ghost"
                              color="neutral"
                              size="sm"
                              aria-label={`Increase quantity of ${item.name}`}
                              onClick={() =>
                                setQuantity(
                                  item.productId,
                                  item.variantId,
                                  item.quantity + 1,
                                )
                              }
                              className="size-9 min-w-0 p-0"
                            >
                              <PlusIcon size={14} />
                            </Button>
                          </div>
                        </div>

                        <div className="flex items-center justify-between gap-4 sm:flex-col sm:items-end">
                          <p className="text-sm font-semibold tabular-nums text-foreground">
                            {formatMoney(lineTotal, item.currency)}
                          </p>

                          <Button
                            type="button"
                            variant="ghost"
                            color="neutral"
                            size="sm"
                            onClick={() =>
                              removeItem(item.productId, item.variantId)
                            }
                            className="gap-2 text-text-muted hover:text-destructive"
                          >
                            <Trash2Icon size={14} />
                            Remove
                          </Button>
                        </div>
                      </div>
                    </article>
                  );
                })}
              </div>
            </div>
          ))}
        </section>

        <aside className="h-fit rounded-lg border border-border bg-surface p-6 lg:sticky lg:top-28">
          <h2 className="font-heading text-xl text-foreground">
            Order summary
          </h2>

          <div className="mt-6 space-y-4 border-b border-border pb-6">
            <div className="flex justify-between text-sm">
              <span className="text-text-muted">Items ({itemCount})</span>
              <span className="font-medium tabular-nums text-foreground">
                {hasSingleCurrency
                  ? formatMoney(subtotal, currency)
                  : "Multiple currencies"}
              </span>
            </div>

            <div className="flex justify-between text-sm">
              <span className="text-text-muted">Shipping</span>
              <span className="text-text-muted">Calculated at checkout</span>
            </div>
          </div>

          {hasSingleCurrency ? (
            <div className="flex justify-between py-5">
              <span className="font-semibold text-foreground">Subtotal</span>
              <span className="font-semibold tabular-nums text-foreground">
                {formatMoney(subtotal, currency)}
              </span>
            </div>
          ) : (
            <div className="space-y-3 py-5">
              <p className="text-xs leading-5 text-warning">
                Your cart contains items in different currencies. Checkout
                requires a single currency.
              </p>

              {currencyGroups.map(([code, amount]) => (
                <div key={code} className="flex justify-between text-sm">
                  <span className="text-text-muted">{code}</span>
                  <span className="font-medium text-foreground">
                    {formatMoney(amount, code)}
                  </span>
                </div>
              ))}
            </div>
          )}

          <Button
            type="button"
            color="brand"
            disabled={!hasSingleCurrency}
            onClick={() => {
              window.location.assign("/checkout");
            }}
            className="w-full"
          >
            Continue to checkout
          </Button>

          <p className="mt-4 text-center text-xs leading-5 text-text-muted">
            Shipping costs and final order totals are confirmed at checkout.
          </p>

          <Link
            href="/"
            className="mt-5 block text-center text-sm font-medium text-text-muted transition-colors hover:text-foreground"
          >
            Continue shopping
          </Link>
        </aside>
      </div>
    </main>
  );
}
