import type { Metadata } from "next";
import Link from "next/link";
import {
  BookmarkCheckIcon,
  PackageCheckIcon,
  ShieldCheckIcon,
  StoreIcon,
  TagIcon,
} from "lucide-react";
import { AuthForm } from "@/features/auth/components/AuthForm";

export const metadata: Metadata = {
  title: "Create account | Shopverse",
  description:
    "Create your free Shopverse account to shop from verified vendors worldwide.",
};

const benefits = [
  {
    icon: TagIcon,
    title: "Millions of finds, one place",
    text: "Fashion, home, beauty and more from independent vendors.",
  },
  {
    icon: ShieldCheckIcon,
    title: "Buyer protection",
    text: "Get help if your order isn't as described.",
  },
  {
    icon: PackageCheckIcon,
    title: "Track every order",
    text: "Follow each delivery from vendor to doorstep.",
  },
  {
    icon: BookmarkCheckIcon,
    title: "Save and check out faster",
    text: "Keep a wishlist and reuse your details.",
  },
];

export default function SignUpPage() {
  return (
    <main className="min-h-[75vh] bg-surface-muted px-4 py-10 sm:py-16">
      <div className="mx-auto grid w-full max-w-5xl overflow-hidden rounded-2xl border border-border bg-surface shadow-sm lg:grid-cols-[1fr_1.1fr]">
        {/* Benefits panel (desktop) */}
        <aside className="hidden flex-col justify-between bg-foreground p-10 text-white lg:flex">
          <Link
            href="/"
            className="font-heading text-2xl font-semibold tracking-tight"
          >
            shopverse<span className="text-brand">.</span>
          </Link>

          <div className="my-12">
            <h1 className="font-heading text-3xl leading-tight">
              Join free and start shopping from vendors worth knowing.
            </h1>

            <ul className="mt-8 space-y-5">
              {benefits.map(({ icon: Icon, title, text }) => (
                <li key={title} className="flex gap-3">
                  <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-white/10">
                    <Icon className="size-4.5" aria-hidden="true" />
                  </span>
                  <div>
                    <p className="text-sm font-semibold">{title}</p>
                    <p className="text-sm text-white/65">{text}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>

          <Link
            href="/vendors"
            className="flex items-center gap-3 rounded-xl border border-white/15 p-4 transition hover:border-white/40 hover:bg-white/5"
          >
            <StoreIcon className="size-5 shrink-0" aria-hidden="true" />
            <span className="text-sm">
              <span className="block font-semibold">Want to sell instead?</span>
              <span className="text-white/65">
                Open your storefront and reach buyers worldwide.
              </span>
            </span>
          </Link>
        </aside>

        {/* Form panel */}
        <section className="p-6 sm:p-10 lg:p-12">
          <Link
            href="/"
            className="mb-8 block text-center font-heading text-2xl font-semibold tracking-tight lg:hidden"
          >
            shopverse<span className="text-brand">.</span>
          </Link>

          <div className="mx-auto w-full max-w-sm">
            <h2 className="font-heading text-2xl text-foreground sm:text-3xl">
              Create your account
            </h2>
            <p className="mt-1.5 mb-6 text-sm text-text-muted">
              It's free and takes less than a minute.
            </p>

            <AuthForm mode="signup" />
          </div>
        </section>
      </div>
    </main>
  );
}
