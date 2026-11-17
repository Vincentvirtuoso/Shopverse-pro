import type { Product, ProductVariant } from "@shopverse/types";

import { validateVariantSelections } from "./validate-variant-selections.js";
import { validateVariantPricing } from "./validate-variant-pricing.js";
import { validatePurchaseLimits } from "./validate-purchase-limits.js";
import { validateBackorder } from "./validate-backorder.js";
import { validatePreorder } from "./validate-preorder.js";
import { validateShippingOverrides } from "./validate-shipping-overrides.js";
import { validateBarcode } from "./validate-barcode.js";
import { validateSku } from "./validate-sku.js";
import { validateVariantStatus } from "./validate-variant-status.js";

export interface VariantValidation {
  valid: boolean;
  errors: string[];
}

export function validateProductVariant(
  variant: ProductVariant,
  product: Pick<Product, "options" | "baseCurrency">,
): VariantValidation {
  const results = [
    validateSku(variant.sku),
    validateVariantStatus(variant.status),
    validateVariantSelections(variant.selections, product.options),
    validateVariantPricing(
      variant.price,
      variant.compareAtPrice,
      product.baseCurrency,
    ),
    validatePurchaseLimits(variant.purchaseLimits),
    validateBackorder(variant.backorder),
    validatePreorder(variant.preorder),
    validateShippingOverrides(variant.shippingOverrides),
    validateBarcode(variant.barcode),
  ];

  const errors = results.flatMap((result) => result.errors);

  return {
    valid: errors.length === 0,
    errors,
  };
}
