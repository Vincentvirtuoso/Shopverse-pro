"use client";

import { useEffect, useRef } from "react";
import Link from "next/link";
import { SearchIcon, XIcon } from "lucide-react";
import { Button, Input } from "@splenddev/kreativ-ui/components";
import { useSearch } from "@/features/search/contexts/search-provider";

const suggestions = [
  { label: "Home & Living", href: "/categories/home-living" },
  { label: "Fashion", href: "/categories/fashion" },
  { label: "Accessories", href: "/categories/accessories" },
  { label: "Beauty", href: "/categories/beauty" },
];

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])';

export function SearchDialog() {
  const {
    isOpen: open,
    closeSearch: onClose,
    query,
    setQuery,
    submitSearch,
    recentSearches,
    clearRecentSearches,
  } = useSearch();
  const inputRef = useRef<HTMLInputElement>(null);
  const dialogRef = useRef<HTMLElement>(null);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!open) return;

    const previouslyFocused = document.activeElement as HTMLElement | null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    inputRef.current?.focus();

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onCloseRef.current();
        return;
      }

      if (event.key !== "Tab" || !dialogRef.current) return;

      const items = dialogRef.current.querySelectorAll<HTMLElement>(FOCUSABLE);
      if (!items.length) return;

      const first = items[0];
      const last = items[items.length - 1];

      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last?.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first?.focus();
      }
    };

    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = previousOverflow;
      previouslyFocused?.focus();
    };
  }, [open]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-100 bg-neutral-950/40 backdrop-blur-[3px] animate-in fade-in duration-200 motion-reduce:animate-none"
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <section
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby="search-dialog-title"
        className="max-h-[90dvh] overflow-y-auto bg-surface px-5 pb-10 pt-6 shadow-xl animate-in slide-in-from-top-2 duration-200 motion-reduce:animate-none sm:px-10"
      >
        <div className="mx-auto max-w-4xl">
          <div className="mb-8 flex items-center justify-between">
            <h2
              id="search-dialog-title"
              className="font-mono text-[10px] font-normal uppercase tracking-[0.2em] text-text-muted"
            >
              Find something good
            </h2>

            <button
              type="button"
              onClick={onClose}
              aria-label="Close search"
              className="flex size-10 items-center justify-center rounded-full text-text-muted transition-colors hover:bg-neutral-200/70 hover:text-foreground focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground"
            >
              <XIcon size={20} aria-hidden="true" />
            </button>
          </div>

          <form
            role="search"
            onSubmit={(event) => {
              event.preventDefault();
              submitSearch();
            }}
          >
            <div className="flex items-center gap-3 border-b border-neutral-300 pb-4 transition-colors focus-within:border-foreground sm:gap-4">
              <SearchIcon
                size={18}
                aria-hidden="true"
                className="shrink-0 text-text-muted"
              />

              <Input
                ref={inputRef}
                type="search"
                name="q"
                variant="ghost"
                embedded
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                aria-label="Search products"
                autoComplete="off"
                enterKeyHint="search"
                placeholder="What are you looking for?"
              />

              <Button
                type="submit"
                variant="ghost"
                color="neutral"
                className="shrink-0 text-xs font-semibold uppercase tracking-wider hover:bg-transparent hover:text-[#b85d37] focus-visible:text-[#b85d37]"
              >
                Search
              </Button>
            </div>
          </form>

          {recentSearches.length > 0 && (
            <div className="mt-8">
              <div className="mb-4 flex items-center justify-between">
                <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-text-muted">
                  Recent searches
                </p>
                <button
                  type="button"
                  onClick={clearRecentSearches}
                  className="text-xs text-text-muted underline-offset-4 transition-colors hover:text-foreground hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground"
                >
                  Clear
                </button>
              </div>

              <ul className="flex flex-wrap gap-2">
                {recentSearches.map((term) => (
                  <li key={term}>
                    <Link
                      href={`/search?q=${encodeURIComponent(term)}`}
                      onClick={onClose}
                      className="block rounded-full bg-neutral-200/60 px-4 py-2 text-sm text-neutral-700 transition-colors hover:bg-neutral-950 hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground"
                    >
                      {term}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          )}

          <div className="mt-8">
            <p className="mb-4 font-mono text-[10px] uppercase tracking-[0.16em] text-text-muted">
              Explore categories
            </p>

            <ul className="flex flex-wrap gap-2">
              {suggestions.map((item) => (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    onClick={onClose}
                    className="block rounded-full border border-neutral-300 px-4 py-2 text-sm text-neutral-700 transition-colors hover:border-neutral-950 hover:bg-neutral-950 hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-foreground"
                  >
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>
    </div>
  );
}
