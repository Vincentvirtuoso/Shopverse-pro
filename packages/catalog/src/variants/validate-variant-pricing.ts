import type { CurrencyCode, Money } from "@shopverse/types";

export interface VariantPricingValidation {
  valid: boolean;
  errors: string[];
}

export function validateVariantPricing(
  price: Money,
  compareAtPrice: Money | null,
  baseCurrency: CurrencyCode,
): VariantPricingValidation {
  const errors: string[] = [];

  if (!Number.isSafeInteger(price.amount) || price.amount < 0) {
    errors.push("Price must be a non-negative safe integer.");
  }

  if (price.currency !== baseCurrency) {
    errors.push("Price currency must match the product base currency.");
  }

  if (compareAtPrice !== null) {
    if (
      !Number.isSafeInteger(compareAtPrice.amount) ||
      compareAtPrice.amount < 0
    ) {
      errors.push("Compare-at price must be a non-negative safe integer.");
    }

    if (compareAtPrice.currency !== baseCurrency) {
      errors.push(
        "Compare-at price currency must match the product base currency.",
      );
    }

    if (compareAtPrice.amount <= price.amount) {
      errors.push("Compare-at price must be greater than the selling price.");
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
