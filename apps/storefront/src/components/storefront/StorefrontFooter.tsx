"uce client";

import { useState, useEffect } from "react";

const footerLinks = {
  Explore: [
    { label: "Shop all", href: "/products" },
    { label: "Categories", href: "/categories" },
    { label: "New arrivals", href: "/products?sort=newest" },
  ],
  Help: [
    { label: "Contact us", href: "/contact" },
    { label: "Shipping information", href: "/shipping" },
    { label: "Returns", href: "/returns" },
  ],
  Company: [
    { label: "About Shopverse", href: "/about" },
    { label: "Become a vendor", href: "/sell" },
  ],
};

export function StorefrontFooter() {
  const [year, setYear] = useState<number | null>(null);

  useEffect(() => {
    // Runs in the browser only — safe to read the clock here.
    setYear(new Date().getFullYear());
  }, []);
  return (
    <footer className="mt-auto border-t border-border bg-surface px-5 py-14 lg:px-8">
      <div className="mx-auto max-w-7xl">
        <div className="grid gap-12 sm:grid-cols-2 lg:grid-cols-[2fr_1fr_1fr_1fr]">
          <div>
            <a href="/" className="font-heading text-3xl text-foreground">
              shopverse<span className="text-brand">.</span>
            </a>
            <p className="mt-4 max-w-xs text-sm leading-6 text-text-muted">
              Good finds, great vendors, and a better way to discover products.
            </p>
          </div>

          {Object.entries(footerLinks).map(([heading, links]) => (
            <div key={heading}>
              <h3 className="mb-5 text-sm font-semibold text-foreground">
                {heading}
              </h3>
              <ul className="space-y-3">
                {links.map((link) => (
                  <li key={link.href}>
                    <a
                      href={link.href}
                      className="text-sm text-text-muted hover:text-foreground"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-14 border-t border-border pt-6 text-xs text-text-muted">
          © {year} Shopverse. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
