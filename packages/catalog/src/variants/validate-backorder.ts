import type { VariantBackorderSettings } from "@shopverse/types";

export interface BackorderValidation {
  valid: boolean;
  errors: string[];
}

export function validateBackorder(
  settings: VariantBackorderSettings,
): BackorderValidation {
  const errors: string[] = [];

  if (!settings.enabled && settings.maxQuantity !== null) {
    errors.push("Disabled backorders cannot have a quantity limit.");
  }

  if (
    settings.maxQuantity !== null &&
    (!Number.isSafeInteger(settings.maxQuantity) || settings.maxQuantity < 1)
  ) {
    errors.push("Backorder quantity must be a positive safe integer.");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
