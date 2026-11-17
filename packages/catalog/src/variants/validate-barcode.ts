import type { ProductVariantBarcode } from "@shopverse/types";

export interface BarcodeValidation {
  valid: boolean;
  errors: string[];
}

function hasValidCheckDigit(value: string): boolean {
  const digits = value.split("").map(Number);
  const checkDigit = digits[digits.length - 1];

  let sum = 0;

  for (
    let index = digits.length - 2, position = 0;
    index >= 0;
    index--, position++
  ) {
    const digit = digits[index];

    if (digit === undefined) return false;

    sum += digit * (position % 2 === 0 ? 3 : 1);
  }

  return checkDigit === (10 - (sum % 10)) % 10;
}

export function validateBarcode(
  barcode: ProductVariantBarcode | null,
): BarcodeValidation {
  if (barcode === null) {
    return { valid: true, errors: [] };
  }

  const errors: string[] = [];
  const { type, value } = barcode;

  const expectedLength =
    type === "upc" ? [12] : type === "ean" ? [13] : [8, 12, 13, 14];

  if (!/^\d+$/.test(value) || !expectedLength.includes(value.length)) {
    errors.push("Barcode has an invalid format or length.");
  } else if (!hasValidCheckDigit(value)) {
    errors.push("Barcode has an invalid check digit.");
  }

  return { valid: errors.length === 0, errors };
}
