"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowUpRight, MenuIcon, SearchIcon, UserIcon, X } from "lucide-react";
import { Button } from "@splenddev/kreativ-ui/components";
import { useSearch } from "@/features/search/contexts/search-provider";
import { CartTrigger } from "@/features/cart/components/CartTrigger";

const navigation = [
  { label: "Discover", href: "/" },
  { label: "Categories", href: "/categories" },
  { label: "New arrivals", href: "/new-arrivals" },
  { label: "Vendors", href: "/vendors" },
];

export function StorefrontHeader() {
  const [menuOpen, setMenuOpen] = useState(false);
  const pathname = usePathname();
  const { openSearch, isOpen: searchOpen } = useSearch();

  const isActive = (href: string) =>
    href === "/"
      ? pathname === "/"
      : pathname === href || pathname.startsWith(`${href}/`);

  useEffect(() => {
    setMenuOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!menuOpen) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMenuOpen(false);
    };

    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [menuOpen]);

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/95 backdrop-blur-md">
      <div className="relative mx-auto max-w-360 px-5 sm:px-8 lg:px-12">
        <div className="flex h-19 items-center justify-between gap-6">
          <Link
            href="/"
            aria-label="Shopverse homepage"
            className="shrink-0 font-heading text-[1.8rem] font-semibold tracking-[-0.075em] text-foreground"
          >
            shopverse<span className="text-brand">.</span>
          </Link>

          <nav
            aria-label="Main navigation"
            className="hidden items-center gap-8 lg:flex"
          >
            {navigation.map((item) => {
              const active = isActive(item.href);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  aria-current={active ? "page" : undefined}
                  className={`relative py-2 text-[13px] font-medium tracking-wide transition-colors ${
                    active
                      ? "text-foreground"
                      : "text-text-muted hover:text-foreground"
                  }`}
                >
                  {item.label}
                  {active && (
                    <span className="absolute inset-x-0 -bottom-0.5 h-px bg-brand" />
                  )}
                </Link>
              );
            })}
          </nav>

          <div className="flex shrink-0 items-center gap-1 sm:gap-3">
            <Button
              type="button"
              aria-label="Search products"
              aria-haspopup="dialog"
              aria-expanded={searchOpen}
              onClick={() => {
                setMenuOpen(false);
                openSearch();
              }}
              variant="ghost"
              color="neutral"
              iconOnly
            >
              <SearchIcon aria-hidden="true" />
            </Button>

            <Link
              href="/account"
              aria-label="Your account"
              className="hidden size-10 items-center justify-center rounded-full text-foreground transition-colors hover:bg-surface-muted focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground sm:flex"
            >
              <UserIcon aria-hidden="true" />
            </Link>

            <CartTrigger />

            <Button
              type="button"
              aria-label={menuOpen ? "Close navigation" : "Open navigation"}
              aria-expanded={menuOpen}
              aria-controls="mobile-navigation"
              onClick={() => setMenuOpen((value) => !value)}
              variant="ghost"
              color="neutral"
              iconOnly
              className="lg:hidden"
            >
              {menuOpen ? (
                <X aria-hidden="true" />
              ) : (
                <MenuIcon aria-hidden="true" />
              )}
            </Button>
          </div>
        </div>

        {/* Absolute mobile dropdown */}
        {menuOpen && (
          <nav
            id="mobile-navigation"
            aria-label="Mobile navigation"
            className="absolute inset-x-0 top-full z-50 border-t border-border bg-background px-5 py-6 shadow-lg animate-in fade-in slide-in-from-top-2 duration-200 motion-reduce:animate-none sm:px-8 lg:hidden"
          >
            <p className="mb-3 font-mono text-[10px] uppercase tracking-[0.18em] text-text-muted">
              Explore Shopverse
            </p>

            <div className="flex flex-col">
              {navigation.map((item) => {
                const active = isActive(item.href);

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMenuOpen(false)}
                    aria-current={active ? "page" : undefined}
                    className={`flex items-center justify-between border-b border-border py-4 text-[15px] transition-colors ${
                      active
                        ? "font-semibold text-foreground"
                        : "font-medium text-text-muted hover:text-foreground"
                    }`}
                  >
                    {item.label}
                    <span className="text-text-muted" aria-hidden="true">
                      {active ? "—" : <ArrowUpRight className="size-4" />}
                    </span>
                  </Link>
                );
              })}
            </div>

            <Link
              href="/account"
              onClick={() => setMenuOpen(false)}
              className="mt-5 flex items-center gap-3 text-sm font-medium text-foreground"
            >
              <UserIcon className="size-5" aria-hidden="true" />
              My account
            </Link>
          </nav>
        )}
      </div>
    </header>
  );
}
