export interface SkuValidation {
  valid: boolean;
  normalizedSku: string;
  errors: string[];
}

export function normalizeSku(sku: string): string {
  return sku.trim().toUpperCase();
}

export function validateSku(sku: string): SkuValidation {
  const normalizedSku = normalizeSku(sku);
  const errors: string[] = [];

  if (!normalizedSku) {
    errors.push("SKU cannot be empty.");
  }

  return {
    valid: errors.length === 0,
    normalizedSku,
    errors,
  };
}
