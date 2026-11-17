import type { ProductDimensions, ProductWeight } from "@shopverse/types";

export interface ShippingOverrides {
  weight?: ProductWeight | null;
  dimensions?: ProductDimensions | null;
}

export interface ShippingValidation {
  valid: boolean;
  errors: string[];
}

function isValidWeight(weight: ProductWeight): boolean {
  return Number.isFinite(weight.value) && weight.value > 0;
}

function isValidDimensions(dimensions: ProductDimensions): boolean {
  return (
    Number.isFinite(dimensions.length) &&
    dimensions.length > 0 &&
    Number.isFinite(dimensions.width) &&
    dimensions.width > 0 &&
    Number.isFinite(dimensions.height) &&
    dimensions.height > 0
  );
}

export function validateShippingOverrides(
  overrides: ShippingOverrides | null,
): ShippingValidation {
  const errors: string[] = [];

  if (overrides?.weight && !isValidWeight(overrides.weight)) {
    errors.push("Variant weight must be a positive finite number.");
  }

  if (overrides?.dimensions && !isValidDimensions(overrides.dimensions)) {
    errors.push("Variant dimensions must all be positive finite numbers.");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
