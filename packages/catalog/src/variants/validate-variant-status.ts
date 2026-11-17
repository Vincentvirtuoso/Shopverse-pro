import type { ProductVariantStatus } from "@shopverse/types";

const VALID_STATUSES: ProductVariantStatus[] = [
  "active",
  "inactive",
  "discontinued",
  "archived",
];

export interface VariantStatusValidation {
  valid: boolean;
  errors: string[];
}

export function validateVariantStatus(
  status: unknown,
): VariantStatusValidation {
  const valid = VALID_STATUSES.includes(status as ProductVariantStatus);

  return {
    valid,
    errors: valid ? [] : ["Invalid product variant status."],
  };
}
