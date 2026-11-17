import type { VariantPurchaseLimits } from "@shopverse/types";

export interface PurchaseLimitsValidation {
  valid: boolean;
  errors: string[];
}

export function validatePurchaseLimits(
  limits: VariantPurchaseLimits,
): PurchaseLimitsValidation {
  const errors: string[] = [];

  if (!Number.isSafeInteger(limits.minPerOrder) || limits.minPerOrder < 1) {
    errors.push("Minimum quantity per order must be at least 1.");
  }

  if (limits.maxPerOrder !== null) {
    if (
      !Number.isSafeInteger(limits.maxPerOrder) ||
      limits.maxPerOrder < limits.minPerOrder
    ) {
      errors.push("Maximum quantity per order cannot be below the minimum.");
    }
  }

  if (
    limits.maxPerCustomer !== null &&
    (!Number.isSafeInteger(limits.maxPerCustomer) || limits.maxPerCustomer < 1)
  ) {
    errors.push("Maximum quantity per customer must be a positive integer.");
  }

  if (
    limits.maxTotalQuantity !== null &&
    (!Number.isSafeInteger(limits.maxTotalQuantity) ||
      limits.maxTotalQuantity < 1)
  ) {
    errors.push("Maximum total quantity must be a positive integer.");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
