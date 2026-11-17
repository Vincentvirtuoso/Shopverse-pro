"use client";

import { useActionState, useState } from "react";
import { Button, Checkbox } from "@splenddev/kreativ-ui/components";
import {
  completeOnboardingAction,
  skipOnboardingAction,
} from "../onboarding-actions";

type Category = {
  id: string;
  name: string;
  slug: string;
};

type OnboardingFormProps = {
  displayName: string;
  categories: Category[];
};

const initialState = null;

const inputClassName =
  "w-full rounded-md border border-border bg-surface px-3 py-3 text-sm text-foreground outline-none transition placeholder:text-text-muted focus:border-brand";

const labelClassName = "mb-2 block text-sm font-medium text-foreground";

export function OnboardingForm({
  displayName,
  categories,
}: OnboardingFormProps) {
  const [state, formAction, isPending] = useActionState(
    completeOnboardingAction,
    initialState,
  );

  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);

  function toggleCategory(categoryId: string, checked: boolean) {
    setSelectedCategories((current) =>
      checked
        ? [...current, categoryId]
        : current.filter((id) => id !== categoryId),
    );
  }

  return (
    <main className="min-h-screen bg-background px-5 py-12 sm:px-8">
      <div className="mx-auto max-w-3xl">
        <div className="mb-10">
          <p className="mb-3 font-mono text-xs uppercase tracking-[0.2em] text-brand">
            SHOPVERSE / YOUR ACCOUNT
          </p>

          <h1 className="font-heading text-4xl tracking-tight text-foreground sm:text-5xl">
            Make yourself at home
            {displayName ? `, ${displayName.split(" ")[0]}` : ""}.
          </h1>

          <p className="mt-4 max-w-xl text-sm leading-6 text-text-muted">
            A few details can make shopping easier. Everything here is optional,
            and you can update your information anytime.
          </p>
        </div>

        <form action={formAction} className="space-y-10">
          <section className="space-y-5">
            <div>
              <p className="font-mono text-xs text-text-muted">01 / PROFILE</p>
              <h2 className="mt-2 font-heading text-2xl text-foreground">
                A little about you
              </h2>
              <p className="mt-1 text-sm text-text-muted">
                Help us personalize your shopping experience.
              </p>
            </div>

            <div className="grid gap-5 sm:grid-cols-2">
              <div>
                <label className={labelClassName} htmlFor="phone">
                  Phone number
                </label>
                <input
                  id="phone"
                  name="phone"
                  type="tel"
                  placeholder="+234 800 000 0000"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="preferredCurrency">
                  Preferred currency
                </label>
                <select
                  id="preferredCurrency"
                  name="preferredCurrency"
                  defaultValue="NGN"
                  className={inputClassName}
                >
                  <option value="NGN">NGN — Nigerian Naira</option>
                  <option value="USD">USD — US Dollar</option>
                  <option value="GBP">GBP — British Pound</option>
                  <option value="EUR">EUR — Euro</option>
                </select>
              </div>
            </div>
          </section>

          <div className="border-t border-border" />

          <section className="space-y-5">
            <div>
              <p className="font-mono text-xs text-text-muted">02 / DELIVERY</p>
              <h2 className="mt-2 font-heading text-2xl text-foreground">
                Where should we deliver?
              </h2>
              <p className="mt-1 text-sm text-text-muted">
                Add an address for faster checkout. You can skip this for now.
              </p>
            </div>

            <div className="grid gap-5 sm:grid-cols-2">
              <div>
                <label className={labelClassName} htmlFor="firstName">
                  First name
                </label>
                <input
                  id="firstName"
                  name="firstName"
                  autoComplete="given-name"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="lastName">
                  Last name
                </label>
                <input
                  id="lastName"
                  name="lastName"
                  autoComplete="family-name"
                  className={inputClassName}
                />
              </div>

              <div className="sm:col-span-2">
                <label className={labelClassName} htmlFor="addressLine1">
                  Street address
                </label>
                <input
                  id="addressLine1"
                  name="addressLine1"
                  autoComplete="address-line1"
                  placeholder="House number and street"
                  className={inputClassName}
                />
              </div>

              <div className="sm:col-span-2">
                <label className={labelClassName} htmlFor="addressLine2">
                  Apartment, suite, etc. (optional)
                </label>
                <input
                  id="addressLine2"
                  name="addressLine2"
                  autoComplete="address-line2"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="city">
                  City
                </label>
                <input
                  id="city"
                  name="city"
                  autoComplete="address-level2"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="state">
                  State
                </label>
                <input
                  id="state"
                  name="state"
                  autoComplete="address-level1"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="postalCode">
                  Postal code
                </label>
                <input
                  id="postalCode"
                  name="postalCode"
                  autoComplete="postal-code"
                  className={inputClassName}
                />
              </div>

              <div>
                <label className={labelClassName} htmlFor="countryCode">
                  Country
                </label>
                <select
                  id="countryCode"
                  name="countryCode"
                  defaultValue="NG"
                  className={inputClassName}
                >
                  <option value="NG">Nigeria</option>
                  <option value="GH">Ghana</option>
                  <option value="KE">Kenya</option>
                  <option value="ZA">South Africa</option>
                  <option value="GB">United Kingdom</option>
                  <option value="US">United States</option>
                  <option value="CA">Canada</option>
                </select>
              </div>
            </div>
          </section>

          <div className="border-t border-border" />

          <section className="space-y-5">
            <div>
              <p className="font-mono text-xs text-text-muted">
                03 / INTERESTS
              </p>
              <h2 className="mt-2 font-heading text-2xl text-foreground">
                What do you love shopping for?
              </h2>
              <p className="mt-1 text-sm text-text-muted">
                Choose a few categories to help us discover what matters to you.
              </p>
            </div>

            {categories.length > 0 ? (
              <div className="grid gap-3 sm:grid-cols-2">
                {categories.map((category) => (
                  <div
                    key={category.id}
                    className="rounded-md border border-border p-4"
                  >
                    <Checkbox
                      checked={selectedCategories.includes(category.id)}
                      onCheckedChange={(checked) =>
                        toggleCategory(category.id, checked === true)
                      }
                      label={category.name}
                    />
                    <input
                      type="hidden"
                      name="categoryIds"
                      value={category.id}
                      disabled={!selectedCategories.includes(category.id)}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-text-muted">
                You can explore all our categories after onboarding.
              </p>
            )}
          </section>

          {state?.status === "error" && (
            <p role="alert" className="text-sm text-red-600">
              {state.message}
            </p>
          )}

          <div className="flex flex-col-reverse gap-3 border-t border-border pt-6 sm:flex-row sm:items-center sm:justify-between">
            <Button
              type="button"
              variant="link"
              color="brand"
              disabled={isPending}
              onClick={() => {
                void skipOnboardingAction();
              }}
            >
              Skip for now
            </Button>

            <Button type="submit" isLoading={isPending}>
              Complete setup
            </Button>
          </div>
        </form>

        <p className="mt-8 text-center text-xs text-text-muted">
          Your details are kept private and can be changed in your account
          settings.
        </p>
      </div>
    </main>
  );
}
