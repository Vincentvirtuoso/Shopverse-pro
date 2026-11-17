import type { VariantPreorderSettings } from "@shopverse/types";

export interface PreorderValidation {
  valid: boolean;
  errors: string[];
}

export function validatePreorder(
  settings: VariantPreorderSettings,
): PreorderValidation {
  const errors: string[] = [];

  if (!settings.enabled) {
    if (settings.expectedAvailableAt !== null) {
      errors.push(
        "Disabled preorders cannot have an expected availability date.",
      );
    }

    if (settings.quantityLimit !== null) {
      errors.push("Disabled preorders cannot have a quantity limit.");
    }
  } else {
    if (!settings.expectedAvailableAt) {
      errors.push("Enabled preorders require an expected availability date.");
    } else if (Number.isNaN(Date.parse(settings.expectedAvailableAt))) {
      errors.push("Expected availability date must be valid.");
    }
  }

  if (
    settings.quantityLimit !== null &&
    (!Number.isSafeInteger(settings.quantityLimit) ||
      settings.quantityLimit < 1)
  ) {
    errors.push("Preorder quantity limit must be a positive safe integer.");
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
