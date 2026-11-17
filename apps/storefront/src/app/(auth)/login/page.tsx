import type { Metadata } from "next";
import Link from "next/link";
import {
  BadgeCheckIcon,
  LockKeyholeIcon,
  PackageCheckIcon,
  ShieldCheckIcon,
  StoreIcon,
} from "lucide-react";
import { AuthForm } from "@/features/auth/components/AuthForm";

export const metadata: Metadata = {
  title: "Sign in | Shopverse",
  description: "Sign in to your Shopverse account.",
};

const benefits = [
  {
    icon: BadgeCheckIcon,
    title: "Verified vendors",
    text: "Shop from independent sellers we've vetted.",
  },
  {
    icon: ShieldCheckIcon,
    title: "Buyer protection",
    text: "Get help if your order isn't as described.",
  },
  {
    icon: LockKeyholeIcon,
    title: "Secure payments",
    text: "Your payment details stay encrypted.",
  },
  {
    icon: PackageCheckIcon,
    title: "Tracked delivery",
    text: "Follow every order from vendor to doorstep.",
  },
];

export default function LoginPage() {
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
              One account. Products from vendors around the world.
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
            className="group flex items-center gap-3 rounded-xl border border-white/15 p-4 transition hover:border-white/40 hover:bg-white/5"
          >
            <StoreIcon className="size-5 shrink-0" aria-hidden="true" />
            <span className="text-sm">
              <span className="block font-semibold">Sell on Shopverse</span>
              <span className="text-white/65">
                Reach buyers worldwide with your own storefront.
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
              Sign in
            </h2>
            <p className="mt-1.5 mb-6 text-sm text-text-muted">
              Welcome back. Track orders, save items and check out faster.
            </p>

            <AuthForm mode="login" />
          </div>
        </section>
      </div>
    </main>
  );
}
